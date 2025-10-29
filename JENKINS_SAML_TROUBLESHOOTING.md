# Jenkins SAML Troubleshooting Guide

## Issue: Jenkins SAML Login Not Displaying Button or Errors

### Current Status
✅ Jenkins is running  
✅ SAML plugin is installed and configured  
✅ Keycloak realm and client are configured  
⚠️ SAML attribute mapping issue detected

---

## Problem Identified

**Error in Jenkins logs:**
```
SEVERE o.j.p.saml.SamlSecurityRealm#getUsernameFromProfile: Unable to get username from attribute username value []
SEVERE o.j.p.saml.SamlSecurityRealm#getUsernameFromProfile: Falling back to NameId jenkins-demo
WARNING o.j.p.saml.SamlSecurityRealm#modifyUserEmail: There is not Email attribute 'email' for user : jenkins-demo
```

**Root Cause:**  
The SAML assertion from Keycloak is not including the `username` attribute in the expected format. Jenkins falls back to using the NameID, which works, but causes warnings.

---

## Solution Options

### Option 1: Use NameID Only (Recommended for Quick Fix)

Remove the `usernameAttributeName` from Jenkins config or leave it empty to make Jenkins use the SAML NameID directly.

**Edit the template:**
```yaml
# In roles/keycloak-saml-integration/templates/jenkins-saml-config.xml.j2
# Line 74: Change from:
<usernameAttributeName>{{ keycloak_saml_app_saml.username_attribute }}</usernameAttributeName>

# To (empty):
<usernameAttributeName></usernameAttributeName>
```

### Option 2: Fix Keycloak Protocol Mapper

Ensure the username mapper in Keycloak is configured correctly:

1. Go to Keycloak Admin Console
2. Navigate to: **Realms** → **jenkins** → **Clients** → **jenkins-saml** → **Client scopes** → **Mappers**
3. Find the "username" mapper
4. Verify configuration:
   - **Mapper Type:** User Property
   - **Property:** username
   - **Friendly Name:** username
   - **SAML Attribute Name:** username
   - **SAML Attribute NameFormat:** Basic

### Option 3: Use Alternative Attribute

Change Jenkins to use a different attribute that Keycloak is providing:

```yaml
# In defaults/main.yml, change:
username_attribute: "username"
# To:
username_attribute: ""  # Empty - use NameID
# Or use:
username_attribute: "preferred_username"  # Keycloak's standard attribute
```

---

## Verification Steps

### 1. Check Current SAML Configuration
```bash
ansible jenkins_servers -i inventory -m shell \
  -a "grep -A 5 'usernameAttributeName' /var/lib/jenkins/config.xml" --become
```

### 2. Check Jenkins Logs for SAML Activity
```bash
ansible jenkins_servers -i inventory -m shell \
  -a "journalctl -u jenkins -n 100 --no-pager | grep -i saml" --become
```

### 3. Test SAML Login
Navigate to: **https://jenkins.local/securityRealm/commenceLogin**

Expected flow:
1. Redirects to Keycloak login page
2. Enter credentials: `jenkins-demo / JenkinsDemo123!`
3. Redirects back to Jenkins
4. User logged in successfully

---

## Additional Checks

### Verify Keycloak Client Configuration

```bash
# Get Keycloak admin token
KEYCLOAK_TOKEN=$(curl -k -X POST "https://keycloak.local/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=admin123" \
  -d "grant_type=password" | jq -r '.access_token')

# Get protocol mappers for jenkins-saml client
curl -k -X GET "https://keycloak.local/admin/realms/jenkins/clients/CLIENTID/protocol-mappers/models" \
  -H "Authorization: Bearer $KEYCLOAK_TOKEN" | jq '.'
```

### Test SAML Metadata Accessibility

```bash
# Keycloak IdP metadata
curl -k https://keycloak.local/realms/jenkins/protocol/saml/descriptor

# Jenkins SP metadata (if generated)
curl -k https://jenkins.local/securityRealm/metadata
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| No SAML button on login page | This is expected - use direct URL: `/securityRealm/commenceLogin` |
| "Unable to get username" error | Use empty `usernameAttributeName` or fix Keycloak mapper |
| "No Email attribute" warning | Add email mapper in Keycloak or ignore (non-critical) |
| Infinite redirect loop | Check `sp_entity_id` matches between Jenkins and Keycloak |
| Clock skew errors | Sync time on Jenkins and Keycloak servers |
| Certificate errors | Disable cert validation or add CA cert to Jenkins truststore |

---

## Jenkins SAML Plugin Configuration Reference

**Minimum Required Configuration:**
```xml
<securityRealm class="org.jenkinsci.plugins.saml.SamlSecurityRealm">
  <idpMetadataConfiguration>
    <url>https://keycloak.local/realms/jenkins/protocol/saml/descriptor</url>
    <period>1440</period>
  </idpMetadataConfiguration>
  <displayNameAttributeName>displayName</displayNameAttributeName>
  <groupsAttributeName>groups</groupsAttributeName>
  <usernameAttributeName></usernameAttributeName>  <!-- Empty = use NameID -->
  <emailAttributeName>email</emailAttributeName>
  <maximumAuthenticationLifetime>7776000</maximumAuthenticationLifetime>
  <spEntityId>jenkins-saml</spEntityId>
</securityRealm>
```

---

## Next Steps

1. **Apply Quick Fix:** Update template to use empty `usernameAttributeName`
2. **Redeploy:** Run `ansible-playbook playbooks/configure-jenkins-saml.yml`
3. **Test Login:** Use `/securityRealm/commenceLogin` URL
4. **Verify Groups:** Check that `jenkins-admins` group provides admin access
5. **Document:** Add login URL to Jenkins or create redirect

---

## Useful Commands

```bash
# Restart Jenkins
ansible jenkins_servers -i inventory -m systemd \
  -a "name=jenkins state=restarted" --become

# Watch Jenkins logs in real-time
ansible jenkins_servers -i inventory -m shell \
  -a "journalctl -u jenkins -f" --become

# Check Jenkins SAML plugin version
ansible jenkins_servers -i inventory -m shell \
  -a "ls -la /var/lib/jenkins/plugins/ | grep saml" --become
```

---

## References

- [Jenkins SAML Plugin Documentation](https://plugins.jenkins.io/saml/)
- [Keycloak SAML Client Configuration](https://www.keycloak.org/docs/latest/server_admin/#saml-clients)
- [SAML 2.0 Protocol Specification](http://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)
