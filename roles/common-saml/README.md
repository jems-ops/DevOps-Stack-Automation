# Common SAML Role

A reusable Ansible role for configuring SAML authentication across multiple applications (SonarQube, Jenkins, etc.). This role follows best practices for maintainability, reusability, and idempotency.

## Features

- **Application-agnostic**: Works with any application that uses properties-based SAML configuration
- **Validation**: Built-in variable validation with clear error messages
- **Idempotent**: Safe to run multiple times without side effects
- **Backup**: Automatic configuration file backup before changes
- **Flexible**: Extensive customization through variables
- **Debug mode**: Enhanced logging for troubleshooting
- **Cleanup**: Automatic removal of temporary files

## Requirements

- Ansible >= 2.9
- Target application must support SAML authentication
- Appropriate permissions to modify application configuration files

## Role Variables

### Required Variables

```yaml
common_saml_app_name: "myapp"                          # Application identifier
common_saml_config_path: "/path/to/config"             # Path to application config file
common_saml_config:
  base_url: "https://myapp.local"                      # Application base URL
  provider_id: "https://keycloak.local/realms/myrealm" # IdP entity ID
  login_url: "https://keycloak.local/realms/myrealm/protocol/saml"  # SSO URL
  application_id: "myapp"                              # SAML client ID
```

### Optional Variables

```yaml
# Application settings
common_saml_app_type: "properties"              # Config format: properties, xml, json
common_saml_service_name: "myapp"               # Systemd service name
common_saml_restart_service: true               # Restart service after config

# Configuration management
common_saml_config_backup: true                 # Backup config before changes
common_saml_config_validate: true               # Validate variables
common_saml_tmp_dir: "/tmp/ansible-saml-myapp"  # Temp directory

# SAML settings
common_saml_config:
  provider_name: "Keycloak SAML"
  sp_entity_id: "myapp"
  force_authentication: false
  logout_url: ""
  sp_certificate: ""
  sp_private_key: ""

  user:
    login: "username"
    name: "name"
    email: "email"
    sign_up_enabled: true
    default_group: ""

  group:
    name: "groups"

  signature:
    enabled: false
    certificate: ""

# Debugging
common_saml_debug: false
```

## Dependencies

None. This role is designed to be self-contained.

## Example Usage

### In a Playbook

```yaml
---
- name: Configure SAML for SonarQube
  hosts: sonarqube
  roles:
    - role: common-saml
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
```

### As a Dependency

In another role's `meta/main.yml`:

```yaml
dependencies:
  - role: common-saml
```

Then in the dependent role's `tasks/main.yml`:

```yaml
---
- name: Configure SonarQube SAML using common role
  ansible.builtin.include_role:
    name: common-saml
  vars:
    common_saml_app_name: "{{ sonarqube_app_name }}"
    common_saml_config_path: "{{ sonarqube_config_path }}"
    common_saml_service_name: "{{ sonarqube_service }}"
    common_saml_config: "{{ sonarqube_saml_config }}"
```

### Using Task Includes

You can include specific tasks for more granular control:

```yaml
---
# Validate only
- name: Validate SAML configuration
  ansible.builtin.include_role:
    name: common-saml
    tasks_from: validate
  vars:
    common_saml_app_name: "myapp"
    common_saml_config: "{{ my_saml_config }}"

# Configure without validation
- name: Apply SAML configuration
  ansible.builtin.include_role:
    name: common-saml
    tasks_from: configure
  vars:
    common_saml_config_validate: false
```

## Role Structure

```
common-saml/
├── README.md                  # This file
├── defaults/
│   └── main.yml              # Default variables
├── tasks/
│   ├── main.yml              # Main task orchestration
│   ├── validate.yml          # Variable validation
│   ├── configure.yml         # SAML configuration
│   └── cleanup.yml           # Temporary file cleanup
├── templates/
│   └── saml-config.properties.j2  # SAML config template
├── vars/
│   ├── sonarqube_example.yml      # SonarQube example
│   └── jenkins_example.yml        # Jenkins example
├── handlers/
│   └── main.yml              # Service restart handlers (optional)
└── meta/
    └── main.yml              # Role metadata
```

