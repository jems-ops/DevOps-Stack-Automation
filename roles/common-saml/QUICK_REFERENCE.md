# Common SAML Role - Quick Reference

## 🚀 Quick Start

### Basic Usage

```yaml
- name: Configure SAML
  ansible.builtin.include_role:
    name: common-saml
  vars:
    common_saml_app_name: "myapp"
    common_saml_config_path: "/path/to/config"
    common_saml_service_name: "myapp"
    common_saml_config:
      base_url: "https://myapp.local"
      provider_id: "https://keycloak.local/realms/myrealm"
      login_url: "https://keycloak.local/realms/myrealm/protocol/saml"
      application_id: "myapp"
```

## 📋 Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `common_saml_app_name` | Application name | `"sonarqube"` |
| `common_saml_config_path` | Config file path | `"/opt/sonarqube/conf/sonar.properties"` |
| `common_saml_config.base_url` | App base URL | `"https://sonar.local"` |
| `common_saml_config.provider_id` | IdP entity ID | `"https://keycloak.local/realms/sonar"` |
| `common_saml_config.login_url` | SSO login URL | `"https://keycloak.local/realms/sonar/protocol/saml"` |
| `common_saml_config.application_id` | SAML client ID | `"sonarqube"` |

## 🎛️ Common Options

```yaml
# Optional settings
common_saml_app_type: "properties"           # Config format
common_saml_service_name: "myapp"            # Service to restart
common_saml_config_backup: true              # Backup before changes
common_saml_config_validate: true            # Validate variables
common_saml_debug: false                     # Debug mode

# Optional SAML settings
common_saml_config:
  force_authentication: false
  logout_url: ""
  sp_entity_id: "myapp"
  user:
    login: "username"
    name: "name"
    email: "email"
    sign_up_enabled: true
    default_group: "users"
  group:
    name: "groups"
```

## 🏷️ Tags

```bash
# All SAML tasks
ansible-playbook playbook.yml --tags saml

# Validation only
ansible-playbook playbook.yml --tags saml-validate

# Configuration only
ansible-playbook playbook.yml --tags saml-configure

# Cleanup only
ansible-playbook playbook.yml --tags saml-cleanup
```

## 🔍 Debug Mode

```yaml
common_saml_debug: true
```

Shows:
- Configuration summary before applying
- Detailed task output
- Cleanup status

## 📦 SonarQube Example

```yaml
- name: Configure SonarQube SAML
  ansible.builtin.include_role:
    name: common-saml
  vars:
    common_saml_app_name: "sonarqube"
    common_saml_app_type: "properties"
    common_saml_config_path: "/opt/sonarqube/conf/sonar.properties"
    common_saml_service_name: "sonarqube"
    common_saml_config:
      base_url: "https://sonar.local"
      provider_id: "https://keycloak.local/realms/sonar"
      login_url: "https://keycloak.local/realms/sonar/protocol/saml"
      application_id: "sonarqube"
      user:
        login: "username"
        name: "name"
        email: "email"
        sign_up_enabled: true
        default_group: "sonar-users"
      group:
        name: "groups"
```

## 🔧 Jenkins Example

```yaml
- name: Configure Jenkins SAML
  ansible.builtin.include_role:
    name: common-saml
  vars:
    common_saml_app_name: "jenkins"
    common_saml_app_type: "properties"
    common_saml_config_path: "/var/lib/jenkins/config.xml"
    common_saml_service_name: "jenkins"
    common_saml_config:
      base_url: "https://jenkins.local"
      provider_id: "https://keycloak.local/realms/jenkins"
      login_url: "https://keycloak.local/realms/jenkins/protocol/saml"
      application_id: "jenkins"
      user:
        login: "username"
        name: "displayName"
        email: "email"
        sign_up_enabled: true
      group:
        name: "groups"
```

## ⚠️ Common Issues

### Validation Fails
✅ **Solution**: Ensure all required variables are set

### Permission Denied
✅ **Solution**: Ensure `become: true` is set appropriately

### Handler Not Found
✅ **Solution**: Add handler to your role:
```yaml
- name: restart_myapp
  ansible.builtin.systemd:
    name: myapp
    state: restarted
  become: true
```

### Template Not Found
✅ **Solution**: Check `common_saml_app_type` matches template name

## 📁 File Locations

- **Role**: `roles/common-saml/`
- **Examples**: `roles/common-saml/vars/*_example.yml`
- **Template**: `roles/common-saml/templates/saml-config.properties.j2`
- **Docs**: `roles/common-saml/README.md`
- **Guide**: `docs/SAML_REFACTORING_GUIDE.md`

## 🔐 Secrets Management

```yaml
# Use Ansible Vault
common_saml_config:
  sp_certificate: "{{ vault_saml_certificate }}"
  sp_private_key: "{{ vault_saml_private_key }}"
```

## ✅ Best Practices

1. ✅ Always validate in non-production first
2. ✅ Keep backups enabled (`common_saml_config_backup: true`)
3. ✅ Use Ansible Vault for sensitive data
4. ✅ Enable validation (`common_saml_config_validate: true`)
5. ✅ Use debug mode when troubleshooting
6. ✅ Test with `--check` mode first

## 📚 Full Documentation

- [README.md](README.md) - Complete documentation
- [SAML_REFACTORING_GUIDE.md](../../docs/SAML_REFACTORING_GUIDE.md) - Architecture and migration guide
