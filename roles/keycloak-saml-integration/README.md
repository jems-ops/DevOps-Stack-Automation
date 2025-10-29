# Keycloak SAML Integration Role

A generic Ansible role for integrating applications with Keycloak using SAML SSO. This role supports multiple applications including **Jenkins** and **SonarQube**.

## Features

- ✅ Generic, reusable role for multiple applications
- ✅ Automatic Keycloak SAML client creation and configuration
- ✅ Protocol mapper setup (username, email, firstName, lastName, displayName, groups)
- ✅ Group management (admin and user groups)
- ✅ Test user creation with configurable permissions
- ✅ Application-specific templates (Jenkins config.xml, SonarQube sonar.properties)
- ✅ HTTPS support with self-signed certificates
- ✅ Idempotent playbook execution

## Supported Applications

| Application | App Type | Config Template |
|-------------|----------|----------------|
| Jenkins     | `jenkins` | `jenkins-saml-config.xml.j2` |
| SonarQube   | `sonarqube` | `sonar-saml-config.properties.j2` |

## Role Variables

### Required Variables

```yaml
# Set the application type (jenkins or sonarqube)
keycloak_saml_app_type: "jenkins"  # or "sonarqube"

# Vault variables (from group_vars/all/vault.yml)
vault_KEYCLOAK_ADMIN_USERNAME: "admin"
vault_KEYCLOAK_ADMIN_PASSWORD: "your-password"
```

### Application URLs

These are automatically resolved from `group_vars/all/saml_integration.yml`:

```yaml
jenkins_hostname: "jenkins.local"
jenkins_base_url: "https://jenkins.local"

sonarqube_hostname: "sonar.local"
sonarqube_base_url: "https://sonar.local"

keycloak_hostname: "keycloak.local"
keycloak_base_url: "https://keycloak.local"
```

### Optional Variables

```yaml
# Enable/disable test user creation
keycloak_saml_test_user:
  enabled: true
  username: "{{ keycloak_saml_app_type }}-demo"
  password: "{{ keycloak_saml_app_name | capitalize }}Demo123!"

# Debug logging
keycloak_saml_debug_logging: false

# HTTPS configuration
keycloak_saml_use_https: true
```

## Directory Structure

```
roles/keycloak-saml-integration/
├── defaults/
│   └── main.yml              # Default variables
├── tasks/
│   ├── main.yml              # Main task orchestration
│   ├── get_keycloak_token.yml
│   ├── create_saml_client.yml
│   ├── configure_protocol_mappers.yml
│   ├── configure_groups.yml
│   ├── create_test_user.yml
│   ├── get_keycloak_certificate.yml
│   └── configure_app_saml.yml
├── templates/
│   ├── jenkins-saml-config.xml.j2
│   └── sonar-saml-config.properties.j2
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
└── README.md
```

## Usage

### Jenkins SAML Integration

Create a playbook `playbooks/jenkins-saml.yml`:

```yaml
---
- name: Jenkins-Keycloak SAML Integration
  hosts: jenkins
  become: true
  gather_facts: true

  vars:
    keycloak_saml_app_type: "jenkins"

  roles:
    - keycloak-saml-integration
```

Run:
```bash
ansible-playbook playbooks/jenkins-saml.yml -i inventory --ask-vault-pass
```

### SonarQube SAML Integration

Create a playbook `playbooks/sonarqube-saml.yml`:

```yaml
---
- name: SonarQube-Keycloak SAML Integration
  hosts: sonarqube
  become: true
  gather_facts: true

  vars:
    keycloak_saml_app_type: "sonarqube"

  roles:
    - keycloak-saml-integration
```

Run:
```bash
ansible-playbook playbooks/sonarqube-saml.yml -i inventory --ask-vault-pass
```

## How It Works

1. **Token Acquisition**: Obtains admin access token from Keycloak
2. **Client Creation**: Creates/updates SAML client in Keycloak for the application
3. **Protocol Mappers**: Configures attribute mappings (username, email, groups, etc.)
4. **Group Setup**: Creates admin and user groups in Keycloak
5. **Test User**: Optionally creates a test user with admin permissions
6. **Certificate**: Retrieves Keycloak SAML certificate
7. **Application Config**: Deploys application-specific SAML configuration
8. **Service Restart**: Restarts the application service

## Application-Specific Templates

### Jenkins Template (`jenkins-saml-config.xml.j2`)

Generates complete `config.xml` with:
- SAML Security Realm configuration
- Full Control Once Logged In authorization strategy
- IdP metadata from Keycloak
- Attribute mappings

### SonarQube Template (`sonar-saml-config.properties.j2`)

Generates SAML properties for `sonar.properties`:
- SAML enabled flag
- Identity provider configuration
- Attribute mappings
- Group synchronization

## Test Users

After deployment, test users are created:

| Application | Username | Password | Groups |
|-------------|----------|----------|--------|
| Jenkins     | `jenkins-demo` | `JenkinsDemo123!` | jenkins-users, jenkins-admins |
| SonarQube   | `sonarqube-demo` | `SonarqubeDemo123!` | sonar-users, sonar-admins |

## SAML Login URLs

- **Jenkins**: `https://jenkins.local/securityRealm/commenceLogin`
- **SonarQube**: `https://sonar.local` (SSO button on login page)

## Extending for Other Applications

To add support for a new application:

1. Add application config to `defaults/main.yml`:
```yaml
keycloak_saml_app_config:
  myapp:
    home: "/opt/myapp"
    config_file: "conf/myapp.conf"
    service_name: "myapp"
    user: "myapp"
    group: "myapp"
    saml_callback_url: "/saml/callback"
```

2. Create application template in `templates/myapp-saml-config.j2`

3. Update `tasks/configure_app_saml.yml` to handle the new app type

4. Create playbook with `keycloak_saml_app_type: "myapp"`

## Dependencies

- Ansible >= 2.9
- Keycloak server installed and accessible
- Target application (Jenkins/SonarQube) installed
- SAML plugin installed on target application

## License

MIT

## Author

DevOps Automation Team
