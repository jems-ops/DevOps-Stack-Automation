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
keycloak_saml_integration_app_type: "jenkins"  # or "sonarqube"

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
keycloak_saml_integration_test_user:
  enabled: true
  username: "{{ keycloak_saml_integration_app_type }}-demo"
  password: "{{ keycloak_saml_integration_app_name | capitalize }}Demo123!"

# Debug logging
keycloak_saml_integration_debug_logging: false

# HTTPS configuration
keycloak_saml_integration_use_https: true
```

## Directory Structure

```
roles/keycloak_saml_integration/
├── defaults/
│   └── main.yml              # Default variables
├── tasks/
│   ├── main.yml                      # Main task orchestration
│   ├── get_keycloak_token.yml        # Get Keycloak admin token
│   ├── create_saml_client.yml        # Create SAML client in Keycloak
│   ├── configure_protocol_mappers.yml # Configure SAML attribute mappings
│   ├── configure_groups.yml          # Create groups in Keycloak
│   ├── create_test_user.yml          # Create test user with admin perms
│   ├── get_keycloak_certificate.yml  # Fetch Keycloak SAML certificate
│   ├── configure_jenkins_saml.yml    # Jenkins-specific SAML config
│   └── configure_sonarqube_saml.yml  # SonarQube-specific SAML config
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

Use the provided playbook `playbooks/configure-jenkins-saml.yml`:

```yaml
---
- name: Configure Jenkins SAML Integration with Keycloak
  hosts: jenkins_servers
  become: yes

  vars:
    keycloak_saml_integration_app_type: "jenkins"
    jenkins_hostname: "jenkins.local"
    jenkins_base_url: "https://{{ jenkins_hostname }}"
    keycloak_hostname: "keycloak.local"
    keycloak_base_url: "https://{{ keycloak_hostname }}"
    keycloak_saml_integration_use_https: true

  roles:
    - keycloak_saml_integration
```

Run:
```bash
ansible-playbook playbooks/configure-jenkins-saml.yml -i inventory --ask-vault-pass
```

### SonarQube SAML Integration

Use the provided playbook `playbooks/configure-sonarqube-saml.yml`:

```yaml
---
- name: Configure SonarQube SAML Integration with Keycloak
  hosts: sonarqube_servers
  become: yes

  vars:
    keycloak_saml_integration_app_type: "sonarqube"
    sonarqube_hostname: "sonar.local"
    sonarqube_base_url: "https://{{ sonarqube_hostname }}"
    keycloak_hostname: "keycloak.local"
    keycloak_base_url: "https://{{ keycloak_hostname }}"
    keycloak_saml_integration_use_https: true

  roles:
    - keycloak_saml_integration
```

Run:
```bash
ansible-playbook playbooks/configure-sonarqube-saml.yml -i inventory --ask-vault-pass
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

Generates complete Jenkins `config.xml` with:
- SAML Security Realm configuration using `org.jenkinsci.plugins.saml.SamlSecurityRealm`
- Full Control Once Logged In authorization strategy
- IdP metadata fetched dynamically from Keycloak
- User attribute mappings (username, email, displayName)
- Group attribute mapping for role-based access
- Advanced SAML settings (encryption, signing, force authentication)

The Jenkins task:
- Stops Jenkins service before configuration
- Backs up existing `config.xml`
- Applies the SAML template
- Restarts Jenkins and waits for it to be ready

### SonarQube Template (`sonar-saml-config.properties.j2`)

Generates SAML configuration block for `sonar.properties`:
- SAML enabled flag
- Application ID (Keycloak client ID)
- Identity provider configuration (Keycloak URLs)
- Certificate configuration (optional for self-signed certs)
- User attribute mappings (login, name, email)
- Group synchronization via `groups` attribute
- Force authentication setting

The SonarQube task:
- Stops SonarQube service before configuration
- Backs up existing `sonar.properties`
- Uses `blockinfile` to insert SAML config block
- Restarts SonarQube and waits for health check

## Test Users

After deployment, test users are created:

| Application | Username | Password | Groups |
|-------------|----------|----------|--------|
| Jenkins     | `jenkins-demo` | `JenkinsDemo123!` | jenkins-users, jenkins-admins |
| SonarQube   | `sonarqube-demo` | `SonarqubeDemo123!` | sonarqube-users, sonarqube-admins |

## SAML Login URLs

- **Jenkins**: `https://jenkins.local/securityRealm/commenceLogin`
- **SonarQube**: `https://sonar.local` (SSO button on login page)

## Extending for Other Applications

To add support for a new application:

1. Add application config to `defaults/main.yml`:
```yaml
keycloak_saml_integration_app_config:
  myapp:
    home: "/opt/myapp"
    config_file: "conf/myapp.conf"
    service_name: "myapp"
    user: "myapp"
    group: "myapp"
    saml_callback_url: "/saml/callback"
```

2. Create application template in `templates/myapp-saml-config.j2`

3. Create a new task file `tasks/configure_myapp_saml.yml`:
```yaml
---
- name: Stop myapp service
  ansible.builtin.systemd:
    name: myapp
    state: stopped
  become: yes

- name: Backup existing config
  ansible.builtin.copy:
    src: "{{ keycloak_saml_integration_app_config[keycloak_saml_integration_app_type].home }}/{{ keycloak_saml_integration_app_config[keycloak_saml_integration_app_type].config_file }}"
    dest: "{{ keycloak_saml_integration_app_config[keycloak_saml_integration_app_type].home }}/{{ keycloak_saml_integration_app_config[keycloak_saml_integration_app_type].config_file }}.backup.{{ ansible_date_time.epoch }}"
    remote_src: yes
  become: yes

- name: Apply SAML configuration from template
  ansible.builtin.template:
    src: myapp-saml-config.j2
    dest: "{{ keycloak_saml_integration_app_config[keycloak_saml_integration_app_type].home }}/{{ keycloak_saml_integration_app_config[keycloak_saml_integration_app_type].config_file }}"
    owner: "{{ keycloak_saml_integration_app_config[keycloak_saml_integration_app_type].user }}"
    group: "{{ keycloak_saml_integration_app_config[keycloak_saml_integration_app_type].group }}"
  become: yes

- name: Start myapp service
  ansible.builtin.systemd:
    name: myapp
    state: started
  become: yes
```

4. Update `tasks/main.yml` to include the new configure task:
```yaml
- name: Configure MyApp SAML
  ansible.builtin.include_tasks: configure_myapp_saml.yml
  when: keycloak_saml_integration_app_type == 'myapp'
```

5. Create playbook with `keycloak_saml_integration_app_type: "myapp"`

## Dependencies

- Ansible >= 2.9
- Keycloak server installed and accessible
- Target application (Jenkins/SonarQube) installed
- SAML plugin installed on target application

## License

MIT

## Author

DevOps Automation Team
