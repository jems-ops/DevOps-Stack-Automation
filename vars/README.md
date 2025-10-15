# Variables Directory

This directory is reserved for project-wide variable files when needed.

## Current Approach

**Role Defaults**: Variables are now defined in role `defaults/main.yml` files for:
- ✅ Better encapsulation
- ✅ Role reusability
- ✅ Clear variable precedence
- ✅ Easy overrides in playbooks

## Variable Override Examples

**In Playbooks:**
```yaml
vars:
  sonarqube:
    host: "192.168.201.11"  # Override auto-detection
  keycloak:
    host: "192.168.201.12"
    admin_password: "{{ vault_keycloak_admin_password }}"
```

**Using Ansible Vault:**
```bash
ansible-vault create group_vars/all/vault.yml
# Add: vault_keycloak_admin_password: "your-secure-password"
```
