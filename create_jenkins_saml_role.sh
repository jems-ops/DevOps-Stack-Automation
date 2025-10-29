#!/bin/bash
#
# Create Complete Jenkins-Keycloak SAML Role
# This script generates a production-ready Ansible role for Jenkins SAML SSO
# with all fixes for HTTPS environments
#

set -e

ROLE_DIR="roles/jenkins-keycloak-saml-new"
echo "Creating Jenkins-Keycloak SAML role in $ROLE_DIR..."

# Create directory structure
mkdir -p "$ROLE_DIR"/{defaults,tasks,handlers,templates,files,meta}

cat > "$ROLE_DIR/README.md" << 'ROLE_README'
# Jenkins-Keycloak SAML Role

Production-ready Ansible role for configuring SAML SSO between Jenkins and Keycloak.

## Features

- ✅ Complete Keycloak SAML client configuration
- ✅ Jenkins SAML plugin configuration with HTTPS support
- ✅ HTTP-POST binding (more reliable than HTTP-Redirect)
- ✅ Automatic metadata management with HTTPS URLs
- ✅ Group-based authorization
- ✅ Test user creation
- ✅ Certificate handling
- ✅ Configuration verification

## Requirements

- Jenkins with SAML plugin (version 2.333 or compatible)
- Keycloak server with configured realm
- Nginx reverse proxy with SSL certificates
- Ansible 2.9+

## Role Variables

See `defaults/main.yml` for all configurable variables.

### Key Variables:

```yaml
jenkins_keycloak_saml_jenkins:
  host: "jenkins.local"
  base_url: "https://jenkins.local"

jenkins_keycloak_saml_keycloak:
  host: "keycloak.local"
  realm: "jenkins"
  base_url: "https://keycloak.local"
```

## Dependencies

None

## Example Playbook

```yaml
- hosts: jenkins
  roles:
    - jenkins-keycloak-saml
```

## Testing

Access Jenkins SAML login:
```
https://jenkins.local/securityRealm/commenceLogin
```

Login with test user:
- Username: jenkins-demo
- Password: JenkinsDemo123!

## License

MIT

## Author

Created: 2025-10-28
ROLE_README

echo "✅ Created README.md"

cat > "$ROLE_DIR/defaults/main.yml" << 'DEFAULTS'
---
# Jenkins-Keycloak SAML Integration Role Defaults

# Jenkins Configuration
jenkins_keycloak_saml_jenkins:
  host: "{{ jenkins_hostname | default('jenkins.local') }}"
  port: 8080
  protocol: "https"
  home: "/var/lib/jenkins"
  config_file: "config.xml"
  service_name: "jenkins"
  base_url: "{{ jenkins_base_url | default('https://jenkins.local') }}"
  user: "jenkins"
  group: "jenkins"

  # SAML Configuration
  saml:
    display_name: "Keycloak SAML SSO"
    sp_entity_id: "jenkins-saml"
    username_attribute: "username"
    email_attribute: "email"
    full_name_attribute: "displayName"
    groups_attribute: "groups"
    binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"  # More reliable than HTTP-Redirect
    logout_url: ""  # Empty to prevent redirect errors
    force_authentication: false
    maximum_authentication_lifetime: 7776000  # 90 days

