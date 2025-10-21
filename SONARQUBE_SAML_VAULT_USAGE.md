# SonarQube-Keycloak SAML Integration with Ansible Vault

This guide shows how to run the SonarQube-Keycloak SAML integration playbook using Ansible Vault for secure password management.

## Current Vault Setup

The project uses Ansible Vault to securely store sensitive information:
- **Vault file**: `group_vars/all/vault.yml` (encrypted)
- **Password file**: `.vault_pass` (contains vault encryption password)
- **Configuration**: `ansible.cfg` is configured to use the vault password file automatically

## Vault Variables Used

The following vault variables are used in the SonarQube-Keycloak SAML integration:

```yaml
# In group_vars/all/vault.yml (encrypted)
vault_KEYCLOAK_ADMIN_USERNAME: "admin"
vault_KEYCLOAK_ADMIN_PASSWORD: "admin123"
```

## Running the Playbook

### Method 1: Using the Main Playbook (Recommended)

```bash
# Run the complete SonarQube-Keycloak SAML integration
ansible-playbook -i inventory playbooks/sonarqube-keycloak-saml.yml
```

### Method 2: Using the Override Playbook

```bash
# Run with custom overrides
ansible-playbook -i inventory playbooks/configure-sonarqube-keycloak-saml-role.yml
```

### Method 3: Manual Vault Password Entry (if .vault_pass is missing)

```bash
# If you need to enter vault password manually
ansible-playbook -i inventory playbooks/sonarqube-keycloak-saml.yml --ask-vault-pass
```

## Vault Management Commands

### View Vault Contents
```bash
ansible-vault view group_vars/all/vault.yml
```

### Edit Vault File
```bash
ansible-vault edit group_vars/all/vault.yml
```

### Change Vault Password
```bash
ansible-vault rekey group_vars/all/vault.yml
```

### Encrypt New File
```bash
ansible-vault encrypt new_vault_file.yml
```

### Decrypt File (temporarily)
```bash
ansible-vault decrypt group_vars/all/vault.yml
# Remember to encrypt again: ansible-vault encrypt group_vars/all/vault.yml
```

## Test User Credentials

**Note**: The demo test user password is NOT stored in vault (as requested):
- **Username**: `demo.user`
- **Password**: `demo123!`
- **Group**: `sonar-users`

## Playbook Configuration

The playbooks now use vault variables for secure password management:

### sonarqube-keycloak-saml.yml
```yaml
vars:
  keycloak:
    host: "keycloak.local"
    port: 443
    protocol: "https"
    base_url: "https://keycloak.local"
    realm: "sonar"
    admin_user: "{{ vault_KEYCLOAK_ADMIN_USERNAME }}"
    admin_password: "{{ vault_KEYCLOAK_ADMIN_PASSWORD }}"
```

## Security Benefits

✅ **Passwords encrypted at rest**
✅ **No plaintext passwords in version control**
✅ **Automatic vault password loading**
✅ **Secure credential management**

## Access Information

After successful deployment:

### SonarQube with SAML SSO:
- **Server 1**: http://192.168.201.11:9000
- **Server 2**: http://192.168.201.16:9000
- **Login Method**: "Log in with Keycloak SAML"

### Keycloak Admin Console:
- **URL**: https://keycloak.local/admin/master/console/
- **Credentials**: Uses vault variables (vault_KEYCLOAK_ADMIN_USERNAME/PASSWORD)

## Troubleshooting

### Vault Password Issues
```bash
# Check if vault password file exists and has correct permissions
ls -la .vault_pass

# Test vault decryption
ansible-vault view group_vars/all/vault.yml
```

### Playbook Execution Issues
```bash
# Run with verbose output for debugging
ansible-playbook -i inventory playbooks/sonarqube-keycloak-saml.yml -vv

# Check specific hosts
ansible-playbook -i inventory playbooks/sonarqube-keycloak-saml.yml --limit 192.168.201.11
```

### Variable Verification
```bash
# Check if vault variables are loaded correctly
ansible sonarqube -i inventory -m debug -a "var=vault_KEYCLOAK_ADMIN_USERNAME"
```

## Example Complete Run

```bash
# Navigate to project directory
cd /Users/jimi/jenkins-ansible-automation

# Verify vault access
ansible-vault view group_vars/all/vault.yml | grep KEYCLOAK

# Run the playbook
ansible-playbook -i inventory playbooks/sonarqube-keycloak-saml.yml

# Verify successful deployment
curl -I http://192.168.201.16:9000/sessions/init/saml
```

The playbook will automatically use the encrypted passwords from the vault file for secure Keycloak authentication.
