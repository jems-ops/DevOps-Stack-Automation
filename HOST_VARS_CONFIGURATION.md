## Host Variables Configuration Guide

This document explains how to use host_vars and group_vars to configure SonarQube-Keycloak SAML integration without hardcoded IP addresses.

---

## Directory Structure

```
jenkins-ansible-automation/
├── host_vars/
│   ├── 192.168.201.11.yml      # SonarQube server 1 configuration
│   └── 192.168.201.16.yml      # SonarQube server 2 configuration (if needed)
├── group_vars/
│   ├── sonarqube/
│   │   └── keycloak.yml        # Shared Keycloak configuration
│   └── all/
│       └── vault.yml           # Encrypted passwords
└── roles/sonarqube-keycloak-saml/
    └── defaults/main.yml       # Role defaults (generic, no hardcoded IPs)
```

---

## Configuration Levels

### 1. Role Defaults (Lowest Priority)
**File**: `roles/sonarqube-keycloak-saml/defaults/main.yml`

Contains generic defaults using dynamic variables:
```yaml
sonarqube_keycloak_saml_sonarqube:
  host: "{{ ansible_host | default(inventory_hostname) }}"
  port: 9000
  base_url: "http://{{ ansible_host | default(inventory_hostname) }}:9000"
```

**Purpose**: Provide fallback values that work for any host

### 2. Group Variables (Medium Priority)
**File**: `group_vars/sonarqube/keycloak.yml`

Shared configuration for all SonarQube servers:
```yaml
sonarqube_keycloak_saml_keycloak:
  host: "keycloak.local"
  port: 443
  protocol: "https"
  realm: "sonar"
  base_url: "https://keycloak.local"
```

**Purpose**: Configuration that's same across all SonarQube instances

### 3. Host Variables (Highest Priority)
**File**: `host_vars/192.168.201.11.yml`

Host-specific configuration:
```yaml
sonarqube_keycloak_saml_sonarqube:
  host: "{{ ansible_host }}"
  base_url: "http://{{ ansible_host }}:9000"

sonarqube_keycloak_saml_keycloak_saml_client:
  client_id: "sonarqube"
  redirect_uris:
    - "http://{{ ansible_host }}:9000/*"
```

**Purpose**: Per-host customization, especially for URLs and client configuration

---

## Variable Precedence

```
host_vars/ > group_vars/ > roles/defaults/
(highest)                   (lowest)
```

---

## Benefits of This Approach

### ✅ No Hardcoded IPs
```yaml
# ❌ OLD: Hardcoded in defaults
host: "192.168.201.11"

# ✅ NEW: Dynamic
host: "{{ ansible_host }}"
```

### ✅ Easy Multi-Host Support
Add new SonarQube servers by creating a new host_vars file:
```bash
cp host_vars/192.168.201.11.yml host_vars/192.168.201.16.yml
# Edit the new file if needed (usually not necessary with ansible_host)
```

### ✅ Environment-Specific Configuration
```
host_vars/
├── dev-sonar.example.com.yml    # Dev environment
├── qa-sonar.example.com.yml     # QA environment
└── prod-sonar.example.com.yml   # Production environment
```

### ✅ Shared Keycloak Configuration
Keycloak settings defined once in `group_vars/sonarqube/keycloak.yml`:
- All SonarQube servers use the same Keycloak instance
- Update in one place, applies to all

---

## Usage Examples

### Example 1: Adding a New SonarQube Server

1. **Update inventory**:
   ```ini
   [sonarqube]
   192.168.201.17
   ```

2. **Create host_vars file** (optional - defaults will work):
   ```bash
   cat > host_vars/192.168.201.17.yml <<EOF
   ---
   # Custom configuration for this host (if needed)
   sonarqube_keycloak_saml_sonarqube:
     host: "{{ ansible_host }}"
     base_url: "http://{{ ansible_host }}:9000"
   EOF
   ```

3. **Run playbook**:
   ```bash
   ansible-playbook -i inventory playbooks/sonarqube-keycloak-saml.yml --limit 192.168.201.17
   ```

### Example 2: Using Different Keycloak for QA

**File**: `group_vars/sonarqube_qa/keycloak.yml`
```yaml
sonarqube_keycloak_saml_keycloak:
  host: "keycloak-qa.local"
  base_url: "https://keycloak-qa.local"
  realm: "sonar-qa"
```

### Example 3: Custom Client ID Per Host