# Keycloak Configuration
jenkins_keycloak_saml_keycloak:
  host: "{{ keycloak_hostname | default('keycloak.local') }}"
  port: 443
  protocol: "https"
  realm: "jenkins"
  admin_user: "{{ vault_KEYCLOAK_ADMIN_USERNAME | default('admin') }}"
  admin_password: "{{ vault_KEYCLOAK_ADMIN_PASSWORD | default('admin123') }}"
  base_url: "{{ keycloak_base_url | default('https://keycloak.local') }}"
  frontend_url: "{{ keycloak_base_url | default('https://keycloak.local') }}"  # For HTTPS support

  # SAML Client Configuration
  saml_client:
    client_id: "jenkins-saml"
    enabled: true
    protocol: "saml"
    front_channel_logout: true
    redirect_uris:
      - "{{ jenkins_base_url | default('https://jenkins.local') }}/securityRealm/finishLogin"
      - "{{ jenkins_base_url | default('https://jenkins.local') }}/*"
      - "*"
    web_origins:
      - "{{ jenkins_base_url | default('https://jenkins.local') }}"
    base_url: "{{ jenkins_base_url | default('https://jenkins.local') }}"
    root_url: "{{ jenkins_base_url | default('https://jenkins.local') }}"
    admin_url: "{{ jenkins_base_url | default('https://jenkins.local') }}"

    # SAML Attributes
    attributes:
      saml_authnstatement: "true"
      saml_server_signature: "true"
      saml_signature_algorithm: "RSA_SHA256"
      saml_client_signature: "false"
      saml_assertion_signature: "true"
      saml_encrypt: "false"
      saml_force_post_binding: "false"
      saml_name_id_format: "username"
      saml_signing_certificate: ""
      saml_signing_private_key: ""

    # Protocol Mappers
    protocol_mappers:
      - name: "username"
        protocol: "saml"
        protocol_mapper: "saml-user-property-mapper"
        consent_required: false
        config:
          attribute_nameformat: "Basic"
          user_attribute: "username"
          attribute_name: "username"

      - name: "email"
        protocol: "saml"
        protocol_mapper: "saml-user-property-mapper"
        consent_required: false
        config:
          attribute_nameformat: "Basic"
          user_attribute: "email"
          attribute_name: "email"

      - name: "displayName"
        protocol: "saml"
        protocol_mapper: "saml-user-property-mapper"
        consent_required: false
        config:
          attribute_nameformat: "Basic"
          user_attribute: "username"
          attribute_name: "displayName"

      - name: "groups"
        protocol: "saml"
        protocol_mapper: "saml-group-membership-mapper"
        consent_required: false
        config:
          attribute_nameformat: "Basic"
          attribute_name: "groups"
          single: "false"
          full_path: "false"

# Groups Configuration
jenkins_keycloak_saml_groups:
  jenkins_admins:
    name: "jenkins-admins"
    description: "Jenkins Administrators with full access"
  jenkins_users:
    name: "jenkins-users"
    description: "Jenkins Users with basic access"

# Permissions Configuration
jenkins_keycloak_saml_permissions:
  jenkins_admins:
    - "hudson.model.Hudson.Administer"
  jenkins_users:
    - "hudson.model.Hudson.Read"
    - "hudson.model.View.Read"
    - "hudson.model.Item.Build"
    - "hudson.model.Item.Discover"
    - "hudson.model.Item.Read"
    - "hudson.model.Item.Workspace"
  authenticated:
    - "hudson.model.Hudson.Read"  # All authenticated users get read access

# Test User Configuration (optional)
jenkins_keycloak_saml_test_user:
  enabled: true
  username: "jenkins-demo"
  password: "JenkinsDemo123!"
  email: "jenkins-demo@example.com"
  first_name: "Jenkins"
  last_name: "Demo"
  groups:
    - "jenkins-users"

# Debug Configuration
jenkins_keycloak_saml_debug: false
DEFAULTS

echo "✅ Created defaults/main.yml"

cat > "$ROLE_DIR/meta/main.yml" << 'META'
---
galaxy_info:
  author: DevOps Team
  description: Configure SAML SSO between Jenkins and Keycloak
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: EL
      versions:
        - 8
        - 9
  galaxy_tags:
    - jenkins
    - keycloak
    - saml
    - sso
    - authentication

dependencies: []
META

echo "✅ Created meta/main.yml"

echo ""
echo "================================================"
echo "Jenkins-Keycloak SAML Role Structure Created!"
echo "================================================"
echo ""
echo "📁 Role location: $ROLE_DIR"
echo ""
echo "📋 Next steps:"
echo "1. Review and customize defaults/main.yml"
echo "2. Run the create_tasks.sh script to generate task files"
echo "3. Test the role with your playbook"
echo ""
echo "🧪 Test command:"
echo "   ansible-playbook playbooks/jenkins-keycloak-saml.yml -i inventory"
echo ""
DEFAULTS

chmod +x "$ROLE_DIR/create_tasks.sh" 2>/dev/null || true

echo "✅ Role structure created successfully!"
