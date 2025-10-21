# Variable Naming Conventions

This document outlines the variable naming conventions used in this Ansible project to ensure consistency and prevent variable name collisions across roles.

## Role Variable Naming

All variables defined in a role's `defaults/main.yml` or `vars/main.yml` should be prefixed with the role name to avoid namespace collisions.

### Naming Pattern

```
<role_name>_<variable_name>
```

Where:
- `<role_name>`: The role name with hyphens replaced by underscores
- `<variable_name>`: A descriptive variable name using snake_case

### Examples

#### sonarqube-keycloak-saml Role

**Correct:**
```yaml
sonarqube_keycloak_saml_sonarqube:
  host: "192.168.201.11"
  port: 9000

sonarqube_keycloak_saml_keycloak:
  host: "keycloak.local"
  port: 443

sonarqube_keycloak_saml_test_user:
  enabled: true
  username: "demo.user"

sonarqube_keycloak_saml_debug_logging: false
```

**Incorrect:**
```yaml
# ❌ No role prefix - can cause conflicts
sonarqube:
  host: "192.168.201.11"

keycloak:
  host: "keycloak.local"

test_user:
  enabled: true

debug_logging: false
```

#### jenkins-keycloak-saml Role

**Correct:**
```yaml
jenkins_keycloak_saml_jenkins:
  host: "192.168.201.10"

jenkins_keycloak_saml_keycloak:
  host: "keycloak.local"

jenkins_keycloak_saml_test_user:
  enabled: true
```

## Backward Compatibility

To maintain backward compatibility with existing playbooks, you can create alias variables:

```yaml
# New prefixed variables (primary)
sonarqube_keycloak_saml_sonarqube:
  host: "192.168.201.11"
  port: 9000

# Backward compatibility alias (deprecated)
sonarqube: "{{ sonarqube_keycloak_saml_sonarqube }}"
```

Add a deprecation notice in your role's README:

```markdown
## Deprecated Variables

The following variables are deprecated and will be removed in version 2.0.0:
- `sonarqube` → use `sonarqube_keycloak_saml_sonarqube`
- `keycloak` → use `sonarqube_keycloak_saml_keycloak`
- `test_user` → use `sonarqube_keycloak_saml_test_user`
- `debug_logging` → use `sonarqube_keycloak_saml_debug_logging`
```

## Benefits

### 1. Prevents Naming Conflicts

```yaml
# Without prefixes - both roles define 'keycloak' variable
# Role A
keycloak:
  host: "keycloak-a.local"

# Role B - overwrites Role A's variable!
keycloak:
  host: "keycloak-b.local"

# With prefixes - no conflicts
# Role A
roleA_keycloak:
  host: "keycloak-a.local"

# Role B - separate namespace
roleB_keycloak:
  host: "keycloak-b.local"
```

### 2. Improves Readability

When reading playbooks or debugging, prefixed variables make it clear which role a variable belongs to:

```yaml
# Clear which role these variables belong to
- debug:
    msg: "SonarQube host: {{ sonarqube_keycloak_saml_sonarqube.host }}"
    msg: "Jenkins host: {{ jenkins_keycloak_saml_jenkins.host }}"
```

### 3. Easier Maintenance

- Easier to search for role-specific variables
- Reduces debugging time when variables conflict
- Makes refactoring safer

## Ansible Lint Integration

This project uses `ansible-lint` to enforce variable naming conventions.

### Running Ansible Lint

```bash
# Lint all files
ansible-lint

# Lint specific role
ansible-lint roles/sonarqube-keycloak-saml/

# Lint specific playbook
ansible-lint playbooks/sonarqube-keycloak-saml.yml

# Auto-fix issues where possible
ansible-lint --fix
```

### Pre-commit Hook

The project uses pre-commit hooks to automatically lint Ansible files:

```bash
# Install pre-commit hooks
pre-commit install

# Run manually
pre-commit run --all-files

# Run only ansible-lint
pre-commit run ansible-lint --all-files
```

## Configuration Files

### .ansible-lint

The `.ansible-lint` file in the project root configures linting rules:

```yaml
profile: production

enable_list:
  - var-naming[no-role-prefix]

rules:
  var-naming:
    enforce: true
```

### .pre-commit-config.yaml

Pre-commit is configured to run ansible-lint automatically:

```yaml
- repo: https://github.com/ansible/ansible-lint
  rev: v6.22.1
  hooks:
    - id: ansible-lint
```

## Migration Guide

### Updating an Existing Role

1. **Identify all role variables** in `defaults/main.yml` and `vars/main.yml`

2. **Add prefixed versions:**
   ```yaml
   # Old (keep for compatibility)
   variable_name: value

   # New (primary)
   role_name_variable_name: value
   ```

3. **Create compatibility aliases:**
   ```yaml
   # Backward compatibility (deprecated)
   variable_name: "{{ role_name_variable_name }}"
   ```

4. **Update role tasks** to use prefixed variables

5. **Add deprecation notice** to README

6. **Update playbooks** gradually to use new variable names

7. **Remove aliases** in next major version

### Example Migration

**Before:**
```yaml
# defaults/main.yml
keycloak:
  host: "keycloak.local"
```

**After:**
```yaml
# defaults/main.yml
# New prefixed variable
sonarqube_keycloak_saml_keycloak:
  host: "keycloak.local"

# Backward compatibility (deprecated - will be removed in v2.0.0)
keycloak: "{{ sonarqube_keycloak_saml_keycloak }}"
```

## Best Practices

1. **Always use role prefixes** for new variables
2. **Use snake_case** for variable names
3. **Keep prefixes consistent** with role name
4. **Document deprecated variables** in README
5. **Run ansible-lint** before committing
6. **Update playbooks** to use new variable names
7. **Plan removal** of deprecated aliases in advance

## References

- [Ansible Best Practices - Variable Naming](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#variables-and-vaults)
- [Ansible Lint - var-naming rule](https://ansible-lint.readthedocs.io/rules/var-naming/)
- [Galaxy Role Requirements - Naming](https://galaxy.ansible.com/docs/contributing/creating_role.html#role-names)
