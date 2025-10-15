# SonarQube-Keycloak SAML Integration Role

This Ansible role provides **fully automated** SAML SSO integration between SonarQube and Keycloak, including automatic certificate extraction and configuration.

## 🎯 Features

- ✅ **Complete SAML configuration** for SonarQube
- ✅ **Keycloak SAML client** creation and configuration
- ✅ **Automatic certificate extraction** from Keycloak
- ✅ **Protocol mappers** for user attributes (username, email, name, groups)
- ✅ **Group mapping** and user provisioning
- ✅ **HTTP POST binding** enforcement (critical for compatibility)
- ✅ **Optional test user** creation with passwords
- ✅ **Configuration verification** and health checks
- ✅ **Complete automation** - no manual steps required

## 🚀 Quick Start

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
          host: "192.168.1.100"
          port: 9000
        keycloak:
          host: "192.168.1.101"
          port: 8080
          realm: "sonar"
          admin_user: "admin"
          admin_password: "admin123"
        test_user:
          enabled: true
```

### Complete Example

```bash
# Run complete SAML integration
ansible-playbook -i inventory your-playbook.yml

# Run with verification only
ansible-playbook -i inventory your-playbook.yml --tags "verify"

# Run with debug logging
ansible-playbook -i inventory your-playbook.yml --extra-vars "debug_logging=true"
```

## 📋 Requirements

- Ansible >= 2.14
- SonarQube installed and running
- Keycloak installed and running
- Network connectivity between SonarQube and Keycloak
- Administrative access to both systems

## ⚙️ Role Variables

### SonarQube Configuration

```yaml
sonarqube:
  host: "192.168.201.16"          # SonarQube server IP/hostname
  port: 9000                      # SonarQube port
  protocol: "http"                # Protocol (http/https)
  config_path: "/opt/sonarqube/conf/sonar.properties"
  service_name: "sonarqube"       # Service name for systemctl
  base_url: "http://192.168.201.16:9000"  # Auto-computed if not provided
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
  base_url: "http://192.168.201.12:8080"  # Auto-computed if not provided
```

### SAML Configuration (Optional - Defaults Provided)

```yaml
sonarqube:
  saml:
    enabled: true
    force_authentication: false   # Set to true to disable local login
    user:
      login: "username"           # SAML attribute for username
      name: "name"               # SAML attribute for display name
      email: "email"             # SAML attribute for email
      sign_up_enabled: true      # Allow new user creation
      default_group: "sonar-users"  # Default group for new users
    group:
      name: "groups"             # SAML attribute for groups
```

### Test User Configuration

```yaml
test_user:
  enabled: true                   # Set to true to create test user
  username: "demo.user"
  password: "demo123!"
  email: "demo@example.com"
  first_name: "Demo"
  last_name: "User"
  groups:
    - "sonar-users"
```

## 🏷️ Available Tags

| Tag | Description |
|-----|-------------|
| `validate` | Validate required variables |
| `debug` | Enable debug logging |
| `sonarqube` | Configure SonarQube SAML settings |
| `keycloak` | Configure Keycloak SAML client |
| `saml` | All SAML-related tasks |
| `client` | Create Keycloak SAML client |
| `mappers` | Configure protocol mappers |
| `groups` | Configure groups |
| `certificate` | **Automatic certificate extraction & installation** |
| `test_user` | Create test user (if enabled) |
| `restart` | Restart services |
| `verify` | Verification and health checks |

## 🔧 Key Improvements

### Automatic Certificate Extraction

The role now **automatically extracts** the SAML signing certificate from Keycloak:

```yaml
# Certificate is automatically extracted from Keycloak SAML descriptor
# No manual certificate configuration required!
```

### File-Based Configuration

Uses SonarQube's properties file (like production systems) instead of API-only configuration:

```yaml
# Automatically adds to /opt/sonarqube/conf/sonar.properties:
sonar.auth.saml.enabled=true
sonar.auth.saml.certificate.secured=<auto-extracted-certificate>
# ... and all other SAML settings
```

### Complete Automation

**Zero manual intervention** required:

1. ✅ Extracts certificate from Keycloak
2. ✅ Creates SAML client with correct attributes
3. ✅ Configures all protocol mappers
4. ✅ Sets up groups and users
5. ✅ Verifies configuration works
6. ✅ Provides test credentials

## 📖 Usage Examples

### Production Deployment

```yaml
---
- name: Production SAML Setup
  hosts: sonarqube-prod
  become: true
  roles:
    - role: sonarqube-keycloak-saml
      vars:
        sonarqube:
          host: "sonar.company.com"
          port: 443
          protocol: "https"
        keycloak:
          host: "keycloak.company.com"
          port: 443
          protocol: "https"
          realm: "production"
          admin_user: "admin"
          admin_password: "{{ vault_keycloak_password }}"
        test_user:
          enabled: false  # Disable test user in production
