# Ansible Vault Usage Guide

This document provides comprehensive information on how to use Ansible Vault in the Jenkins Automation project to securely manage sensitive data.

## Overview

Ansible Vault is used to encrypt sensitive information such as:
- SSH passwords and credentials
- Database passwords
- SSL certificate configuration
- API keys and tokens
- Application passwords

## Vault Structure

```
group_vars/
├── all/
│   ├── main.yml     # Non-sensitive variables and vault references
│   └── vault.yml    # 🔒 Encrypted sensitive variables
└── .vault_pass      # 🔒 Vault password file (git-ignored)
```

## Encrypted Variables

The following sensitive variables are stored in the encrypted `vault.yml`:

### Authentication
- `vault_ansible_user` - SSH username
- `vault_ansible_password` - SSH password
- `vault_ansible_become_password` - sudo password

### Database Credentials
- `vault_postgresql_db_password` - PostgreSQL database password
- `vault_sonarqube_db_password` - SonarQube database password

### SSL Certificate Configuration
- `vault_ssl_organization` - Certificate organization name
- `vault_ssl_email` - Certificate email address
- `vault_ssl_country` - Certificate country code
- `vault_ssl_state` - Certificate state/province
- `vault_ssl_city` - Certificate city

### Application Passwords
- `vault_jenkins_admin_password` - Jenkins admin password
- `vault_sonarqube_admin_token` - SonarQube admin token

### API Keys
- `vault_github_api_token` - GitHub API token
- `vault_docker_registry_password` - Docker registry password

## Usage Methods

### 1. Command Line Tools

#### Using the Vault Manager Script
```bash
# View vault status
./scripts/vault-manager.sh status

# Edit vault file (opens in your default editor)
./scripts/vault-manager.sh edit

# View decrypted vault contents
./scripts/vault-manager.sh view

# Encrypt vault file
./scripts/vault-manager.sh encrypt

# Decrypt vault file (use with caution)
./scripts/vault-manager.sh decrypt

# Change vault password
./scripts/vault-manager.sh rekey
```

#### Using Makefile Targets
```bash
# Check vault status
make vault-status

# Edit vault file
make vault-edit

# View vault contents
make vault-view

# Encrypt vault file
make vault-encrypt

# Decrypt vault file
make vault-decrypt

# Change vault password
make vault-rekey
```

#### Direct Ansible Vault Commands
```bash
# Edit vault file
ansible-vault edit group_vars/all/vault.yml

# View vault file
ansible-vault view group_vars/all/vault.yml

# Encrypt existing file
ansible-vault encrypt group_vars/all/vault.yml

# Decrypt file
ansible-vault decrypt group_vars/all/vault.yml

# Change vault password
ansible-vault rekey group_vars/all/vault.yml
```

### 2. Using Variables in Playbooks

Variables are automatically available in playbooks:

```yaml
- name: Example task using vault variables
  user:
    name: "{{ vault_ansible_user }}"
    password: "{{ vault_ansible_password | password_hash('sha512') }}"
```

## Configuration Files

### ansible.cfg
Vault password file is automatically configured:
```ini
[defaults]
vault_password_file = .vault_pass
ask_vault_pass = False
```

### group_vars/all/main.yml
Non-sensitive variables that reference vault variables:
```yaml
# SSH and authentication (from vault)
ansible_user: "{{ vault_ansible_user }}"
ansible_password: "{{ vault_ansible_password }}"
ansible_become_password: "{{ vault_ansible_become_password }}"

# SSL Certificate configuration (from vault)
ssl_organization: "{{ vault_ssl_organization }}"
ssl_email: "{{ vault_ssl_email }}"
# ... etc
```

## Security Best Practices

### 1. Vault Password Management
- **Never commit `.vault_pass` to git** (already in .gitignore)
- Store the vault password securely (password manager, secure notes)
- Rotate vault passwords regularly
- Use strong, unique passwords for vault encryption

### 2. Variable Naming
- Prefix all vault variables with `vault_`
- Use descriptive names that indicate the purpose
- Group related variables together in the vault file

### 3. Access Control
- Limit access to vault password file (600 permissions)
- Only share vault passwords with authorized team members
- Consider using external secret management for production

### 4. Backup and Recovery
- Keep secure backups of the vault password
- Test vault decryption regularly
- Document vault recovery procedures

## Common Operations

### Adding New Sensitive Variables
1. Edit the vault file:
   ```bash
   make vault-edit
   ```
2. Add your new variable with `vault_` prefix
3. Reference it in `group_vars/all/main.yml`
4. Use in playbooks as needed

### Changing Passwords
1. Update the vault file:
   ```bash
   make vault-edit
   ```
2. Change the variable values
3. Save and test with your playbooks

### Rotating Vault Password
1. Change the vault password:
   ```bash
   make vault-rekey
   ```
2. Update `.vault_pass` file with new password:
   ```bash
   echo "your_new_password" > .vault_pass
   chmod 600 .vault_pass
   ```

## Testing Vault Configuration

### Basic Connectivity Test
```bash
ansible all -m ping
```

### Variable Resolution Test
```bash
ansible all -m debug -a "var=ansible_user"
```

### Playbook Syntax Check
```bash
make test-syntax
```

### Full Integration Test
```bash
# Run any playbook with --check flag
ansible-playbook playbooks/install-jenkins.yml --check
```

## Troubleshooting

### Common Issues

#### "Vault password file not found"
- Ensure `.vault_pass` exists and has correct permissions (600)
- Check `ansible.cfg` has correct path to vault password file

#### "Failed to decrypt vault"
- Verify vault password in `.vault_pass` is correct
- Check vault file wasn't corrupted
- Try viewing vault manually: `ansible-vault view group_vars/all/vault.yml`

#### Variables not resolving
- Ensure vault variables use `vault_` prefix
- Check `group_vars/all/main.yml` references vault variables correctly
- Test variable resolution: `ansible all -m debug -a "var=your_variable"`

#### Permission errors
- Check file permissions on `.vault_pass` (should be 600)
- Ensure vault file is readable by your user
- Verify SSH connectivity to target hosts

### Getting Help
```bash
# Show vault manager help
./scripts/vault-manager.sh help

# Show Makefile targets
make help

# Ansible vault help
ansible-vault --help
```

## Production Considerations

### External Secret Management
For production environments, consider:
- HashiCorp Vault integration
- AWS Secrets Manager
- Azure Key Vault
- CyberArk or other enterprise solutions

### CI/CD Integration
- Use CI/CD secret stores for vault passwords
- Never log vault passwords in CI/CD outputs
- Consider separate vault files per environment

### Monitoring and Auditing
- Log vault access and modifications
- Monitor for unauthorized vault access attempts
- Regular security reviews of vault contents

---

## Quick Reference

| Operation | Command |
|-----------|---------|
| View status | `make vault-status` |
| Edit vault | `make vault-edit` |
| View vault | `make vault-view` |
| Test connectivity | `ansible all -m ping` |
| Syntax check | `make test-syntax` |
| Help | `./scripts/vault-manager.sh help` |
