# SAML Integration Usage Guide

This repository contains a unified SAML integration playbook that works for any application.

## Quick Start

Use the single playbook `configure-keycloak-saml-integration.yml` with the `-e app=<app_name>` parameter:

```bash
# For Artifactory
ansible-playbook playbooks/configure-keycloak-saml-integration.yml \
  -e "app=artifactory" \
  -i inventory

# For Nexus
ansible-playbook playbooks/configure-keycloak-saml-integration.yml \
  -e "app=nexus" \
  -i inventory
```

## Supported Applications

- **Artifactory** (On-premises)
- **Nexus Repository Manager**

## File Structure

```
├── playbooks/
│   └── configure-keycloak-saml-integration.yml  # Unified SAML playbook
├── group_vars/all/
│   └── saml_integration.yml                      # Application URLs and settings
├── roles/keycloak_saml_integration/
│   ├── vars/apps/
│   │   ├── artifactory.yml                       # Artifactory-specific config
│   │   └── nexus.yml                             # Nexus-specific config
│   ├── templates/
│   │   └── artifactory-saml-config.xml.j2       # Artifactory SAML template
│   └── tasks/
│       ├── configure_artifactory_saml.yml        # Artifactory SAML tasks
│       ├── configure_nexus_saml.yml              # Nexus SAML tasks
│       ├── configure_client_roles.yml            # Keycloak roles
│       └── configure_protocol_mappers.yml        # SAML mappers
```

## Configuration Files

### 1. group_vars/all/saml_integration.yml

Contains application URLs and base configuration:

```yaml
# Artifactory (on-premises)
artifactory_hostname: "{{ groups['artifactory_servers'][0] }}"
artifactory_base_url: "http://{{ artifactory_hostname }}"
artifactory_admin_user: "admin"
artifactory_admin_password: "Artifactory@2025"

# Nexus (on-premises)
nexus_hostname: "{{ groups['nexus_servers'][0] }}"
nexus_base_url: "http://{{ nexus_hostname }}"

# Keycloak
keycloak_hostname: "{{ groups['keycloak'][0] }}"
keycloak_base_url: "http://{{ keycloak_hostname }}"
```

### 2. App-specific vars

**roles/keycloak_saml_integration/vars/apps/artifactory.yml**
- Service name, home directory
- Admin credentials
- SAML-specific settings

**roles/keycloak_saml_integration/vars/apps/nexus.yml**
- Similar structure for Nexus

## Adding a New Application

To add support for a new application:

1. Create `roles/keycloak_saml_integration/vars/apps/<app>.yml`
2. Create `roles/keycloak_saml_integration/tasks/configure_<app>_saml.yml`
3. Add application URL to `group_vars/all/saml_integration.yml`
4. Run the playbook with `-e "app=<app>"`

## Configuration

### Keycloak Realm
Default realm: **master**

To use a different realm, override with:
```bash
-e "keycloak_saml_integration_realm_name=devops"
```

### Keycloak Credentials
The playbook uses vault variables for Keycloak admin credentials.
These should be defined in `group_vars/all/vault.yml` or passed as extra vars.

## Keycloak Configuration

The playbook automatically creates in Keycloak:

- ✅ SAML client for the application
- ✅ Client roles (admin, user)
- ✅ Groups (app-admins, app-users)
- ✅ Protocol mappers (username, email, groups)

## Application Configuration

For each application, the playbook:

- ✅ Fetches Keycloak SAML certificate
- ✅ Configures SAML settings via API
- ✅ Enables SSO login
- ✅ Configures group sync and auto-user creation

## Testing

After running the playbook:

1. Open `http://<app>.local` in your browser
2. Look for "Login via SSO" or SAML login option
3. Login with Keycloak credentials (admin/admin123)
4. User should be auto-created with appropriate roles

## Troubleshooting

### Token Expiration (401 Errors)
The Keycloak admin token expires after a few minutes. If you see 401 errors during role mapping, the main SAML configuration usually succeeded. You can manually complete the setup or rerun the playbook.

### Application Not Accessible
- Verify the application is running: `systemctl status <app>`
- Check nginx reverse proxy is configured: `http://<app>.local`
- Verify DNS/hosts file has correct entry

### SAML Login Not Showing
- Check SAML is enabled in application admin UI
- Verify Keycloak certificate was fetched correctly
- Check application logs for SAML errors

## Related Playbooks

- `playbooks/install-nexus.yml` - Install Nexus Repository
- `playbooks/deploy-nexus-complete.yml` - Complete Nexus deployment

## Notes

- Uses HTTP URLs for local development (use HTTPS in production)
- Keycloak realm: `master` (configurable via `-e` parameter)
- All applications use the same Keycloak instance
- Group-based access control via Keycloak groups
