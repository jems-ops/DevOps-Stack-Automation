# Jenkins Keycloak SAML SSO - Manual Configuration Guide

This guide provides step-by-step instructions for manually configuring SAML Single Sign-On (SSO) between Jenkins and Keycloak, based on our Ansible automation role.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Part 1: Keycloak Configuration](#part-1-keycloak-configuration)
- [Part 2: Jenkins Configuration](#part-2-jenkins-configuration)
- [Part 3: Testing and Verification](#part-3-testing-and-verification)
- [Part 4: User and Group Management](#part-4-user-and-group-management)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

---

## Prerequisites

Before starting, ensure you have:

- ✅ Jenkins installed and accessible (e.g., `https://jenkins.local`)
- ✅ Keycloak installed and accessible (e.g., `https://keycloak.local`)
- ✅ Admin access to both Jenkins and Keycloak
- ✅ SAML plugin installed in Jenkins (version `4.429.v9a_781a_61f1da_` or later)
- ✅ Jenkins initial admin password

### Required Information

| Item | Value | Notes |
|------|-------|-------|
| Jenkins URL | `https://jenkins.local` | Your Jenkins base URL |
| Keycloak URL | `https://keycloak.local` | Your Keycloak base URL |
| Keycloak Realm | `master` | Realm where client will be created |
| Keycloak Admin User | `admin` | Keycloak admin username |
| Keycloak Admin Password | From vault | Keycloak admin password |

---

## Architecture Overview

```
┌─────────────┐          SAML          ┌──────────────┐
│             │◄─────Authentication────►│              │
│   Jenkins   │                         │   Keycloak   │
│  (Service   │    IdP Metadata         │     (IdP)    │
│  Provider)  │◄────────────────────────│              │
│             │                         │              │
└─────────────┘                         └──────────────┘
```

**Flow:**
1. User accesses Jenkins
2. Jenkins redirects to Keycloak for authentication
3. User logs in with Keycloak credentials
4. Keycloak returns SAML assertion to Jenkins
5. Jenkins creates/updates user session with group mappings

---

## Part 1: Keycloak Configuration

### Step 1.1: Access Keycloak Admin Console

1. Open browser and navigate to: `https://keycloak.local/admin`
2. Login with admin credentials
3. Select the **master** realm from the dropdown (or your desired realm)

### Step 1.2: Create SAML Client for Jenkins

1. In the left sidebar, click **Clients**
2. Click **Create client** button
3. Fill in the **General Settings**:
   - **Client type**: `SAML`
   - **Client ID**: `jenkins`
   - Click **Next**

4. Configure **Capability config**:
   - **Client signature required**: `Off`
   - **Force POST binding**: `On`
   - **Front channel logout**: `On`
   - **Force name ID format**: `Off`
   - **Name ID format**: `username`
   - **Include AuthnStatement**: `On`
   - **Sign documents**: `Off`
   - **Sign assertions**: `Off`
   - **Signature algorithm**: `RSA_SHA256`
   - **SAML signature key name**: `CERT_SUBJECT`
   - **Canonicalization method**: `EXCLUSIVE`
   - Click **Next**

5. Configure **Login settings**:
   - **Root URL**: `https://jenkins.local`
   - **Home URL**: `https://jenkins.local`
   - **Valid redirect URIs**:
     ```
     https://jenkins.local/*
     https://jenkins.local/securityRealm/finishLogin
     ```
   - **Valid post logout redirect URIs**: `https://jenkins.local/*`
   - **IDP Initiated SSO URL name**: `jenkins`
   - **IDP Initiated SSO relay state**: (leave empty)
   - **Master SAML Processing URL**: `https://jenkins.local/securityRealm/finishLogin`
   - **Assertion Consumer Service POST Binding URL**: `https://jenkins.local/securityRealm/finishLogin`
   - Click **Save**

### Step 1.3: Configure Client Scopes and Mappers

1. Go to **Clients** → **jenkins** → **Client scopes** tab
2. Click on **jenkins-dedicated** scope
3. Click **Add mapper** → **By configuration**

#### Mapper 1: Username

- Click **User Property**
- **Name**: `username`
- **Property**: `username`
- **Friendly Name**: `Username`
- **SAML Attribute Name**: `username`
- **SAML Attribute NameFormat**: `Basic`
- Click **Save**

#### Mapper 2: Email

- Click **Add mapper** → **By configuration** → **User Property**
- **Name**: `email`
- **Property**: `email`
- **Friendly Name**: `Email`
- **SAML Attribute Name**: `email`
- **SAML Attribute NameFormat**: `Basic`
- Click **Save**

#### Mapper 3: Full Name

- Click **Add mapper** → **By configuration** → **User Property**
- **Name**: `fullName`
- **Property**: `username`
- **Friendly Name**: `Full Name`
- **SAML Attribute Name**: `fullName`
- **SAML Attribute NameFormat**: `Basic`
- Click **Save**

#### Mapper 4: Groups

- Click **Add mapper** → **By configuration** → **Group list**
- **Name**: `groups`
- **Group attribute name**: `groups`
- **Friendly Name**: `Groups`
- **SAML Attribute NameFormat**: `Basic`
- **Single Group Attribute**: `On`
- **Full group path**: `Off`
- Click **Save**

### Step 1.4: Create Groups

1. In the left sidebar, click **Groups**
2. Click **Create group**
3. Create parent group:
   - **Name**: `devops`
   - Click **Create**

4. Select the `devops` group, then click **Create group**
5. Create admin group:
   - **Name**: `jenkins-admins`
   - Click **Create**

6. Create the `devops` group again, then click **Create group**
7. Create user group:
   - **Name**: `jenkins-users`
   - Click **Create**

**Group Hierarchy:**
```
devops/
├── jenkins-admins
└── jenkins-users
```

### Step 1.5: Create Roles (Optional but Recommended)

1. Go to **Clients** → **jenkins** → **Roles** tab
2. Click **Create role**
3. Create admin role:
   - **Role name**: `admin`
   - **Description**: `Jenkins Administrator`
   - Click **Save**

4. Click **Create role** again
5. Create user role:
   - **Role name**: `user`
   - **Description**: `Jenkins User`
   - Click **Save**

### Step 1.6: Download SAML Descriptor (IdP Metadata)

1. Go to **Realm settings** in the left sidebar
2. Click on **SAML 2.0 Identity Provider Metadata** endpoint or navigate to:
   ```
   https://keycloak.local/realms/master/protocol/saml/descriptor
   ```
3. Save the entire XML content - you'll need this for Jenkins configuration

**Example URL structure:**
```
https://keycloak.local/realms/master/protocol/saml/descriptor
```

The XML should start with:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" ...>
```

---

## Part 2: Jenkins Configuration

### Step 2.1: Install SAML Plugin (if not already installed)

1. Log into Jenkins with initial admin password
2. Complete the initial setup wizard
3. Go to **Manage Jenkins** → **Plugins**
4. Click **Available plugins**
5. Search for `SAML` or `SAML Plugin`
6. Install **SAML Plugin** (version 4.429.v9a_781a_61f1da_ or later)
7. Restart Jenkins when prompted

### Step 2.2: Configure SAML Security Realm

#### Method 1: Via Jenkins UI (Recommended for Testing)

1. Go to **Manage Jenkins** → **Security**
2. Under **Security Realm**, select **SAML 2.0**
3. Configure the following settings:

**IdP Metadata:**
- Paste the entire XML content from Keycloak's SAML descriptor (Step 1.6)
- Or use the URL: `https://keycloak.local/realms/master/protocol/saml/descriptor`
- **Metadata refresh period**: `1440` (minutes)

**Display Name Attribute Name:**
```
fullName
```

**Groups Attribute Name:**
```
groups
```

**Maximum Authentication Lifetime:**
```
86400
```

**Username Attribute Name:**
- Leave empty (uses NameID from SAML assertion)

**Email Attribute Name:**
```
email
```

**Login Button Text:**
```
Login with SAML SSO
```

**User Name Case Conversion:**
- Select: `none`

**Data Binding Method:**
- Select: `HTTP POST`

**Force Authentication:**
- Check this box: `☑`

**SP Entity ID:**
```
jenkins
```

**Advanced Configuration:**
- **Force Authentication**: `true`
- **Authn Requests Signed**: `false`
- **Want Assertions Signed**: `false`
- **Signature Algorithm**: `RSA_SHA256`

4. Click **Save**

#### Method 2: Via Configuration File (For Automation)

1. Stop Jenkins service:
   ```bash
   sudo systemctl stop jenkins
   ```

2. Backup existing configuration:
   ```bash
   sudo cp /var/lib/jenkins/config.xml /var/lib/jenkins/config.xml.backup
   ```

3. Edit `/var/lib/jenkins/config.xml` and replace the `<securityRealm>` section with:

```xml
<securityRealm class="org.jenkinsci.plugins.saml.SamlSecurityRealm" plugin="saml@4.429.v9a_781a_61f1da_">
  <idpMetadataConfiguration>
    <xml>&lt;?xml version="1.0" encoding="UTF-8"?&gt;
&lt;EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" ...&gt;
  ... (paste your escaped Keycloak metadata here) ...
&lt;/EntityDescriptor&gt;</xml>
    <period>1440</period>
  </idpMetadataConfiguration>
  <displayNameAttributeName>fullName</displayNameAttributeName>
  <groupsAttributeName>groups</groupsAttributeName>
  <loginButtonText>Login with SAML SSO</loginButtonText>
  <maximumAuthenticationLifetime>86400</maximumAuthenticationLifetime>
  <usernameAttributeName></usernameAttributeName>
  <emailAttributeName>email</emailAttributeName>
  <logoutUrl></logoutUrl>
  <usernameCaseConversion>none</usernameCaseConversion>
  <encryptionData/>
  <authnContextClassRef/>
  <maximumSessionLifetime>86400</maximumSessionLifetime>
  <dataBindingMethod>HTTP_POST</dataBindingMethod>
  <forceAuthn>true</forceAuthn>
  <spEntityId>jenkins</spEntityId>
  <advancedConfiguration>
    <forceAuthn>true</forceAuthn>
    <spEntityId>jenkins</spEntityId>
    <authnRequestsSigned>false</authnRequestsSigned>
    <wantAssertionsSigned>false</wantAssertionsSigned>
    <signatureAlgorithm>RSA_SHA256</signatureAlgorithm>
  </advancedConfiguration>
</securityRealm>
```

**Note:** The XML content must be escaped:
- Replace `<` with `&lt;`
- Replace `>` with `&gt;`
- Replace `&` with `&amp;`

4. Set proper ownership:
   ```bash
   sudo chown jenkins:jenkins /var/lib/jenkins/config.xml
   sudo chmod 644 /var/lib/jenkins/config.xml
   ```

5. Start Jenkins:
   ```bash
   sudo systemctl start jenkins
   ```

### Step 2.3: Configure Authorization Strategy

1. Go to **Manage Jenkins** → **Security**
2. Under **Authorization**, select **Matrix-based security** or **Role-Based Strategy**

**For Matrix-based security:**

Add permissions for Keycloak groups:
- Group name: `jenkins-admins`
  - ☑ Administer
  - ☑ Read
  - ☑ All other permissions

- Group name: `jenkins-users`
  - ☑ Read
  - ☑ Build
  - ☑ Cancel

3. **Important:** Add yourself as admin before testing SSO!
   - Add your Keycloak username with full admin rights
   - This prevents lockout

4. Click **Save**

### Step 2.4: Configure Single Logout (Optional)

To enable Single Logout (SLO) so that logging out of Jenkins also logs you out of Keycloak:

#### In Keycloak:

1. Go to **Clients** → **jenkins** → **Settings** tab
2. Scroll to **Logout settings**:
   - **Valid post logout redirect URIs**: `https://jenkins.local/*`
   - **Logout Service POST Binding URL**: `https://jenkins.local/securityRealm/finishLogin`
   - **Logout Service Redirect Binding URL**: `https://jenkins.local/securityRealm/finishLogin`
3. Ensure **Front Channel Logout**: `On`
4. Click **Save**

#### In Jenkins:

1. Go to **Manage Jenkins** → **Security** → **Configure Global Security**
2. In the **SAML 2.0** security realm settings:
   - **IdP Single Logout URL**: `https://keycloak.local/realms/master/protocol/saml`
   - **Logout URL** (or **Single Logout Service URL**): Leave as `https://jenkins.local/securityRealm/finishLogin` (automatically set)
3. Enable: **Single Logout** (if available as checkbox)
4. Click **Save**

**Note**: After configuration, clicking logout in Jenkins will log you out of both Jenkins and Keycloak.

---

## Part 3: Testing and Verification

### Step 3.1: Test SSO Login

1. **Logout** from Jenkins (if logged in)
2. Navigate to Jenkins login page: `https://jenkins.local`
3. You should see a button: **Login with SAML SSO**
4. Click the button
5. You'll be redirected to Keycloak
6. Enter Keycloak credentials
7. After successful authentication, you'll be redirected back to Jenkins
8. Verify you're logged in with your Keycloak username

### Step 3.2: Verify User Information

1. Click on your username in the top-right corner
2. Go to **Configure**
3. Verify the following information is populated from Keycloak:
   - **Full Name**: Should match Keycloak profile
   - **Email Address**: Should match Keycloak email
   - **Groups**: Should show `jenkins-admins` or `jenkins-users`

### Step 3.3: Test Group-Based Authorization

1. Create a test job
2. Logout and login with a user in the `jenkins-users` group
3. Verify the user can:
   - ✅ View the job
   - ✅ Build the job
   - ❌ Not configure or delete the job

4. Login with a user in the `jenkins-admins` group
5. Verify the admin can:
   - ✅ Configure Jenkins settings
   - ✅ Manage plugins
   - ✅ Create/delete jobs

### Step 3.4: Check SAML Logs

**In Jenkins:**
1. Go to **Manage Jenkins** → **System Log**
2. Add logger: `org.jenkinsci.plugins.saml` at level `FINE`
3. Check logs for SAML authentication events

**In Keycloak:**
1. Go to **Realm settings** → **Events**
2. Enable **Save Events**: `On`
3. Check **Login Events** tab for authentication attempts

---

## Part 4: User and Group Management

### Step 4.1: Create Test Users in Keycloak

1. In Keycloak admin console, go to **Users**
2. Click **Create user**
3. Fill in user details:
   - **Username**: `testuser`
   - **Email**: `testuser@example.com`
   - **First name**: `Test`
   - **Last name**: `User`
   - **Email verified**: `On`
   - **Enabled**: `On`
4. Click **Create**

5. Go to **Credentials** tab
6. Click **Set password**
   - **Password**: (enter secure password)
   - **Temporary**: `Off`
7. Click **Save**

### Step 4.2: Assign Users to Groups

1. Select the user (e.g., `testuser`)
2. Go to **Groups** tab
3. Click **Join Group**
4. Select `devops/jenkins-users` or `devops/jenkins-admins`
5. Click **Join**

### Step 4.3: Assign Client Roles (Optional)

1. Select the user
2. Go to **Role mapping** tab
3. Click **Assign role**
4. Filter by: `Filter by clients`
5. Select `jenkins` client
6. Select roles: `admin` or `user`
7. Click **Assign**

---

## Troubleshooting

### Issue 1: SAML Authentication Fails

**Symptoms:**
- Redirected to Keycloak but get an error
- "Unable to validate SAML response"

**Solutions:**
1. Verify SP Entity ID matches in both Jenkins and Keycloak (`jenkins`)
2. Check that redirect URIs are correctly configured in Keycloak
3. Ensure clocks are synchronized between Jenkins and Keycloak servers
4. Verify IdP metadata is up-to-date in Jenkins

### Issue 2: User Not Getting Correct Groups

**Symptoms:**
- User logs in but doesn't have expected permissions
- Groups not showing in Jenkins user profile

**Solutions:**
1. Verify group mapper is configured in Keycloak client scopes
2. Check group attribute name is `groups` in both Keycloak and Jenkins
3. Ensure user is actually a member of the group in Keycloak
4. Try using full group path if needed

### Issue 3: Login Button Not Appearing

**Symptoms:**
- No "Login with SAML SSO" button on Jenkins login page

**Solutions:**
1. Verify SAML plugin is installed and enabled
2. Check Jenkins configuration has SAML security realm configured
3. Restart Jenkins service
4. Clear browser cache and cookies

### Issue 4: Getting Locked Out

**Solutions:**
1. If you get locked out, disable security temporarily:
   ```bash
   # Stop Jenkins
   sudo systemctl stop jenkins

   # Disable security
   sudo sed -i 's/<useSecurity>true<\/useSecurity>/<useSecurity>false<\/useSecurity>/g' /var/lib/jenkins/config.xml

   # Start Jenkins
   sudo systemctl start jenkins
   ```

2. Re-configure SAML with correct settings
3. Re-enable security

### Issue 5: Certificate or SSL Errors

**Symptoms:**
- SSL/TLS certificate validation errors
- "unable to find valid certification path"

**Solutions:**
1. If using self-signed certificates, import them:
   ```bash
   # Export Keycloak certificate
   openssl s_client -connect keycloak.local:443 -showcerts < /dev/null 2>/dev/null | openssl x509 -outform PEM > keycloak.crt

   # Import to Java keystore
   sudo keytool -import -alias keycloak -file keycloak.crt -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit

   # Restart Jenkins
   sudo systemctl restart jenkins
   ```

---

## Security Considerations

### Production Recommendations

1. **Use HTTPS Everywhere**
   - Both Jenkins and Keycloak should use valid SSL certificates
   - Enable HSTS headers

2. **Enable Signature Validation**
   - Set `wantAssertionsSigned: true` in Jenkins SAML config
   - Enable signature in Keycloak client settings

3. **Use Strong Credentials**
   - Change default Keycloak admin password
   - Use complex passwords for service accounts

4. **Enable Audit Logging**
   - Enable event logging in Keycloak
   - Configure Jenkins audit trail plugin

5. **Regular Updates**
   - Keep SAML plugin updated
   - Keep Keycloak updated to latest stable version

6. **Network Security**
   - Use firewall rules to restrict access
   - Consider using VPN or private networks

7. **Session Management**
   - Configure appropriate session timeouts
   - Enable re-authentication for sensitive operations

### Group-Based Access Control Best Practices

1. **Principle of Least Privilege**
   - Give users minimum required permissions
   - Use separate groups for different access levels

2. **Group Naming Convention**
   - Use clear, descriptive names
   - Example: `jenkins-admins`, `jenkins-developers`, `jenkins-viewers`

3. **Regular Audits**
   - Review group memberships quarterly
   - Remove users who no longer need access

---

## Quick Reference

### Jenkins SAML Configuration URLs

| Purpose | URL |
|---------|-----|
| SAML Login | `https://jenkins.local/securityRealm/commenceLogin` |
| SAML Callback | `https://jenkins.local/securityRealm/finishLogin` |
| Jenkins Security | `https://jenkins.local/manage/configureSecurity` |

### Keycloak URLs

| Purpose | URL |
|---------|-----|
| Admin Console | `https://keycloak.local/admin` |
| Realm Metadata | `https://keycloak.local/realms/master/protocol/saml/descriptor` |
| Account Console | `https://keycloak.local/realms/master/account` |

### Important File Locations

| Component | Path |
|-----------|------|
| Jenkins Config | `/var/lib/jenkins/config.xml` |
| Jenkins Home | `/var/lib/jenkins/` |
| Jenkins Logs | `/var/log/jenkins/jenkins.log` |
| Keycloak Config | `/opt/keycloak/conf/` |

---

## Automated Configuration

If you want to automate this configuration instead of doing it manually, use our Ansible playbook:

```bash
ansible-playbook playbooks/configure-keycloak-saml-integration.yml \
  -e "app=jenkins" \
  -i inventory
```

See [SAML_INTEGRATION_USAGE.md](../SAML_INTEGRATION_USAGE.md) for more details.

---

## Additional Resources

- [Jenkins SAML Plugin Documentation](https://plugins.jenkins.io/saml/)
- [Keycloak SAML Documentation](https://www.keycloak.org/docs/latest/server_admin/#_saml)
- [SAML 2.0 Specification](http://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)

---

**Last Updated**: 2025-11-24
**Tested Versions**:
- Jenkins: 2.479+
- Keycloak: 22.0.5+
- SAML Plugin: 4.429.v9a_781a_61f1da_
