# Jenkins-Keycloak SAML Integration Role

This Ansible role configures SAML Single Sign-On (SSO) integration between Jenkins and Keycloak. It automates the complete setup process, including Keycloak SAML client configuration, Jenkins SAML plugin setup, protocol mappers, group management, and certificate handling.

## Features

- ✅ **Complete SAML Integration**: Full Jenkins-Keycloak SAML SSO setup
- 🔐 **Secure Configuration**: Proper certificate handling and security settings
- 👥 **Group Management**: Automatic creation and configuration of user groups
- 🗂️ **Protocol Mappers**: Comprehensive user attribute mapping
- 🧪 **Test User Support**: Optional test user creation for verification
- 🔍 **Verification**: Built-in configuration verification and testing
- 📋 **Debug Support**: Comprehensive logging and troubleshooting information

## Requirements

### System Requirements
- Ansible >= 2.9
- Python >= 3.6
- Jenkins server with SAML plugin installed
- Keycloak server (running and accessible)

### Jenkins Requirements
- Jenkins SAML plugin (org.jenkinsci.plugins.saml) must be installed
- Jenkins admin access for configuration updates
- Jenkins service must be manageable via systemd

### Keycloak Requirements
- Keycloak admin credentials
- Target realm must exist (role can create it if needed)
- Admin API access enabled

## Role Variables

### Required Variables

```yaml
# Keycloak Configuration
keycloak:
  host: "keycloak.example.com"
  admin_password: "{{ vault_keycloak_admin_password }}"
  realm: "jenkins"

# Jenkins Configuration
jenkins:
  base_url: "http://jenkins.example.com:8080"
```

### Optional Variables

#### Jenkins SAML Settings
```yaml
jenkins:
  saml:
    display_name: "Keycloak SAML"
    username_attribute: "username"
    email_attribute: "email"
    full_name_attribute: "displayName"
    groups_attribute: "groups"
    sp_entity_id: "jenkins-saml"
    force_authentication: false
    maximum_authentication_lifetime: 7776000  # 90 days
```

#### Keycloak SAML Client Settings
```yaml
keycloak:
  saml_client:
    client_id: "jenkins-saml"
    attributes:
      saml_force_post_binding: "true"
      saml_server_signature: "true"
      saml_signature_algorithm: "RSA_SHA256"
      saml_assertion_signature: "true"
```

#### Group Configuration
```yaml
groups:
  jenkins_admins:
    name: "jenkins-admins"
    description: "Jenkins Administrators"
  jenkins_users:
    name: "jenkins-users"
    description: "Jenkins Users"
```

#### Test User (Optional)
```yaml
test_user:
  enabled: true
  username: "jenkins-demo"
  email: "jenkins-demo@example.com"
  first_name: "Jenkins"
  last_name: "Demo"
  password: "JenkinsDemo123!"
  groups:
    - "jenkins-users"
```

## Dependencies

This role has no external role dependencies but requires:
- `ansible.builtin` collection
- Jenkins SAML plugin pre-installed
- Running Keycloak instance

## Example Playbook

### Basic Usage
```yaml
---
- name: Configure Jenkins-Keycloak SAML Integration
  hosts: jenkins_servers
  become: yes
  vars:
    keycloak:
      host: "keycloak.example.com"
      admin_password: "{{ vault_keycloak_admin_password }}"
      realm: "jenkins"
    jenkins:
      base_url: "http://{{ ansible_fqdn }}:8080"
  roles:
    - jenkins-keycloak-saml
```

### Advanced Configuration
```yaml
---
- name: Configure Jenkins-Keycloak SAML Integration with Test User
  hosts: jenkins_servers
  become: yes
  vars:
    keycloak:
      host: "keycloak.internal.com"
      port: 8080
      admin_user: "admin"
      admin_password: "{{ vault_keycloak_admin_password }}"
      realm: "jenkins-prod"

    jenkins:
      base_url: "https://jenkins.company.com"
      saml:
        display_name: "Company SSO"
        sp_entity_id: "jenkins-production"
        force_authentication: true

    test_user:
      enabled: true
      username: "test-jenkins"
      password: "{{ vault_test_user_password }}"
      groups:
        - "jenkins-users"

    debug:
      enabled: true

  roles:
    - jenkins-keycloak-saml
```

## Task Tags

You can run specific parts of the role using tags:

