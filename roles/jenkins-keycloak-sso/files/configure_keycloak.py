#!/usr/bin/env python3
"""
Configure Keycloak for Jenkins SSO Integration
This script handles realm creation, client configuration, and user setup
"""

import requests
import json
import sys
import argparse
import time
from urllib.parse import urljoin

class KeycloakConfigError(Exception):
    pass

class KeycloakConfig:
    def __init__(self, keycloak_url, admin_user, admin_password, timeout=30, retries=3):
        self.keycloak_url = keycloak_url.rstrip('/')
        self.admin_user = admin_user
        self.admin_password = admin_password
        self.timeout = timeout
        self.retries = retries
        self.token = None
        self.session = requests.Session()
        self.session.timeout = timeout

    def _retry_request(self, method, url, **kwargs):
        """Retry HTTP requests with exponential backoff"""
        for attempt in range(self.retries):
            try:
                response = method(url, **kwargs)
                return response
            except requests.exceptions.RequestException as e:
                if attempt == self.retries - 1:
                    raise KeycloakConfigError(f"Request failed after {self.retries} attempts: {e}")
                time.sleep(2 ** attempt)

    def get_admin_token(self):
        """Get admin access token"""
        token_url = f"{self.keycloak_url}/realms/master/protocol/openid-connect/token"
        data = {
            'client_id': 'admin-cli',
            'username': self.admin_user,
            'password': self.admin_password,
            'grant_type': 'password'
        }

        response = self._retry_request(self.session.post, token_url, data=data)

        if response.status_code != 200:
            raise KeycloakConfigError(f"Failed to get admin token: {response.text}")

        token_data = response.json()
        self.token = token_data['access_token']
        self.session.headers.update({'Authorization': f'Bearer {self.token}'})
        return self.token

    def create_realm(self, realm_config):
        """Create or update a Keycloak realm"""
        realm_name = realm_config['realm']
        url = f"{self.keycloak_url}/admin/realms"

        # Check if realm exists
        check_response = self._retry_request(self.session.get, f"{url}/{realm_name}")

        if check_response.status_code == 200:
            print(f"Realm '{realm_name}' already exists - updating configuration")
            update_response = self._retry_request(
                self.session.put,
                f"{url}/{realm_name}",
                json=realm_config
            )
            return update_response.status_code == 204

        # Create new realm
        response = self._retry_request(self.session.post, url, json=realm_config)

        if response.status_code == 201:
            print(f"Created realm: {realm_name}")
            return True
        else:
            raise KeycloakConfigError(f"Failed to create realm: {response.text}")

    def create_groups(self, realm_name, groups):
        """Create groups in the realm"""
        url = f"{self.keycloak_url}/admin/realms/{realm_name}/groups"

        for group_name in groups:
            # Check if group exists
            existing_groups = self._retry_request(self.session.get, url, params={"search": group_name})
            if existing_groups.status_code == 200:
                for group in existing_groups.json():
                    if group['name'] == group_name:
                        print(f"Group '{group_name}' already exists")
                        continue

            group_config = {
                "name": group_name,
                "attributes": {}
            }

            response = self._retry_request(self.session.post, url, json=group_config)
            if response.status_code == 201:
                print(f"Created group: {group_name}")
            else:
                print(f"Warning: Failed to create group {group_name}: {response.text}")

    def create_client(self, realm_name, client_config):
        """Create or update OIDC client"""
        url = f"{self.keycloak_url}/admin/realms/{realm_name}/clients"
        client_id = client_config['clientId']

        # Check if client exists
        clients_response = self._retry_request(self.session.get, url, params={"clientId": client_id})

        if clients_response.status_code == 200:
            clients = clients_response.json()
            if clients:
                print(f"Client '{client_id}' already exists - updating configuration")
                client_uuid = clients[0]['id']
                update_response = self._retry_request(
                    self.session.put,
                    f"{url}/{client_uuid}",
                    json=client_config
                )
                return update_response.status_code == 204

        # Create new client
        response = self._retry_request(self.session.post, url, json=client_config)

        if response.status_code == 201:
            print(f"Created client: {client_id}")
            return True
        else:
            raise KeycloakConfigError(f"Failed to create client: {response.text}")

    def create_users(self, realm_name, users):
        """Create users in the realm"""
        url = f"{self.keycloak_url}/admin/realms/{realm_name}/users"

        for user_data in users:
            username = user_data['username']

            # Check if user exists
            existing_users = self._retry_request(self.session.get, url, params={"username": username})

            if existing_users.status_code == 200 and existing_users.json():
                print(f"User '{username}' already exists")
                continue

            # Create user
            user_config = {
                "username": user_data['username'],
                "email": user_data.get('email'),
                "firstName": user_data.get('firstName'),
                "lastName": user_data.get('lastName'),
                "enabled": True,
                "emailVerified": True,
                "credentials": [{
                    "type": "password",
                    "value": user_data['password'],
                    "temporary": False
                }] if 'password' in user_data else []
            }

            response = self._retry_request(self.session.post, url, json=user_config)

            if response.status_code == 201:
                print(f"Created user: {username}")

                # Add user to groups if specified
                if 'groups' in user_data:
                    user_id = response.headers.get('Location', '').split('/')[-1]
                    self._add_user_to_groups(realm_name, user_id, user_data['groups'])
            else:
                print(f"Warning: Failed to create user {username}: {response.text}")

    def _add_user_to_groups(self, realm_name, user_id, group_names):
        """Add user to specified groups"""
        groups_url = f"{self.keycloak_url}/admin/realms/{realm_name}/groups"

        # Get all groups
        groups_response = self._retry_request(self.session.get, groups_url)
        if groups_response.status_code != 200:
            return

        groups = groups_response.json()

        for group_name in group_names:
            # Find group ID
            group_id = None
            for group in groups:
                if group['name'] == group_name:
                    group_id = group['id']
                    break

            if group_id:
                # Add user to group
                add_url = f"{self.keycloak_url}/admin/realms/{realm_name}/users/{user_id}/groups/{group_id}"
                response = self._retry_request(self.session.put, add_url)
                if response.status_code == 204:
                    print(f"Added user to group: {group_name}")