## Tags

This role supports the following tags for selective execution:

- `saml` - All SAML-related tasks
- `saml-validate` - Only validation tasks
- `saml-configure` - Only configuration tasks
- `saml-cleanup` - Only cleanup tasks

Example:

```bash
ansible-playbook playbook.yml --tags saml-validate
```

## Handlers

The role expects a handler named `restart_<service_name>` in the calling role or playbook. Example:

```yaml
# handlers/main.yml in your role or playbook
---
- name: restart_sonarqube
  ansible.builtin.systemd:
    name: sonarqube
    state: restarted
  become: true
```

## Best Practices

1. **Variable Organization**: Define application-specific variables in `group_vars` or role defaults
2. **Secrets Management**: Use Ansible Vault for sensitive SAML certificates and keys
3. **Testing**: Test in a non-production environment first
4. **Validation**: Keep `common_saml_config_validate: true` for safety
5. **Backups**: Keep `common_saml_config_backup: true` to enable rollback
6. **Debugging**: Use `common_saml_debug: true` when troubleshooting

## Integration with Existing Roles

### SonarQube Integration

Update `sonarqube-keycloak-saml` role to use common-saml:

```yaml
# roles/sonarqube-keycloak-saml/meta/main.yml
dependencies:
  - common-saml

# roles/sonarqube-keycloak-saml/tasks/configure_sonarqube_saml.yml
---
- name: Configure SonarQube SAML via common role
  ansible.builtin.include_role:
    name: common-saml
  vars:
    common_saml_app_name: "sonarqube"
    common_saml_app_type: "properties"
    common_saml_config_path: "{{ sonarqube_keycloak_saml_sonarqube.config_path }}"
    common_saml_service_name: "{{ sonarqube_keycloak_saml_sonarqube.service_name }}"
    common_saml_config:
      base_url: "{{ sonarqube_keycloak_saml_sonarqube.base_url }}"
      force_authentication: "{{ sonarqube_keycloak_saml_sonarqube.saml.force_authentication }}"
      enabled: "{{ sonarqube_keycloak_saml_sonarqube.saml.enabled }}"
      application_id: "{{ sonarqube_keycloak_saml_sonarqube.saml.application_id }}"
      provider_name: "{{ sonarqube_keycloak_saml_sonarqube.saml.provider_name }}"
      provider_id: "{{ sonarqube_keycloak_saml_sonarqube.saml.provider_id }}"
      login_url: "{{ sonarqube_keycloak_saml_sonarqube.saml.login_url }}"
      sp_entity_id: "{{ sonarqube_keycloak_saml_sonarqube.saml.sp_entity_id }}"
      user: "{{ sonarqube_keycloak_saml_sonarqube.saml.user }}"
      group: "{{ sonarqube_keycloak_saml_sonarqube.saml.group }}"
```

## Troubleshooting

### Common Issues

1. **Validation fails**: Check that all required variables are defined and non-empty
2. **Permission denied**: Ensure the role has appropriate privileges (`become: true`)
3. **Service doesn't restart**: Verify handler name matches `restart_<service_name>` format
4. **Template not found**: Check `common_saml_app_type` matches available templates

### Debug Mode

Enable debug mode for detailed output:

```yaml
common_saml_debug: true
```

### Manual Verification

Check generated configuration:

```bash
cat /tmp/ansible-saml-myapp/saml-config-hostname.properties
```

## License

MIT

## Author

DevOps Team

## Contributing

When adding support for new applications:

1. Create a new example variable file in `vars/`
2. Test with the new application
3. Update this README with integration examples
4. Consider adding application-specific templates if needed
