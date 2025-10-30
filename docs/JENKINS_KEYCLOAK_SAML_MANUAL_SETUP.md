# Jenkins Keycloak SAML SSO - Manual Setup Guide

**Version:** 1.0  
**Last Updated:** October 30, 2025  
**Automated Role:** `keycloak-saml-integration`

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Step-by-Step Manual Setup](#step-by-step-manual-setup)
5. [Automated Setup](#automated-setup)
6. [Troubleshooting](#troubleshooting)
7. [Testing](#testing)

---

## Overview

This guide provides step-by-step instructions for configuring Jenkins to use Keycloak as a SAML 2.0 Single Sign-On (SSO) provider. This allows users to authenticate to Jenkins using their Keycloak credentials.

### What You'll Configure

- **Keycloak:** Create realm, SAML client, protocol mappers, groups, and test user
- **Jenkins:** Install SAML plugin and configure security realm
- **SAML Flow:** Enable secure authentication between Jenkins and Keycloak

### Time Estimate

- **Manual Setup:** ~30-45 minutes
- **Automated Setup:** ~5 minutes (using our Ansible role)

---

## Prerequisites

### Required Software

- **Jenkins:** Version 2.332.1 or higher
- **Keycloak:** Version 22.0 or higher
- **Jenkins SAML Plugin:** Version 2.333 or higher

### Access Requirements

- Keycloak admin credentials
- Jenkins admin access
- Network connectivity between Jenkins and Keycloak

### DNS/Network Setup

```
Jenkins:   https://jenkins.local (or your domain)
Keycloak:  https://keycloak.local (or your domain)
```

---

## Architecture

```
┌─────────────────┐          SAML Request          ┌──────────────────┐
│                 │ ──────────────────────────────> │                  │
│     Jenkins     │                                 │     Keycloak     │
│  (Service       │ <────────────────────────────── │   (Identity      │
│   Provider)     │          SAML Response          │    Provider)     │
└─────────────────┘                                 └──────────────────┘
        │                                                    │
        │                                                    │
        └────────────────────────────────────────────────────┘
                        Authenticated User
```

**Flow:**
1. User accesses Jenkins → Redirected to Keycloak
2. User logs in to Keycloak
3. Keycloak sends SAML assertion to Jenkins
4. Jenkins validates assertion and creates session

---

## Step-by-Step Manual Setup

### Phase 1: Install Jenkins SAML Plugin

#### Option A: Via Jenkins UI

1. Navigate to **Jenkins → Manage Jenkins → Manage Plugins**
2. Go to **Available** tab
3. Search for "SAML"
4. Select **SAML Plugin**
5. Click **Install without restart**
6. Wait for installation to complete

#### Option B: Via Command Line

```bash
# Download plugin
cd /var/lib/jenkins/plugins/
curl -LO https://updates.jenkins.io/download/plugins/saml/2.333.vc81e525974a_c/saml.hpi

# Set permissions
chown jenkins:jenkins saml.hpi

# Restart Jenkins
systemctl restart jenkins
```

**Reference:** See `roles/keycloak-saml-integration/tasks/configure_jenkins_saml.yml`

---

### Phase 2: Configure Keycloak

#### Step 1: Create Realm

1. Login to Keycloak Admin Console: `https://keycloak.local`
2. Click dropdown at top-left (says "master")
3. Click **Create Realm**
4. Enter realm name: `jenkins`
5. Click **Create**

**Automated equivalent:**
```yaml
# See: roles/keycloak-saml-integration/tasks/create_keycloak_realm.yml
POST /admin/realms
{
  "realm": "jenkins",
  "enabled": true,
  "displayName": "Jenkins Realm"
}
```

---

#### Step 2: Create SAML Client

1. In `jenkins` realm, click **Clients** (left menu)
2. Click **Create client**
3. Configure:
   - **Client type:** SAML
   - **Client ID:** `jenkins-saml`
   - Click **Next**

4. **Capability config:**
   - **Client authentication:** OFF
   - **Authorization:** OFF
   - Click **Next**

5. **Login settings:**
   - **Root URL:** `https://jenkins.local`
   - **Valid redirect URIs:** 
     ```
     https://jenkins.local/securityRealm/finishLogin
     https://jenkins.local/*
     ```
   - **Base URL:** `https://jenkins.local`
   - Click **Save**

6. **Advanced Settings** (in client settings):
   - **Assertion Consumer Service POST Binding URL:** `https://jenkins.local/securityRealm/finishLogin`
   - **Logout Service POST Binding URL:** `https://jenkins.local/logout`
   - **Name ID Format:** `username`
   - **Force POST Binding:** ON
   - **Front Channel Logout:** ON
   - Click **Save**

**Automated equivalent:**
```yaml
# See: roles/keycloak-saml-integration/tasks/create_saml_client.yml
```

---

#### Step 3: Configure Protocol Mappers

In the `jenkins-saml` client, go to **Client scopes** → **jenkins-saml-dedicated** → **Mappers** tab:

##### Mapper 1: Username
1. Click **Add mapper** → **By configuration** → **User Property**
2. Configure:
   - **Name:** username
   - **Property:** username
   - **SAML Attribute Name:** username
   - **SAML Attribute NameFormat:** Basic
3. Click **Save**

##### Mapper 2: Email
1. Click **Add mapper** → **By configuration** → **User Property**
2. Configure:
   - **Name:** email
   - **Property:** email
   - **SAML Attribute Name:** email
   - **SAML Attribute NameFormat:** Basic
3. Click **Save**

##### Mapper 3: Display Name
1. Click **Add mapper** → **By configuration** → **User Property**
2. Configure:
   - **Name:** displayName
   - **Property:** username
   - **SAML Attribute Name:** displayName
   - **SAML Attribute NameFormat:** Basic
3. Click **Save**

##### Mapper 4: First Name
1. Click **Add mapper** → **By configuration** → **User Property**
2. Configure:
   - **Name:** firstName
   - **Property:** firstName
   - **SAML Attribute Name:** firstName
   - **SAML Attribute NameFormat:** Basic
3. Click **Save**

##### Mapper 5: Last Name
1. Click **Add mapper** → **By configuration** → **User Property**
2. Configure:
   - **Name:** lastName
   - **Property:** lastName
   - **SAML Attribute Name:** lastName
   - **SAML Attribute NameFormat:** Basic
3. Click **Save**

##### Mapper 6: Groups
1. Click **Add mapper** → **By configuration** → **Group list**
2. Configure:
   - **Name:** groups
   - **Group attribute name:** groups
   - **SAML Attribute NameFormat:** Basic
   - **Single Group Attribute:** OFF
   - **Full group path:** OFF
3. Click **Save**

**Automated equivalent:**
```yaml
# See: roles/keycloak-saml-integration/tasks/configure_protocol_mappers.yml
# See: roles/keycloak-saml-integration/defaults/main.yml (keycloak_saml_protocol_mappers)
```

---

#### Step 4: Create Groups

1. In `jenkins` realm, click **Groups** (left menu)
2. Click **Create group**

##### Admin Group
- **Name:** `jenkins-admins`
- **Description:** Jenkins Administrators
- Click **Create**

##### Users Group
- **Name:** `jenkins-users`
- **Description:** Jenkins Users
- Click **Create**

**Automated equivalent:**
```yaml
# See: roles/keycloak-saml-integration/tasks/configure_groups.yml
```

---

#### Step 5: Create Test User

1. Click **Users** (left menu)
2. Click **Add user**
3. Configure:
   - **Username:** `jenkins-demo`
   - **Email:** `jenkins-demo@example.com`
   - **First name:** Jenkins
   - **Last name:** Demo
   - **Email verified:** ON
   - Click **Create**

4. **Set Password:**
   - Go to **Credentials** tab
   - Click **Set password**
   - **Password:** `JenkinsDemo123!`
   - **Temporary:** OFF
   - Click **Save**

5. **Add to Groups:**
   - Go to **Groups** tab
   - Click **Join Group**
   - Select `jenkins-admins` and `jenkins-users`
   - Click **Join**

**Automated equivalent:**
```yaml
# See: roles/keycloak-saml-integration/tasks/create_test_user.yml
```

---

#### Step 6: Get IdP Metadata

1. Get SAML descriptor URL:
   ```
   https://keycloak.local/realms/jenkins/protocol/saml/descriptor
   ```

2. **Save this URL** - you'll need it for Jenkins configuration

**Automated equivalent:**
```yaml
# See: roles/keycloak-saml-integration/tasks/get_keycloak_certificate.yml
```

---

### Phase 3: Configure Jenkins

#### Step 1: Backup Current Configuration

```bash
# Backup Jenkins config
cp /var/lib/jenkins/config.xml /var/lib/jenkins/config.xml.backup.$(date +%s)
```

---

#### Step 2: Configure SAML Security Realm

1. Navigate to **Jenkins → Manage Jenkins → Configure Global Security**

2. **Security Realm:** Select **SAML 2.0**

3. **IdP Metadata Configuration:**
   - **Option:** URL from IdP
   - **URL:** `https://keycloak.local/realms/jenkins/protocol/saml/descriptor`
   - **Period:** 1440 (refresh every 24 hours)

4. **Display Name Attribute:** `displayName`

5. **Group Attribute:** `groups`

6. **Username Attribute:** *Leave empty* (uses NameID)
   
   ⚠️ **Important:** Leave this empty to avoid "Unable to get username" errors

7. **Email Attribute:** `email`

8. **Username Case Conversion:** none

9. **Data Binding Method:** HTTP-POST

10. **Logout URL:** Leave empty

11. **Maximum Authentication Lifetime:** `7776000` (90 days)

12. **Advanced Configuration:**
    - **SP Entity ID:** `jenkins-saml`
    - **Force Authentication:** Unchecked
    - **Authentication Context Class:** Leave empty
    - **Sign Authentication Requests:** Unchecked
    - **Want Assertions Signed:** Unchecked

---

#### Step 3: Configure Authorization Strategy

**Option A: Simple (Recommended for testing)**

Select **Logged-in users can do anything**
- ✅ Easy to test
- ❌ No role-based access control

**Option B: Role-Based (Production)**

Select **Project-based Matrix Authorization Strategy**

Add permissions for groups:
```
jenkins-admins:
  - Overall: Administer, Read
  - Job: All permissions
  - View: All permissions
  - Run: All permissions

jenkins-users:
  - Overall: Read
  - Job: Build, Cancel, Read, Workspace
  - View: Read
```

---

#### Step 4: Save and Test

1. Click **Save** (bottom of page)
2. **Don't log out yet!**
3. Open a new private/incognito browser window
4. Navigate to: `https://jenkins.local/securityRealm/commenceLogin`
5. You should be redirected to Keycloak login

---

### Phase 4: Verification

#### Test SAML Login

1. Access: `https://jenkins.local/securityRealm/commenceLogin`
2. Login with test user:
   - Username: `jenkins-demo`
   - Password: `JenkinsDemo123!`
3. Should redirect back to Jenkins and be logged in

#### Verify User Info

1. Click your username (top-right)
2. Check:
   - Username shows correctly
   - Email is populated
   - Groups are assigned

#### Check Logs

```bash
# Check Jenkins logs for SAML activity
journalctl -u jenkins -n 50 | grep -i saml

# Should NOT see these errors:
# ❌ "Unable to get username from attribute username value []"
# ❌ "Falling back to NameId"

# Should see:
# ✅ SAML configuration initialized
# ✅ SP metadata written
```

---

## Automated Setup

Instead of manual setup, use our Ansible role:

### Quick Deploy

```bash
# Deploy Jenkins SAML integration
ansible-playbook playbooks/configure-jenkins-saml.yml -i inventory --ask-vault-pass
```

### What It Does

The automated role performs all the steps above:

1. ✅ Validates prerequisites
2. ✅ Checks service status (Jenkins, Keycloak)
3. ✅ Creates Keycloak realm (if not exists)
4. ✅ Configures SAML client with all settings
5. ✅ Creates protocol mappers (6 mappers)
6. ✅ Creates groups (admins, users)
7. ✅ Creates test user with credentials
8. ✅ Gets IdP certificate
9. ✅ Backs up Jenkins config
10. ✅ Generates and applies SAML config
11. ✅ Restarts Jenkins
12. ✅ Waits for Jenkins to be ready

### Role Structure

```
roles/keycloak-saml-integration/
├── defaults/main.yml              # Default variables
├── tasks/
│   ├── main.yml                   # Orchestration
│   ├── preflight_checks.yml       # Service validation
│   ├── create_keycloak_realm.yml  # Realm creation
│   ├── create_saml_client.yml     # Client config
│   ├── configure_protocol_mappers.yml
│   ├── configure_groups.yml       # Group creation
│   ├── create_test_user.yml       # Test user
│   ├── get_keycloak_certificate.yml
│   └── configure_jenkins_saml.yml # Jenkins config
├── templates/
│   └── jenkins-saml-config.xml.j2 # Config template
└── handlers/main.yml              # Service handlers
```

### Configuration Files

**Variables:** `group_vars/all/saml_integration.yml`
```yaml
jenkins_hostname: "{{ groups['jenkins_servers'][0] }}"
jenkins_base_url: "https://{{ jenkins_hostname }}"
keycloak_hostname: "{{ groups['keycloak'][0] }}"
keycloak_base_url: "https://{{ keycloak_hostname }}"
keycloak_saml_use_https: true
```

**Playbook:** `playbooks/configure-jenkins-saml.yml`
```yaml
- name: Configure Jenkins SAML Integration with Keycloak
  hosts: jenkins_servers
  become: yes
  
  vars:
    keycloak_saml_app_type: "jenkins"
  
  roles:
    - keycloak-saml-integration
```

---

## Troubleshooting

### Issue: No SAML Login Button

**Symptom:** Jenkins login page doesn't show SAML/SSO button

**Solution:** This is expected behavior with Jenkins SAML plugin. Users must access:
```
https://jenkins.local/securityRealm/commenceLogin
```

**Workaround Options:**
1. Bookmark the SAML URL
2. Create nginx redirect (see below)
3. Add a link on Jenkins login page

**Nginx Redirect:**
```nginx
# In /etc/nginx/conf.d/jenkins.conf
location = /login {
    return 302 https://jenkins.local/securityRealm/commenceLogin;
}
```

---

### Issue: "Unable to get username from attribute" Error

**Symptom:** Jenkins logs show:
```
SEVERE: Unable to get username from attribute username value []
SEVERE: Falling back to NameId jenkins-demo
```

**Solution:** Leave the "Username Attribute" field **empty** in Jenkins SAML config

**Why:** Keycloak may not send the username attribute in the expected format. Using empty value makes Jenkins use the SAML NameID directly.

**Fix Applied:** Our Ansible template already has this fix (line 74):
```xml
<usernameAttributeName></usernameAttributeName>
```

---

### Issue: Redirect Loop

**Symptom:** Infinite redirects between Jenkins and Keycloak

**Cause:** SP Entity ID mismatch

**Solution:** Ensure `SP Entity ID` in Jenkins matches `Client ID` in Keycloak:
- Jenkins: `jenkins-saml`
- Keycloak: `jenkins-saml`

---

### Issue: "Realm not found"

**Symptom:** 404 error when accessing Keycloak

**Solution:** Verify realm name is exactly `jenkins` (case-sensitive)

Check:
```bash
curl -k https://keycloak.local/realms/jenkins/protocol/saml/descriptor
```

---

### Issue: Certificate Validation Error

**Symptom:** SSL/TLS certificate errors

**Solution:** 
- **Production:** Use valid SSL certificates
- **Development:** Disable cert validation in Jenkins SAML plugin settings

---

### Issue: User Has No Permissions

**Symptom:** User logs in but sees "Access Denied"

**Solution:**
1. Check user is in correct groups (jenkins-admins)
2. Verify Authorization Strategy allows group permissions
3. Check groups attribute is being sent in SAML assertion

**Debug:**
```bash
# Check SAML assertion in Jenkins logs
journalctl -u jenkins | grep -A 20 "SAML response"
```

---

## Testing

### Test Checklist

- [ ] SAML endpoint accessible: `https://jenkins.local/securityRealm/commenceLogin`
- [ ] Redirects to Keycloak login page
- [ ] Can login with test user (jenkins-demo)
- [ ] Redirects back to Jenkins after login
- [ ] User is authenticated in Jenkins
- [ ] Username displays correctly
- [ ] Email is populated
- [ ] Groups are assigned (jenkins-admins, jenkins-users)
- [ ] Has admin permissions (if in jenkins-admins)
- [ ] Can logout successfully
- [ ] No errors in Jenkins logs

### Manual Test Commands

```bash
# Check Jenkins is running
systemctl status jenkins

# Check Keycloak is accessible
curl -k -I https://keycloak.local/realms/master

# Check SAML descriptor
curl -k https://keycloak.local/realms/jenkins/protocol/saml/descriptor

# Check Jenkins SAML endpoint
curl -k -I https://jenkins.local/securityRealm/commenceLogin

# Check Jenkins logs
journalctl -u jenkins -n 50 | grep -i saml
```

---

## Additional Resources

### Documentation

- **Jenkins SAML Plugin:** https://plugins.jenkins.io/saml/
- **Keycloak SAML Clients:** https://www.keycloak.org/docs/latest/server_admin/#saml-clients
- **SAML 2.0 Spec:** http://docs.oasis-open.org/security/saml/

### Our Resources

- **Automated Role:** `roles/keycloak-saml-integration/`
- **Playbook:** `playbooks/configure-jenkins-saml.yml`
- **Troubleshooting Guide:** `JENKINS_SAML_TROUBLESHOOTING.md`
- **Deployment Summary:** `DEPLOYMENT_SUMMARY.md`

### Test Credentials

```
Username: jenkins-demo
Password: JenkinsDemo123!
Groups:   jenkins-admins, jenkins-users
```

---

## Summary

**Manual Setup Time:** ~30-45 minutes  
**Automated Setup Time:** ~5 minutes  

**Manual Steps:** 20+ steps across Keycloak and Jenkins  
**Automated Steps:** 1 command

**Recommendation:** Use the automated Ansible role for consistency, repeatability, and reduced errors.

---

**Document Version:** 1.0  
**Last Updated:** October 30, 2025  
**Maintained By:** DevOps Automation Team
