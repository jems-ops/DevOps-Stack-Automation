# Generic Keycloak SAML Integration Role - Implementation Guide

## Overview

This document outlines the implementation of a **generic, reusable Ansible role** for integrating multiple applications (Jenkins, SonarQube, etc.) with Keycloak using SAML SSO.

## Design Goals

1. **DRY Principle**: Extract common Keycloak SAML configuration tasks
2. **Flexibility**: Support multiple applications with minimal code duplication
3. **Maintainability**: Single source of truth for SAML integration logic
4. **Extensibility**: Easy to add new applications

## Architecture

### Role Structure

```
roles/keycloak_saml_integration/
├── defaults/main.yml           # Generic variables with app-specific overrides
├── tasks/
│   ├── main.yml                # Task orchestration
│   ├── get_keycloak_token.yml  # ✅ COMMON: Get Keycloak admin token
│   ├── create_saml_client.yml  # ✅ COMMON: Create/update SAML client
│   ├── configure_protocol_mappers.yml  # ✅ COMMON: Setup attribute mappers
│   ├── configure_groups.yml    # ✅ COMMON: Create Keycloak groups
│   ├── create_test_user.yml    # ✅ COMMON: Create test user
│   ├── get_keycloak_certificate.yml  # ✅ COMMON: Get SAML certificate
│   └── configure_app_saml.yml  # 🔧 APP-SPECIFIC: Deploy app config
├── templates/
│   ├── jenkins-saml-config.xml.j2  # 🔧 Jenkins-specific template
│   └── sonar-saml-config.properties.j2  # 🔧 SonarQube-specific template
├── handlers/main.yml
├── meta/main.yml
└── README.md
```

### Variable Design

**Generic Variables** (works for all apps):
```yaml
keycloak_saml_integration_app_type: "jenkins"  # or "sonarqube"
keycloak_saml_integration_app_name: "{{ keycloak_saml_integration_app_type }}"
keycloak_saml_integration_groups:
  admins:
    name: "{{ keycloak_saml_integration_app_type }}-admins"
  users:
    name: "{{ keycloak_saml_integration_app_type }}-users"
```

**Application-Specific Configuration**:
```yaml
keycloak_saml_integration_app_config:
  jenkins:
    home: "/var/lib/jenkins"
    config_file: "config.xml"
    service_name: "jenkins"
    saml_callback_url: "/securityRealm/finishLogin"
  sonarqube:
    home: "/opt/sonarqube"
    config_file: "conf/sonar.properties"
    service_name: "sonarqube"
    saml_callback_url: "/oauth2/callback/saml"
```

## Common Tasks (Shared Logic)

### 1. Get Keycloak Token
- **File**: `tasks/get_keycloak_token.yml`
- **Purpose**: Authenticate to Keycloak Admin API
- **Common for**: All applications
- **Variables**: `keycloak_saml_integration_keycloak.*`

### 2. Create SAML Client
- **File**: `tasks/create_saml_client.yml`
- **Purpose**: Create/update SAML client in Keycloak
- **Common for**: All applications
- **Dynamic**: Uses `keycloak_saml_integration_app_type` to set client_id, redirect_uris

### 3. Configure Protocol Mappers
- **File**: `tasks/configure_protocol_mappers.yml`
- **Purpose**: Map SAML attributes (username, email, groups, etc.)
- **Common for**: All applications
- **Same mappers**: username, email, firstName, lastName, displayName, groups

### 4. Configure Groups
- **File**: `tasks/configure_groups.yml`
- **Purpose**: Create Keycloak groups
- **Common for**: All applications
- **Dynamic**: Group names prefixed with `app_type` (e.g., `jenkins-admins`)

### 5. Create Test User
- **File**: `tasks/create_test_user.yml`
- **Purpose**: Create test user with admin permissions
- **Common for**: All applications
- **Dynamic**: Username/password based on `app_type`

### 6. Get Keycloak Certificate
- **File**: `tasks/get_keycloak_certificate.yml`
- **Purpose**: Retrieve SAML certificate from Keycloak
- **Common for**: All applications
- **Output**: `saml_descriptor` fact

## Application-Specific Tasks

### Configure Application SAML
- **File**: `tasks/configure_app_saml.yml`
- **Purpose**: Deploy application-specific SAML configuration
- **Logic**:
  ```yaml
  - name: Configure SAML based on application type
    include_tasks: "configure_{{ keycloak_saml_integration_app_type }}_saml.yml"
  ```

