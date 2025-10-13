# Jenkins-Keycloak SAML Integration Role Usage Guide

This guide provides practical examples and usage instructions for the `jenkins-keycloak-saml` Ansible role.

## Quick Start

### 1. Prerequisites Checklist

Before running the role, ensure:

- [ ] Jenkins server is running and accessible
- [ ] Jenkins SAML plugin is installed (`org.jenkinsci.plugins.saml`)
- [ ] Keycloak server is running and accessible
- [ ] Target Keycloak realm exists (e.g., "jenkins")
- [ ] Keycloak admin credentials are available

### 2. Basic Usage

```yaml
---
- name: Configure Jenkins SAML SSO
  hosts: jenkins_servers
  become: yes
  vars:
    keycloak:
      host: "keycloak.example.com"
      admin_password: "{{ vault_keycloak_admin_password }}"
      realm: "jenkins"
    jenkins:
      base_url: "http://jenkins.example.com:8080"
  roles:
    - jenkins-keycloak-saml
```

### 3. Run the Playbook

```bash
# Basic execution
ansible-playbook -i inventory playbooks/configure-jenkins-keycloak-saml-role.yml

# With vault password
ansible-playbook -i inventory playbooks/configure-jenkins-keycloak-saml-role.yml --ask-vault-pass

# With specific tags
ansible-playbook -i inventory playbooks/configure-jenkins-keycloak-saml-role.yml --tags keycloak,jenkins
```

## Advanced Configuration Examples

### Production Environment Setup

```yaml
---
- name: Production Jenkins SAML Setup
  hosts: jenkins_prod
  become: yes
  vars:
    # Production Keycloak Configuration
    keycloak:
      protocol: "https"
      host: "sso.company.com"
      port: 443
      realm: "jenkins-prod"
      admin_user: "jenkins-admin"
      admin_password: "{{ vault_prod_keycloak_password }}"

      saml_client:
        client_id: "jenkins-production"
        attributes:
          saml_force_post_binding: "true"
          saml_server_signature: "true"
          saml_signature_algorithm: "RSA_SHA256"
          saml_assertion_signature: "true"
          saml_encrypt: "false"

    # Production Jenkins Configuration
    jenkins:
      base_url: "https://ci.company.com"
      home: "/opt/jenkins"
      saml:
        display_name: "Company SSO"
        sp_entity_id: "jenkins-production"
        force_authentication: true
        maximum_authentication_lifetime: 28800  # 8 hours

    # Custom Groups
    groups:
      jenkins_admins:
        name: "ci-administrators"
        description: "CI/CD Administrators"
      jenkins_users:
        name: "developers"
        description: "Development Team"

    # Disable test user in production
    test_user:
      enabled: false

  roles:
    - jenkins-keycloak-saml
```

### Development Environment with Test User

```yaml
---
- name: Development Jenkins SAML Setup
  hosts: jenkins_dev
  become: yes
  vars:
    keycloak:
      host: "keycloak-dev.local"
      admin_password: "dev-password"
      realm: "jenkins-dev"

    jenkins:
      base_url: "http://jenkins-dev.local:8080"

    # Enable test user for development
    test_user:
      enabled: true
      username: "dev-tester"
      email: "dev-tester@company.com"
      first_name: "Dev"
      last_name: "Tester"
      password: "DevTest123!"
      groups:
        - "jenkins-users"

    # Enable debug mode
    debug:
      enabled: true
      log_level: "debug"

  roles:
    - jenkins-keycloak-saml
```

## Configuration Variables Reference

### Essential Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `keycloak.host` | Keycloak server hostname | Yes | - |
| `keycloak.admin_password` | Keycloak admin password | Yes | - |
| `keycloak.realm` | Target Keycloak realm | Yes | "jenkins" |
| `jenkins.base_url` | Jenkins server URL | Yes | - |

### Optional Keycloak Variables

```yaml
keycloak:
  protocol: "http"                    # http or https
  port: 8080                          # Keycloak port
  admin_user: "admin"                 # Admin username

  saml_client:
    client_id: "jenkins-saml"         # SAML client identifier
    attributes:
      saml_force_post_binding: "true"
      saml_server_signature: "true"
      saml_signature_algorithm: "RSA_SHA256"
      saml_assertion_signature: "true"
      saml_encrypt: "false"
```

### Optional Jenkins Variables

```yaml
jenkins:
  home: "/var/lib/jenkins"            # Jenkins home directory
  user: "jenkins"                     # Jenkins system user
  group: "jenkins"                    # Jenkins system group

  saml:
    display_name: "Keycloak SAML"     # Display name on login page
    username_attribute: "username"    # SAML username attribute
    email_attribute: "email"          # SAML email attribute
    full_name_attribute: "displayName" # SAML full name attribute
    groups_attribute: "groups"        # SAML groups attribute
    sp_entity_id: "jenkins-saml"      # Service Provider entity ID
    force_authentication: false       # Force re-authentication
    maximum_authentication_lifetime: 7776000  # Session timeout (90 days)
```

## Common Usage Patterns

### 1. Testing and Validation

