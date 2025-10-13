# SonarQube-Keycloak SAML Role Usage

The `sonarqube-keycloak-saml` role has been created to simplify and standardize SAML SSO configuration between SonarQube and Keycloak.

## Quick Start

### 1. Basic Usage

```bash
# Run the role with default settings
ansible-playbook -i inventory playbooks/configure-sonarqube-keycloak-saml-role.yml
```

### 2. Custom Configuration

Edit `group_vars/all/main.yml` or create host-specific variables:

```yaml
# Custom Keycloak settings
keycloak:
  host: "your-keycloak-server"
  admin_password: "{{ vault_keycloak_password }}"

# Enable test user
test_user:
  enabled: true
  username: "testuser"
  password: "{{ vault_test_password }}"
```

### 3. Production Deployment

For production, use HTTPS and secure passwords:

```yaml
sonarqube:
  host: "sonar.company.com"
  protocol: "https"
  port: 443

keycloak:
  host: "keycloak.company.com"
  protocol: "https"
  port: 443
  admin_password: "{{ vault_production_password }}"

debug_logging: false
test_user:
  enabled: false
```

## Role Features

✅ **All configurations from our working setup**:
- HTTP POST binding enforcement (fixes SAML response errors)
- Complete protocol mapper configuration (username, email, name, groups)
- Automatic certificate management
- Group creation and user provisioning
- Force authentication disabled for auto-provisioning

✅ **Production-ready**:
- Comprehensive error handling
- Configuration validation
- Health checks and verification
- Secure password handling with Ansible Vault

✅ **Flexible**:
- Configurable for any environment
- Optional test user creation
- Debug logging support
- Tag-based execution

## Migrating from Old Playbooks

Instead of running individual playbooks like:
- `configure-sonarqube-saml.yml`
- `create-sonarqube-saml-client.yml`
- Manual certificate extraction steps

Now you can simply run:
```bash
ansible-playbook -i inventory playbooks/configure-sonarqube-keycloak-saml-role.yml
```

## Benefits

1. **Consistency**: Same configuration every time
2. **Maintainability**: Single role to maintain instead of multiple playbooks
3. **Reliability**: Comprehensive error handling and validation
4. **Documentation**: Clear variables and usage examples
5. **Reusability**: Can be used across different environments
6. **Testing**: Built-in verification and health checks

## Files Created

The role creates a complete, organized structure:

```
roles/sonarqube-keycloak-saml/
├── README.md                    # Comprehensive documentation
├── defaults/main.yml           # Default variables
├── handlers/main.yml           # Service management
├── meta/main.yml              # Role metadata
└── tasks/
    ├── main.yml               # Main orchestration
    ├── configure_sonarqube_saml.yml
    ├── get_keycloak_token.yml
    ├── create_keycloak_saml_client.yml
    ├── configure_protocol_mappers.yml
    ├── configure_groups.yml
    ├── get_keycloak_certificate.yml
    ├── update_sonarqube_certificate.yml
    ├── create_test_user.yml    # Optional
    ├── debug_logging.yml       # Optional
    └── verify_configuration.yml
```

This role encapsulates all the knowledge and fixes we discovered during our troubleshooting session, making SAML SSO setup reliable and repeatable.