def main():
    parser = argparse.ArgumentParser(description='Configure Keycloak for Jenkins SSO')
    parser.add_argument('--config-file', required=True, help='JSON configuration file')
    parser.add_argument('--keycloak-url', required=True, help='Keycloak server URL')
    parser.add_argument('--admin-user', required=True, help='Keycloak admin username')
    parser.add_argument('--admin-password', required=True, help='Keycloak admin password')
    parser.add_argument('--timeout', type=int, default=30, help='Request timeout')
    parser.add_argument('--retries', type=int, default=3, help='Number of retries')

    args = parser.parse_args()

    try:
        # Load configuration
        with open(args.config_file, 'r') as f:
            config = json.load(f)

        kc = KeycloakConfig(
            args.keycloak_url,
            args.admin_user,
            args.admin_password,
            timeout=args.timeout,
            retries=args.retries
        )

        print("🔐 Configuring Keycloak for Jenkins SSO...")

        # Get admin token
        print("Getting admin token...")
        kc.get_admin_token()

        # Create realm
        if 'realm' in config:
            print("Configuring realm...")
            kc.create_realm(config['realm'])

        # Create groups
        if 'groups' in config:
            print("Creating groups...")
            realm_name = config['realm']['realm']
            kc.create_groups(realm_name, config['groups'])

        # Create client
        if 'client' in config:
            print("Configuring Jenkins client...")
            realm_name = config['realm']['realm']
            kc.create_client(realm_name, config['client'])

        # Create users
        if 'users' in config:
            print("Creating users...")
            realm_name = config['realm']['realm']
            kc.create_users(realm_name, config['users'])

        print("\n✅ Keycloak configuration completed successfully!")

        # Output configuration summary
        realm_name = config['realm']['realm']
        client_id = config['client']['clientId']
        print(f"\n📋 Configuration Summary:")
        print(f"  Realm: {realm_name}")
        print(f"  Client ID: {client_id}")
        print(f"  Well-known URL: {args.keycloak_url}/realms/{realm_name}/.well-known/openid_configuration")

        if 'users' in config:
            print(f"  Created {len(config['users'])} user(s)")

    except FileNotFoundError:
        print(f"Error: Configuration file '{args.config_file}' not found")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in configuration file: {e}")
        sys.exit(1)
    except KeycloakConfigError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