```

### QA Environment with Testing

```yaml
---
- name: QA SAML Setup with Test User
  hosts: sonarqube-qa
  become: true
  roles:
    - role: sonarqube-keycloak-saml
      vars:
        sonarqube:
          host: "{{ ansible_default_ipv4.address }}"
        keycloak:
          host: "192.168.1.12"
          realm: "sonar-qa"
          admin_password: "{{ vault_keycloak_qa_password }}"
        test_user:
          enabled: true
          username: "qa.tester"
          password: "QAtest123!"
        debug_logging: true
```

### Verification Only

```bash
# Just verify existing SAML configuration
ansible-playbook -i inventory setup-saml.yml --tags "verify"
```

## ✅ Post-Installation

After running this role successfully:

1. **Access SonarQube**: Navigate to your SonarQube URL
2. **Test SSO**: Look for "Log in with Keycloak SAML" button
3. **Authenticate**: Use Keycloak credentials (or test user if created)
4. **Verify**: Confirm user is created and has appropriate permissions

## 🐛 Troubleshooting

### SAML Login Button Not Visible

1. **Clear browser cache** - SonarQube UI is cached
2. **Check configuration**: `grep -i saml /opt/sonarqube/conf/sonar.properties`
3. **Restart SonarQube**: `systemctl restart sonarqube`
4. **Test direct URL**: `http://your-sonarqube:9000/sessions/init/saml`

### Common Issues

| Issue | Solution |
|-------|----------|
| "SAML Response not found" | ✅ **Auto-fixed**: HTTP POST binding configured |
| "name is missing" | ✅ **Auto-fixed**: All protocol mappers created |
| Authorization Errors | ✅ **Auto-fixed**: sonar-users group created |
| Certificate Issues | ✅ **Auto-fixed**: Certificate auto-extracted |

### Debug Mode

```yaml
debug_logging: true
```

Enables:
- DEBUG logging in SonarQube
- Detailed configuration display
- All variable values during execution

### Manual Verification

```bash
# Check SAML settings
grep -i saml /opt/sonarqube/conf/sonar.properties

# Test SAML initiation - should return HTTP 302 with SAMLRequest
curl -I http://your-sonarqube:9000/sessions/init/saml

# Check SonarQube logs
tail -f /opt/sonarqube/logs/web.log
```

## 🔒 Security Considerations

- Use Ansible Vault for sensitive passwords
- Configure HTTPS in production environments
- Use strong passwords for test users
- Monitor authentication logs
- Regularly update certificates

## 📊 Version Compatibility

| Component | Tested Versions |
|-----------|-----------------|
| SonarQube | 9.x, 10.x |
| Keycloak | 20.x, 21.x, 22.x |
| Ansible | 2.14+, 2.15+ |

## 🎉 Complete Example Playbook

See `test-sonarqube-keycloak-saml-complete.yml` for a fully working example with:

- ✅ Pre-flight checks
- ✅ Complete variable configuration
- ✅ Post-installation verification
- ✅ Test user creation
- ✅ Detailed success reporting

## 📝 License

MIT

## 👥 Author

DevOps Team

## 🔄 Changelog

### v2.0.0 (Latest)
- ✅ **Automatic certificate extraction**
- ✅ **File-based configuration** (production-ready)
- ✅ **Complete automation** - zero manual steps
- ✅ **Enhanced verification** with direct SAML testing
- ✅ **Improved error handling** and troubleshooting
- ✅ **Test user management** with password setting
- ✅ **Production examples** and best practices

### v1.0.0
- Initial release
- Basic SAML SSO integration
- Manual certificate configuration required