```bash
# Run only verification tasks
ansible-playbook playbook.yml --tags verify

# Run with debug enabled
ansible-playbook playbook.yml -e "debug.enabled=true"

# Test specific components
ansible-playbook playbook.yml --tags keycloak,client
ansible-playbook playbook.yml --tags jenkins,saml
```

### 2. Incremental Updates

```bash
# Update only protocol mappers
ansible-playbook playbook.yml --tags mappers

# Update only groups
ansible-playbook playbook.yml --tags groups

# Create/update test user
ansible-playbook playbook.yml --tags test_user
```

### 3. Troubleshooting

```bash
# Enable debug mode
ansible-playbook playbook.yml -e "debug.enabled=true" --tags debug

# Check configuration only
ansible-playbook playbook.yml --tags verify --check

# Skip Jenkins restart
ansible-playbook playbook.yml --skip-tags jenkins
```

## Integration with Existing Infrastructure

### Using with Ansible Vault

1. **Create vault file:**
```bash
ansible-vault create group_vars/all/vault.yml
```

2. **Add sensitive variables:**
```yaml
# group_vars/all/vault.yml
vault_keycloak_admin_password: "secure-password-here"
vault_jenkins_admin_password: "jenkins-admin-password"
vault_test_user_password: "test-user-password"
```

3. **Reference in playbook:**
```yaml
vars:
  keycloak:
    admin_password: "{{ vault_keycloak_admin_password }}"
  test_user:
    password: "{{ vault_test_user_password }}"
```

### Using with Dynamic Inventory

```yaml
# playbook with dynamic groups
- name: Configure Jenkins SAML SSO
  hosts: "{{ jenkins_environment | default('jenkins_servers') }}"
  vars:
    keycloak:
      host: "{{ hostvars[groups['keycloak'][0]]['ansible_fqdn'] }}"
      realm: "{{ jenkins_environment | default('jenkins') }}"
    jenkins:
      base_url: "http://{{ ansible_fqdn }}:8080"
```

### Integration with CI/CD Pipeline

```yaml
# Jenkins pipeline stage
stage('Configure SAML SSO') {
    steps {
        ansiblePlaybook(
            playbook: 'playbooks/configure-jenkins-keycloak-saml-role.yml',
            inventory: 'inventory/production.yml',
            vaultCredentialsId: 'ansible-vault-key',
            extraVars: [
                jenkins_environment: env.ENVIRONMENT,
                keycloak_realm: "jenkins-${env.ENVIRONMENT}"
            ]
        )
    }
}
```

## Post-Installation Configuration

### 1. Jenkins Authorization Strategy

After SAML is configured, update Jenkins authorization:

1. Go to **Manage Jenkins** → **Configure Global Security**
2. Under **Authorization**, select **Role-based Authorization Strategy** or **Matrix-based security**
3. Configure permissions based on SAML groups:
   - `jenkins-admins`: Full admin access
   - `jenkins-users`: Read and build permissions

### 2. Verify SAML Attributes

Check that user attributes are correctly mapped:

1. Login via SAML
2. Go to **People** → Select a user → **Configure**
3. Verify that email, full name, and groups are populated

### 3. Test Group Permissions

1. Create a test job
2. Configure project-based permissions
3. Assign permissions to SAML groups
4. Test access with different user accounts

## Troubleshooting Guide

### Common Issues

#### 1. SAML Plugin Not Found
**Symptoms**: No SAML login option on Jenkins
**Solution**: Install SAML plugin and restart Jenkins

#### 2. Certificate Validation Errors
**Symptoms**: SAML authentication fails
**Solution**: Check certificate extraction in debug mode

#### 3. Group Permissions Not Working
**Symptoms**: Users login but can't access resources
**Solution**: Verify group mapping and Jenkins authorization strategy

### Debug Commands

```bash
# Check Jenkins SAML configuration
curl -u admin:password http://jenkins:8080/configureSecurity/

# Verify Keycloak SAML metadata
curl http://keycloak:8080/realms/jenkins/protocol/saml/descriptor

# Test SAML redirect
curl -I http://jenkins:8080/securityRealm/commenceLogin?from=/
```

### Log File Locations

- **Jenkins logs**: `/var/log/jenkins/jenkins.log`
- **Keycloak logs**: `/opt/keycloak/data/log/keycloak.log`
- **System logs**: `journalctl -u jenkins -u keycloak`

## Best Practices

### Security
- Use HTTPS in production environments
- Implement proper certificate management
- Regular password rotation for service accounts
- Monitor authentication logs

### Performance
- Configure appropriate session timeouts
- Use connection pooling for database backends
- Monitor resource usage during peak authentication periods

### Maintenance
- Regular backup of Jenkins and Keycloak configurations
- Test SAML integration after updates
- Document any custom configurations
- Monitor certificate expiration dates

## Support and Troubleshooting

For additional support:

1. Check the role's README.md for detailed documentation
2. Review Ansible task logs for specific error messages
3. Consult Jenkins and Keycloak documentation for SAML configuration
4. Test individual components using role tags

Remember to always test SAML integration in a development environment before applying to production systems.