```bash
# Only configure Keycloak components
ansible-playbook playbook.yml --tags keycloak

# Only configure Jenkins SAML
ansible-playbook playbook.yml --tags jenkins,saml

# Only create test user
ansible-playbook playbook.yml --tags test_user

# Enable debug output
ansible-playbook playbook.yml --tags debug

# Run verification only
ansible-playbook playbook.yml --tags verify
```

Available tags:
- `keycloak` - All Keycloak-related tasks
- `jenkins` - All Jenkins-related tasks
- `saml` - SAML-specific configuration
- `client` - SAML client creation
- `mappers` - Protocol mapper configuration
- `groups` - Group management
- `test_user` - Test user creation
- `certificate` - Certificate handling
- `debug` - Debug information
- `verify` - Configuration verification

## Protocol Mappers

The role automatically configures these SAML protocol mappers:

| Mapper | Type | SAML Attribute | User Property |
|--------|------|----------------|---------------|
| username | User Property | username | username |
| email | User Property | email | email |
| firstName | User Property | firstName | firstName |
| lastName | User Property | lastName | lastName |
| displayName | JavaScript | displayName | firstName + lastName |
| groups | Group Membership | groups | User groups |

## Security Considerations

### Certificate Management
- The role automatically retrieves Keycloak's SAML signing certificate
- Certificates are validated before use
- Consider implementing certificate rotation procedures

### Authentication Settings
- SAML assertions are signed by default
- POST binding is enforced for security
- Authentication lifetime is configurable (default: 90 days)

### Group Mapping
- Users are automatically assigned to groups based on Keycloak group membership
- Jenkins permissions should be configured to use SAML groups
- Consider implementing group-based authorization strategies

## Troubleshooting

### Common Issues

#### 1. SAML Plugin Not Found
**Error**: SAML login option not available
**Solution**: Ensure Jenkins SAML plugin is installed:
```bash
# Install via Jenkins CLI or web interface
java -jar jenkins-cli.jar -s http://jenkins:8080 install-plugin saml
```

#### 2. Certificate Issues
**Error**: SAML authentication fails with certificate errors
**Solution**: Verify certificate extraction:
```yaml
debug:
  enabled: true
```

#### 3. Group Mapping Not Working
**Error**: Users login but have no permissions
**Solution**:
- Verify protocol mappers are configured
- Check Jenkins authorization strategy
- Ensure users are in correct Keycloak groups

#### 4. Jenkins Configuration Reset
**Error**: Configuration changes don't persist
**Solution**:
- Check Jenkins file permissions
- Verify systemd service restart
- Review Jenkins logs: `/var/log/jenkins/jenkins.log`

### Debug Mode

Enable debug mode for detailed troubleshooting:
```yaml
debug:
  enabled: true
  log_level: "debug"
```

### Log Files

Check these log files for issues:
- Jenkins: `/var/log/jenkins/jenkins.log`
- Keycloak: `/opt/keycloak/data/log/keycloak.log`
- System: `journalctl -u jenkins -u keycloak`

## Testing

### Verification Steps

1. **Basic Connectivity**
   ```bash
   # Check Jenkins accessibility
   curl -I http://jenkins:8080/login

   # Check Keycloak SAML metadata
   curl http://keycloak:8080/realms/jenkins/protocol/saml/descriptor
   ```

2. **SAML Configuration**
   - Visit Jenkins login page
   - Verify SAML login option is present
   - Click SAML login and verify redirect to Keycloak

3. **User Authentication**
   - Login with test user credentials
   - Verify user details are correctly mapped
   - Check group membership in Jenkins

### Integration Testing

```yaml
# Enable test user for integration testing
test_user:
  enabled: true
  username: "integration-test"
  password: "TestPass123!"
  groups:
    - "jenkins-users"
```

## Performance Considerations

- **Jenkins Restart**: Role restarts Jenkins service during configuration
- **Certificate Caching**: SAML metadata is cached by Jenkins (configurable)
- **Group Synchronization**: Groups are synchronized on each login
- **Session Timeout**: Configure appropriate session timeouts

## Maintenance

### Regular Tasks
- Monitor certificate expiration dates
- Review and rotate test user credentials
- Update group memberships as needed
- Monitor authentication logs

### Backup Recommendations
- Backup Jenkins configuration before running role
- Store Keycloak realm configuration
- Document custom protocol mappers

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Update documentation
5. Submit a pull request

## License

This role is released under the MIT License. See LICENSE file for details.

## Author Information

Created and maintained by the Jenkins DevOps Team.

For issues and feature requests, please use the project's issue tracker.
