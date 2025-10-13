# SonarQube-Keycloak SAML Integration Role

This Ansible role configures SAML SSO integration between SonarQube and Keycloak, enabling seamless single sign-on authentication.

## Features

- ✅ Complete SAML configuration for SonarQube
- ✅ Keycloak SAML client creation and configuration
- ✅ Protocol mappers for user attributes (username, email, name, groups)
- ✅ Group mapping and user provisioning
- ✅ Automatic certificate management
- ✅ HTTP POST binding enforcement (critical for compatibility)
- ✅ Optional test user creation
- ✅ Configuration verification and health checks
- ✅ Debug logging support

## Requirements

- Ansible >= 2.14
- SonarQube installed and running
- Keycloak installed and running
- Network connectivity between SonarQube and Keycloak
- Administrative access to both systems

## Role Variables

### SonarQube Configuration

```yaml
sonarqube:
  host: "192.168.201.16"          # SonarQube server IP/hostname
  port: 9000                      # SonarQube port
  protocol: "http"                # Protocol (http/https)
  config_path: "/opt/sonarqube/conf/sonar.properties"
  service_name: "sonarqube"       # Service name for systemctl
```

### Keycloak Configuration

```yaml
keycloak:
  host: "192.168.201.12"          # Keycloak server IP/hostname
  port: 8080                      # Keycloak port
  protocol: "http"                # Protocol (http/https)
  realm: "sonar"                  # Keycloak realm name
  admin_user: "admin"             # Keycloak admin username
  admin_password: "admin123"      # Keycloak admin password
```

### SAML Configuration

The role automatically configures all SAML settings including:
- Application ID and Provider URLs
- User attribute mappings (username, email, name)
- Group mappings
- Certificate management
- HTTP POST binding enforcement

### Optional Features

```yaml
# Enable debug logging
debug_logging: false

# Create a test user
test_user:
  enabled: true                   # Set to true to create test user
  username: "testuser"
  password: "testpass123"
  email: "testuser@example.com"
  first_name: "Test"
  last_name: "User"
```

## Dependencies

None. This role is self-contained.

## Example Playbook

### Basic Usage

```yaml
---
- name: Configure SonarQube-Keycloak SAML Integration
  hosts: sonarqube
  become: true
  roles:
    - role: sonarqube-keycloak-saml
      vars:
        sonarqube:
          host: "192.168.201.16"
          port: 9000
        keycloak:
          host: "192.168.201.12"
          port: 8080
          realm: "sonar"
          admin_user: "admin"
          admin_password: "{{ keycloak_admin_password }}"
```

### Advanced Usage with Custom Configuration

```yaml
---
- name: Configure SonarQube-Keycloak SAML Integration
  hosts: sonarqube
  become: true
  roles:
    - role: sonarqube-keycloak-saml
      vars:
        # Custom SonarQube configuration
        sonarqube:
          host: "sonar.company.com"
          port: 443
          protocol: "https"

        # Custom Keycloak configuration
        keycloak:
          host: "keycloak.company.com"
          port: 443
          protocol: "https"
          realm: "production"
          admin_user: "admin"
          admin_password: "{{ vault_keycloak_password }}"

        # Enable debug logging
        debug_logging: true

        # Create test user
        test_user:
          enabled: true
          username: "demo.user"
          password: "{{ vault_test_password }}"
          email: "demo@company.com"
```

### Playbook with Tags

```yaml
---
- name: Configure SAML Integration
  hosts: sonarqube
  become: true
  roles:
    - sonarqube-keycloak-saml
  tags:
    - sonarqube
    - keycloak
    - saml
```

## Usage

### 1. Basic Deployment

```bash
# Run the complete role
ansible-playbook -i inventory site.yml

# Run with specific tags
ansible-playbook -i inventory site.yml --tags "sonarqube,saml"
```

### 2. Configuration Only

```bash
# Configure only SonarQube settings
ansible-playbook -i inventory site.yml --tags "sonarqube"

# Configure only Keycloak settings
ansible-playbook -i inventory site.yml --tags "keycloak"
```

### 3. Verification Only

```bash
# Run verification checks
ansible-playbook -i inventory site.yml --tags "verify"
```

## Available Tags

- `validate` - Validate required variables
- `debug` - Enable debug logging
- `sonarqube` - Configure SonarQube SAML settings
- `keycloak` - Configure Keycloak SAML client
- `saml` - All SAML-related tasks
- `client` - Create Keycloak SAML client
- `mappers` - Configure protocol mappers
- `groups` - Configure groups
- `certificate` - Certificate management
- `test_user` - Create test user (if enabled)
- `restart` - Restart services
- `verify` - Verification and health checks

## Post-Installation

After running this role successfully:

1. **Access SonarQube**: Navigate to your SonarQube URL (e.g., `http://192.168.201.16:9000`)
2. **Test SSO**: Click "Log in with Keycloak SAML"
3. **Authenticate**: Use Keycloak credentials (or test user if created)
4. **Verify**: Confirm user is created and has appropriate permissions

## Troubleshooting

### Common Issues

1. **"SAML Response not found" Error**
   - The role automatically configures HTTP POST binding to prevent this
   - Verify `saml.force.post.binding=true` in Keycloak client settings

2. **"name is missing" Error**
   - The role creates all required protocol mappers
   - Verify username, email, name, and groups mappers exist

3. **Authorization Errors**
   - The role creates and configures the sonar-users group
   - Verify users are assigned to this group in Keycloak

4. **Certificate Issues**
   - The role automatically extracts and configures Keycloak certificates
   - Check certificate validity in SonarQube configuration

### Debug Mode

Enable debug logging to troubleshoot issues:

```yaml
debug_logging: true
```

This will:
- Enable DEBUG logging in SonarQube
- Display detailed configuration information
- Show all variable values during execution

### Manual Verification

You can manually verify the configuration:

```bash
# Check SonarQube SAML settings
grep -i saml /opt/sonarqube/conf/sonar.properties

# Test SAML initiation endpoint
curl -I http://192.168.201.16:9000/sessions/init/saml

# Check SonarQube logs
tail -f /opt/sonarqube/logs/web.log
```

## Security Considerations

- Use Ansible Vault for sensitive passwords
- Configure HTTPS in production environments
- Regularly update Keycloak certificates
- Monitor authentication logs
- Use strong passwords for test users

## Version Compatibility

| Component | Tested Versions |
|-----------|-----------------|
| SonarQube | 9.x, 10.x |
| Keycloak | 20.x, 21.x, 22.x |
| Ansible | 2.14+, 2.15+ |

## Contributing

1. Test changes with molecule
2. Update documentation for new variables
3. Follow existing code style
4. Add appropriate tags to new tasks

## License

MIT

## Author

DevOps Team

## Changelog

### v1.0.0
- Initial release
- Complete SAML SSO integration
- HTTP POST binding support
- Automatic certificate management
- Protocol mappers configuration
- Group management
- Test user creation
- Comprehensive verification
