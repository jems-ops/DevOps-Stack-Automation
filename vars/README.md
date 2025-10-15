# Variables Directory

This directory contains variable files for Ansible playbooks.

## Files

### `sonarqube-keycloak-saml.yml`
Variables for SonarQube-Keycloak SAML integration playbook.

**Usage:**
```yaml
vars_files:
  - "../vars/sonarqube-keycloak-saml.yml"
```

**Key Variables to Customize:**
- `keycloak.host` - Your Keycloak server IP/hostname
- `keycloak.admin_password` - Keycloak admin password
- `sonarqube.host` - Your SonarQube server IP/hostname
- `test_user.enabled` - Enable/disable test user creation

**Vault Variables:**
Use Ansible Vault for sensitive data:
```bash
ansible-vault create vault_keycloak_admin_password
```