### Jenkins-Specific (`configure_jenkins_saml.yml`)
1. Stop Jenkins service
2. Backup existing `config.xml`
3. Deploy `jenkins-saml-config.xml.j2` template
4. Restart Jenkins service

### SonarQube-Specific (`configure_sonarqube_saml.yml`)
1. Stop SonarQube service
2. Backup existing `sonar.properties`
3. Update properties with SAML configuration
4. Restart SonarQube service

## Templates

### Jenkins Template
**File**: `templates/jenkins-saml-config.xml.j2`

Key sections:
- `<authorizationStrategy>`: Permission matrix
- `<securityRealm>`: SAML configuration with IdP metadata
- Variables used: `keycloak_saml_integration_app.base_url`, `keycloak_saml_integration_app_saml.*`

### SonarQube Template
**File**: `templates/sonar-saml-config.properties.j2`

```properties
sonar.auth.saml.enabled=true
sonar.auth.saml.applicationId={{ keycloak_saml_integration_client.client_id }}
sonar.auth.saml.providerName=Keycloak
sonar.auth.saml.providerId={{ keycloak_saml_integration_keycloak.base_url }}/realms/{{ keycloak_saml_integration_keycloak.realm }}
sonar.auth.saml.loginUrl={{ keycloak_saml_integration_keycloak.base_url }}/realms/{{ keycloak_saml_integration_keycloak.realm }}/protocol/saml
sonar.auth.saml.certificate.secured={{ saml_certificate }}
sonar.auth.saml.user.login={{ keycloak_saml_integration_app_saml.username_attribute }}
sonar.auth.saml.user.name={{ keycloak_saml_integration_app_saml.full_name_attribute }}
sonar.auth.saml.user.email={{ keycloak_saml_integration_app_saml.email_attribute }}
sonar.auth.saml.group.name={{ keycloak_saml_integration_app_saml.groups_attribute }}
```

## Usage Examples

### Jenkins Integration
```yaml
---
- name: Jenkins SAML Integration
  hosts: jenkins
  become: true

  vars:
    keycloak_saml_integration_app_type: "jenkins"

  roles:
    - keycloak_saml_integration
```

### SonarQube Integration
```yaml
---
- name: SonarQube SAML Integration
  hosts: sonarqube
  become: true

  vars:
    keycloak_saml_integration_app_type: "sonarqube"

  roles:
    - keycloak_saml_integration
```

## Benefits

### Before (Separate Roles)
- ❌ `jenkins-keycloak-saml` role (889 lines)
- ❌ `sonarqube-keycloak-saml` role (800+ lines)
- ❌ ~80% code duplication
- ❌ Changes need to be made in multiple places
- ❌ Difficult to maintain consistency

### After (Generic Role)
- ✅ Single `keycloak_saml_integration` role (~500 lines)
- ✅ ~95% code reuse
- ✅ Changes in one place affect all applications
- ✅ Easy to add new applications
- ✅ Consistent SAML configuration across apps

## Adding New Applications

To support a new application (e.g., GitLab):

1. **Add app config** to `defaults/main.yml`:
   ```yaml
   gitlab:
     home: "/var/opt/gitlab"
     config_file: "config/gitlab.rb"
     service_name: "gitlab"
     saml_callback_url: "/users/auth/saml/callback"
   ```

2. **Create template**: `templates/gitlab-saml-config.rb.j2`

3. **Create task**: `tasks/configure_gitlab_saml.yml`

4. **Create playbook**: `playbooks/gitlab-saml.yml` with `keycloak_saml_integration_app_type: "gitlab"`

## Migration Path

### Phase 1: Create Generic Role ✅
- Define generic variables
- Extract common tasks
- Create README

### Phase 2: Implement Common Tasks
- Copy and genericize tasks from existing roles
- Test with Jenkins
- Test with SonarQube

### Phase 3: Create App-Specific Components
- Jenkins template and task
- SonarQube template and task

### Phase 4: Create New Playbooks
- `playbooks/jenkins-saml-generic.yml`
- `playbooks/sonarqube-saml-generic.yml`

### Phase 5: Testing & Validation
- Test Jenkins SAML integration
- Test SonarQube SAML integration
- Verify idempotency

### Phase 6: Documentation
- Update README with examples
- Document variable overrides
- Add troubleshooting guide

## Next Steps

1. Complete common task implementation
2. Create app-specific templates
3. Create main.yml task orchestration
4. Test with both applications
5. Update playbooks to use generic role
6. Deprecate old specific roles

## Conclusion

This generic role provides a **maintainable, scalable** approach to SAML integration with Keycloak, reducing code duplication by **~90%** and making it trivial to add support for new applications.
