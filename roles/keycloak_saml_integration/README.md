# Keycloak SAML SSO Integration

Unified Ansible role for configuring SAML SSO between Keycloak and multiple applications.

## Supported Apps

✅ Jenkins | ✅ SonarQube | ✅ Artifactory

## Project Structure

```
roles/keycloak_saml_integration/
├── vars/apps/                      # App-specific configs
│   ├── jenkins.yml
│   ├── sonarqube.yml
│   └── artifactory.yml
├── tasks/
│   ├── configure_jenkins_saml.yml
│   ├── configure_sonarqube_saml.yml
│   └── configure_artifactory_saml.yml
└── templates/
    ├── jenkins-saml-config.xml.j2
    ├── sonarqube-saml-config.properties.j2
    └── artifactory-saml-config.xml.j2
```

## How to Add a New App

### 1. Create `vars/apps/myapp.yml`
```yaml
keycloak_saml_integration_app_config:
  home: "/opt/myapp"
  config_file: "config.xml"
  service_name: "myapp"
  saml_callback_url: "/saml/callback"

# Authorization is driven by the SAML `groups` attribute populated from
# FreeIPA via the LDAP group-ldap-mapper. Create your app's admin group
# in FreeIPA (e.g. `myapp-administrators`) and rely on it appearing in
# the SAML assertion; do not declare Keycloak-side groups or test users
# in this role.
```

### 2. Create `tasks/configure_myapp_saml.yml`
```yaml
- name: Stop MyApp service
  ansible.builtin.systemd:
    name: myapp
    state: stopped

- name: Apply SAML configuration
  ansible.builtin.template:
    src: myapp-saml-config.j2
    dest: /opt/myapp/config.xml

- name: Start MyApp service
  ansible.builtin.systemd:
    name: myapp
    state: started
```

### 3. Create `templates/myapp-saml-config.j2`
Template with your app's SAML configuration format.

### 4. Update `tasks/main.yml`
Add `myapp` to supported apps list:
```yaml
keycloak_saml_integration_app_type in ['jenkins', 'sonarqube', 'artifactory', 'myapp']
```

## How to Run

```bash
# Jenkins
ansible-playbook playbooks/configure-keycloak-saml-integration.yml -e "app=jenkins"

# SonarQube
ansible-playbook playbooks/configure-keycloak-saml-integration.yml -e "app=sonarqube"

# Artifactory
ansible-playbook playbooks/configure-keycloak-saml-integration.yml -e "app=artifactory"
```

## What It Does

1. ✅ Creates Keycloak realm and SAML client
2. ✅ Configures protocol mappers (username, email, groups)
3. ✅ Fetches and validates SAML metadata (with curl fallback)
4. ✅ Applies app-specific SAML configuration
5. ✅ Restarts application service

User identities and group membership are sourced from FreeIPA via the
`ldap_federation` submodule of this role; this role does NOT create
Keycloak-managed users, groups, or client roles.

## Metadata Validation

Auto-validates SAML metadata with fallback:
- **Primary**: Ansible `uri` module
- **Fallback**: `curl -k` on target server (if validation fails)
- **Shows**: Which method was used (ansible-uri vs curl-fallback)

## Test

```bash
# Lint check
ansible-lint playbooks/configure-keycloak-saml-integration.yml roles/keycloak_saml_integration/

# Test login URLs
curl -I https://jenkins.local/securityRealm/commenceLogin
curl -I https://sonar.local
curl -I http://artifactory.local/artifactory/webapp/#/login
```