**File**: `host_vars/prod-sonar.example.com.yml`
```yaml
sonarqube_keycloak_saml_keycloak_saml_client:
  client_id: "sonarqube-prod"
  redirect_uris:
    - "https://{{ ansible_host }}/*"
```

---

## How Variables Are Resolved

### SonarQube Host
```yaml
# 1. Check host_vars/192.168.201.11.yml
sonarqube_keycloak_saml_sonarqube:
  host: "{{ ansible_host }}"  # ← Used if defined

# 2. Check group_vars/sonarqube/*.yml
# (not typically defined here)

# 3. Fallback to defaults/main.yml
sonarqube_keycloak_saml_sonarqube:
  host: "{{ ansible_host | default(inventory_hostname) }}"  # ← Used if not in host_vars
```

### Keycloak Configuration
```yaml
# 1. Check host_vars/ (for host-specific overrides)
# Usually not needed

# 2. Check group_vars/sonarqube/keycloak.yml
sonarqube_keycloak_saml_keycloak:
  host: "keycloak.local"  # ← Used (shared config)

# 3. Fallback to defaults/main.yml
# Only if not in group_vars
```

---

## Testing Your Configuration

### Check Variable Resolution
```bash
# See what values Ansible will use for a host
ansible 192.168.201.11 -i inventory -m debug \
  -a "var=sonarqube_keycloak_saml_sonarqube"

# Check Keycloak configuration
ansible 192.168.201.11 -i inventory -m debug \
  -a "var=sonarqube_keycloak_saml_keycloak"
```

### Verify Host Variables
```bash
# List all variables for a host
ansible-inventory -i inventory --host 192.168.201.11 --yaml
```

### Dry Run
```bash
# Test without making changes
ansible-playbook -i inventory playbooks/sonarqube-keycloak-saml.yml \
  --limit 192.168.201.11 --check
```

---

## Migration from Hardcoded Values

### Before (Hardcoded in defaults)
```yaml
# roles/sonarqube-keycloak-saml/defaults/main.yml
sonarqube_keycloak_saml_sonarqube:
  host: "192.168.201.11"  # ❌ Hardcoded
  base_url: "http://192.168.201.11:9000"  # ❌ Hardcoded
```

### After (Dynamic with host_vars)
```yaml
# roles/sonarqube-keycloak-saml/defaults/main.yml
sonarqube_keycloak_saml_sonarqube:
  host: "{{ ansible_host | default(inventory_hostname) }}"  # ✅ Dynamic
  base_url: "http://{{ ansible_host | default(inventory_hostname) }}:9000"  # ✅ Dynamic

# host_vars/192.168.201.11.yml
sonarqube_keycloak_saml_sonarqube:
  host: "{{ ansible_host }}"  # ✅ Uses inventory
```

---

## Best Practices

1. **Keep Keycloak Config in group_vars**
   - Shared across all SonarQube instances
   - Single point of configuration

2. **Use host_vars for Host-Specific Settings**
   - URLs with hostname/IP
   - Per-host client IDs (if needed)

3. **Use ansible_host for Dynamic IPs**
   ```yaml
   host: "{{ ansible_host }}"  # Gets IP from inventory
   ```

4. **Avoid Hardcoding in Defaults**
   - Defaults should be generic
   - Use Jinja2 templates for dynamic values

5. **Document Custom Variables**
   - Add comments in host_vars files
   - Explain why host-specific values are needed

6. **Version Control**
   - Commit host_vars/ and group_vars/
   - Exclude vault.yml (already encrypted)

---

## Troubleshooting

### Variables Not Being Used

**Problem**: Host variables not taking effect

**Solution**:
```bash
# Check variable precedence
ansible 192.168.201.11 -i inventory -m debug \
  -a "var=sonarqube_keycloak_saml_sonarqube" -vvv
```

### Wrong IP in Configuration

**Problem**: Still seeing hardcoded IP

**Solution**:
1. Check if host_vars file exists
2. Verify inventory has correct IP
3. Check `ansible_host` is set in inventory

### Keycloak Connection Fails

**Problem**: Can't connect to Keycloak

**Solution**:
```bash
# Verify Keycloak variables
ansible sonarqube -i inventory -m debug \
  -a "var=sonarqube_keycloak_saml_keycloak.base_url"
```

---

## References

- [Ansible Variables Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)
- [Variable Precedence](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)
- [Project Variable Naming Conventions](./VARIABLE_NAMING_CONVENTIONS.md)
