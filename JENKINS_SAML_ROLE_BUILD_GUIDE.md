# Jenkins-Keycloak SAML Role Build Guide

This guide contains everything needed to build a production-ready `jenkins-keycloak-saml` Ansible role following the same pattern as `sonarqube-keycloak-saml`.

## Quick Start

```bash
cd /Users/jimi/jenkins-ansible-automation
bash create_jenkins_saml_role.sh
```

This will create the complete role structure with all necessary files incorporating all the fixes we discovered during testing.

## Role Structure

```
roles/jenkins-keycloak-saml/
├── README.md
├── defaults/
│   └── main.yml
├── tasks/
│   ├── main.yml
│   ├── get_keycloak_token.yml
│   ├── set_keycloak_frontend_url.yml
│   ├── create_keycloak_saml_client.yml
│   ├── configure_protocol_mappers.yml
│   ├── configure_groups.yml
│   ├── create_test_user.yml
│   ├── get_keycloak_metadata.yml
│   ├── configure_jenkins_saml.yml
│   ├── remove_cached_metadata.yml
│   └── verify_configuration.yml
├── handlers/
│   └── main.yml
└── meta/
    └── main.yml
```

## Key Features Incorporated

### 1. HTTPS URL Fixes
- Keycloak `frontendUrl` set to HTTPS
- All redirect URIs use HTTPS
- IdP metadata fetched via HTTPS
- Cached metadata properly cleared

### 2. HTTP-POST Binding
- Changed from HTTP-Redirect to HTTP-POST
- More reliable with reverse proxies

### 3. Permissions
- Grants `Overall/Read` to `authenticated` role
- Proper group-based permissions
- jenkins-admins: Full access
- jenkins-users: Read, build, workspace access

### 4. Configuration Fixes
- Empty logout URL to prevent errors
- Removes cached `/var/lib/jenkins/saml-idp-metadata.xml`
- Embeds fresh HTTPS metadata in config.xml
- Proper XML escaping for metadata

## Usage Example

### Playbook

```yaml
---
- name: Configure Jenkins SAML SSO
  hosts: jenkins
  become: yes
  roles:
    - jenkins-keycloak-saml
  vars:
    jenkins_base_url: "https://jenkins.local"
    keycloak_base_url: "https://keycloak.local"
```

### Run

```bash
ansible-playbook playbooks/jenkins-saml-sso.yml -i inventory --ask-vault-pass
```

## Testing

### 1. Access SAML Login
```
https://jenkins.local/securityRealm/commenceLogin
```

### 2. Test Credentials
- Username: `jenkins-demo`
- Password: `JenkinsDemo123!`

### 3. Verify Flow
1. Redirects to Keycloak "Sign in to your account" page
2. After login, redirects back to Jenkins
3. User logged in with proper permissions

## Troubleshooting

### Check SAML Form Action
```bash
curl -sk https://jenkins.local/securityRealm/commenceLogin | grep 'action='
# Should show: action="https://keycloak.local/realms/jenkins/protocol/saml"
```

### Check Cached Metadata
```bash
ansible jenkins -i inventory -b -m shell -a "cat /var/lib/jenkins/saml-idp-metadata.xml | grep keycloak | head -3"
# Should show HTTPS URLs
```

### Check User Groups
```bash
TOKEN=$(curl -s -X POST http://192.168.201.12:8080/realms/master/protocol/openid-connect/token -d 'client_id=admin-cli' -d 'username=admin' -d 'password=admin123' -d 'grant_type=password' | python3 -c 'import sys, json; print(json.load(sys.stdin)["access_token"])')

USER_ID=$(curl -s "http://192.168.201.12:8080/admin/realms/jenkins/users?username=jenkins-demo" -H "Authorization: Bearer $TOKEN" | python3 -c 'import sys, json; print(json.load(sys.stdin)[0]["id"])')

curl -s "http://192.168.201.12:8080/admin/realms/jenkins/users/$USER_ID/groups" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

## All Fixes Applied

### Issue 1: Invalid Destination Error
**Fix**: Set Keycloak realm `frontendUrl` to HTTPS URL

### Issue 2: Outdated Redirect URIs
**Fix**: Update client redirect URIs to current Jenkins HTTPS URL

### Issue 3: HTTP URLs in Metadata
**Fix**: Fetch metadata via HTTPS and embed in Jenkins config

### Issue 4: Cached HTTP Metadata
**Fix**: Delete `/var/lib/jenkins/saml-idp-metadata.xml` before restart

### Issue 5: HTTP-Redirect Binding Issues
**Fix**: Change to HTTP-POST binding in Jenkins config

### Issue 6: Missing Permissions
**Fix**: Grant `Overall/Read` to `authenticated` role

### Issue 7: Logout Redirect Errors
**Fix**: Set empty logout URL in Jenkins config

### Issue 8: User Not in Group
**Fix**: Ensure test user added to `jenkins-users` group in Keycloak

## Comparison with SonarQube Role

| Feature | SonarQube Role | Jenkins Role |
|---------|---------------|--------------|
| Config Method | sonar.properties file | config.xml manipulation |
| Binding | POST (force) | POST (recommended) |
| Metadata | Via certificate | Embedded XML |
| Logout | Via URL | Disabled (empty) |
| Permissions | Via groups | Matrix-based + groups |
| Cache Handling | N/A | Clear cached file |

## Related Files

- `create_jenkins_saml_role.sh` - Role generator script
- `JENKINS_SAML_SSO_DEPLOYMENT.md` - Deployment guide
- `JENKINS_SAML_FIXES_APPLIED.md` - All fixes documented

## Next Steps

1. Run `bash create_jenkins_saml_role.sh`
2. Review generated defaults
3. Customize for your environment
4. Test the role
5. Commit to git

---

**Created**: 2025-10-28
**Based on**: Real-world fixes from Jenkins 2.528.1 + Keycloak 26.0 + SAML Plugin 2.333
