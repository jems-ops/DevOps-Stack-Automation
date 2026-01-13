# Nessus Ansible Role

This role installs and configures Tenable Nessus vulnerability scanner on Rocky Linux 9.

## Requirements

- Rocky Linux 9
- Internet connectivity to download Nessus RPM
- Nessus activation code (for licensed version)

## Role Variables

### Required Variables (from vault)
```yaml
vault_nessus_admin_username: "admin"
vault_nessus_admin_password: "SecurePassword123!"
vault_nessus_admin_email: "admin@example.com"
vault_nessus_activation_code: "XXXX-XXXX-XXXX-XXXX"  # Optional for Essentials
```

### Optional Variables
```yaml
nessus_version: "10.7.1"
nessus_port: 8834
nessus_hostname: "nessus.local"
nessus_base_url: "https://nessus.local"
nessus_configure_firewall: true
```

## Dependencies

None

## Example Playbook

```yaml
---
- name: Install Nessus
  hosts: nessus_servers
  become: yes
  roles:
    - nessus
```

## Usage

1. **Install Nessus:**
   ```bash
   ansible-playbook playbooks/install-nessus.yml -i inventory --ask-vault-pass
   ```

2. **Access Nessus:**
   - URL: https://nessus.local:8834
   - Complete initial setup wizard
   - Create admin user
   - Enter activation code
   - Wait for plugin compilation (30-60 minutes)

3. **Configure SAML Integration:**
   After Nessus is installed and initialized, configure SAML with Keycloak:
   ```bash
   ansible-playbook playbooks/configure-keycloak-saml-integration.yml -i inventory -e "app=nessus" --ask-vault-pass
   ```

## Post-Installation

1. **Configure nginx reverse proxy:**
   - Add nessus.local to DNS
   - Configure SSL certificates
   - Set up nginx proxy to port 8834

2. **Complete Nessus Setup:**
   - Access https://nessus.local:8834
   - Follow setup wizard
   - Configure admin user
   - Enter activation code
   - Wait for plugins to compile

3. **Configure SAML:**
   - Use Keycloak SAML integration playbook
   - Configure SAML settings in Nessus
   - Test SSO login

## License

MIT

## Author

DevOps Team
