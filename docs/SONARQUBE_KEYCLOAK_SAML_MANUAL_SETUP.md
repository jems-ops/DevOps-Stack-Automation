# SonarQube Keycloak SAML SSO - Manual Configuration Guide

This guide provides step-by-step instructions for manually configuring SAML Single Sign-On (SSO) between SonarQube and Keycloak, based on our Ansible automation role.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Part 1: Keycloak Configuration](#part-1-keycloak-configuration)
- [Part 2: SonarQube Configuration](#part-2-sonarqube-configuration)
- [Part 3: Testing and Verification](#part-3-testing-and-verification)
- [Part 4: User and Group Management](#part-4-user-and-group-management)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

---

## Prerequisites

Before starting, ensure you have:

- ✅ SonarQube installed and accessible (e.g., `https://sonar.local`)
- ✅ Keycloak installed and accessible (e.g., `https://keycloak.local`)
- ✅ Admin access to both SonarQube and Keycloak
- ✅ SonarQube version 10.3.0 or later (with built-in SAML support)
- ✅ SonarQube admin password

### Required Information

| Item | Value | Notes |
|------|-------|-------|
| SonarQube URL | `https://sonar.local` | Your SonarQube base URL |
| Keycloak URL | `https://keycloak.local` | Your Keycloak base URL |
| Keycloak Realm | `master` | Realm where client will be created |
| Keycloak Admin User | `admin` | Keycloak admin username |
| Keycloak Admin Password | `Admin@2025` | Keycloak admin password |
| SonarQube Admin User | `admin` | SonarQube admin username |
| SonarQube Admin Password | `Sonar@2025` | SonarQube admin password |

---

## Architecture Overview

```
┌─────────────┐          SAML          ┌──────────────┐
│             │◄─────Authentication────►│              │
│  SonarQube  │                         │   Keycloak   │
│  (Service   │    IdP Metadata         │     (IdP)    │
│  Provider)  │◄────────────────────────│              │
│             │                         │              │
└─────────────┘                         └──────────────┘
```

**Flow:**
1. User accesses SonarQube
2. User clicks "Log in with SAML" button
3. SonarQube redirects to Keycloak for authentication
4. User logs in with Keycloak credentials
5. Keycloak returns SAML assertion to SonarQube
6. SonarQube creates/updates user session with group mappings

---

## Part 1: Keycloak Configuration

### Step 1.1: Access Keycloak Admin Console

1. Open browser and navigate to: `https://keycloak.local/admin`
2. Login with admin credentials (`admin` / `Admin@2025`)
3. Select the **master** realm from the dropdown (or your desired realm)

### Step 1.2: Create SAML Client for SonarQube

1. In the left sidebar, click **Clients**
2. Click **Create client** button
3. Fill in the **General Settings**:
   - **Client type**: `SAML`
   - **Client ID**: `sonarqube`
   - Click **Next**

4. Configure **Capability config**:
   - **Client signature required**: `Off`
   - **Force POST binding**: `On`
   - **Front channel logout**: `On`
   - **Force name ID format**: `Off`
   - **Name ID format**: `username`
   - **Include AuthnStatement**: `On`
   - **Sign documents**: `Off`
   - **Sign assertions**: `On`
   - **Signature algorithm**: `RSA_SHA256`
   - **SAML signature key name**: `CERT_SUBJECT`
   - **Canonicalization method**: `EXCLUSIVE`
   - Click **Next**

5. Configure **Login settings**:
   - **Root URL**: `https://sonar.local`
   - **Home URL**: `https://sonar.local`
   - **Valid redirect URIs**:
     ```
     https://sonar.local/*
     https://sonar.local/oauth2/callback/saml
     ```
   - **Valid post logout redirect URIs**: `https://sonar.local/*`
   - **IDP Initiated SSO URL name**: `sonarqube`
   - **Master SAML Processing URL**: `https://sonar.local/oauth2/callback/saml`
   - **Assertion Consumer Service POST Binding URL**: `https://sonar.local/oauth2/callback/saml`
   - Click **Save**

### Step 1.3: Delete Default Protocol Mappers

**IMPORTANT**: SonarQube's SAML library is strict about duplicate attributes. We must remove Keycloak's default mappers before creating our own.

1. Go to **Clients** → **sonarqube** → **Client scopes** tab
2. Click on **sonarqube-dedicated** scope
3. Click on the **Mappers** tab
4. Delete ALL existing mappers if any exist (role list, X500 email, X500 givenName, X500 surname, etc.)

### Step 1.4: Configure Custom Protocol Mappers

Now add our custom mappers for SonarQube:

#### Mapper 1: Username

1. Click **Add mapper** → **By configuration** → **User Property**
2. Configure:
   - **Name**: `username`
   - **Property**: `username`
   - **Friendly Name**: `Username`
   - **SAML Attribute Name**: `username`
   - **SAML Attribute NameFormat**: `Basic`
3. Click **Save**

#### Mapper 2: Email

1. Click **Add mapper** → **By configuration** → **User Property**
2. Configure:
   - **Name**: `email`
   - **Property**: `email`
   - **Friendly Name**: `Email`
   - **SAML Attribute Name**: `email`
   - **SAML Attribute NameFormat**: `Basic`
3. Click **Save**

#### Mapper 3: Name (Display Name)

1. Click **Add mapper** → **By configuration** → **User Property**
2. Configure:
   - **Name**: `name`
   - **Property**: `username`
   - **Friendly Name**: `Name`
   - **SAML Attribute Name**: `name`
   - **SAML Attribute NameFormat**: `Basic`
3. Click **Save**

> **Note**: We map `username` to the `name` attribute because SonarQube uses this for display name.

#### Mapper 4: Groups

1. Click **Add mapper** → **By configuration** → **Group list**
2. Configure:
   - **Name**: `groups`
   - **Group attribute name**: `groups`
   - **Friendly Name**: `Groups`
   - **SAML Attribute NameFormat**: `Basic`
   - **Single Group Attribute**: `Off`
   - **Full group path**: `Off`
3. Click **Save**

> **CRITICAL**: Set "Single Group Attribute" to `Off` and "Full group path" to `Off` to avoid duplicate attribute errors.

### Step 1.5: Create Groups

1. In the left sidebar, click **Groups**
2. Click **Create group**
3. Create parent group:
   - **Name**: `devops`
   - Click **Create**

4. Select the `devops` group, then click **Create group**
5. Create admin group:
   - **Name**: `sonarqube-admins`
   - Click **Create**

6. Go back to `devops` group, then click **Create group**
7. Create user group:
   - **Name**: `sonarqube-users`
   - Click **Create**

**Group Hierarchy:**
```
devops/
├── sonarqube-admins
└── sonarqube-users
```

### Step 1.6: Create Roles (Optional but Recommended)

1. Go to **Clients** → **sonarqube** → **Roles** tab
2. Click **Create role**
3. Create admin role:
   - **Role name**: `admin`
   - **Description**: `SonarQube Administrator`
   - Click **Save**

4. Click **Create role** again
5. Create user role:
   - **Role name**: `user`
   - **Description**: `SonarQube User`
   - Click **Save**

### Step 1.7: Create Test User

1. In the left sidebar, click **Users**
2. Click **Create new user**
3. Fill in user details:
   - **Username**: `demo.user`
   - **Email**: `demo@example.com`
   - **First name**: `Demo`
   - **Last name**: `User`
   - **Email verified**: `On`
   - **Enabled**: `On`
4. Click **Create**

5. Set user password:
   - Go to the **Credentials** tab
   - Click **Set password**
   - **Password**: `demo123!`
   - **Password confirmation**: `demo123!`
   - **Temporary**: `Off`
   - Click **Save**

6. Assign user to groups:
   - Go to the **Groups** tab
   - Click **Join Group**
   - Select `devops/sonarqube-users`
   - Click **Join**

7. Assign user to roles:
   - Go to the **Role mapping** tab
   - Click **Assign role**
   - Filter by clients: select **sonarqube**
   - Select `user` role
   - Click **Assign**

---

## Part 2: SonarQube Configuration

### Step 2.1: Access SonarQube as Admin

1. Open browser and navigate to: `https://sonar.local`
2. Click **Log in**
3. Login with admin credentials (`admin` / `Sonar@2025`)

### Step 2.2: Configure SAML in sonar.properties

SonarQube's SAML configuration is done via the `sonar.properties` file, not through the UI.

1. SSH into the SonarQube server
2. Stop SonarQube service:
   ```bash
   sudo systemctl stop sonarqube
   ```

3. Backup the current configuration:
   ```bash
   sudo cp /opt/sonarqube/conf/sonar.properties /opt/sonarqube/conf/sonar.properties.backup
   ```

4. Edit the configuration file:
   ```bash
   sudo vi /opt/sonarqube/conf/sonar.properties
   ```

5. Add the following SAML configuration at the end of the file:

```properties
# SAML Authentication Configuration
sonar.auth.saml.enabled=true
sonar.auth.saml.applicationId=sonarqube
sonar.auth.saml.providerName=Keycloak SAML
sonar.auth.saml.providerId=https://keycloak.local/realms/master
sonar.auth.saml.loginUrl=https://keycloak.local/realms/master/protocol/saml
sonar.auth.saml.certificate.secured=

# User Attribute Mappings
sonar.auth.saml.user.login=username
sonar.auth.saml.user.name=name
sonar.auth.saml.user.email=email

# Group Mapping
sonar.auth.saml.group.name=groups

# Service Provider Configuration
sonar.auth.saml.sp.entityId=sonarqube

# Auto-create users from SAML
sonar.auth.saml.user.signUpEnabled=true

# Default group for new SAML users
sonar.auth.saml.user.defaultGroup=sonarqube-users
```

6. Save and exit the editor

7. Start SonarQube service:
   ```bash
   sudo systemctl start sonarqube
   ```

8. Wait for SonarQube to fully start (check logs):
   ```bash
   sudo tail -f /opt/sonarqube/logs/sonar.log
   ```

   Wait until you see: `SonarQube is operational`

### Step 2.3: Verify SAML Configuration

1. Navigate to `https://sonar.local`
2. You should now see a **Log in with SAML** button on the login page
3. Do NOT login yet - we need to configure Keycloak certificate first

### Step 2.4: Get Keycloak SAML Certificate

1. Download Keycloak's SAML signing certificate:
   ```bash
   curl -k https://keycloak.local/realms/master/protocol/saml/descriptor \
     | grep -oP '(?<=<ds:X509Certificate>).*(?=</ds:X509Certificate>)' \
     > /tmp/keycloak-cert.txt
   ```

2. Or manually:
   - Navigate to: `https://keycloak.local/realms/master/protocol/saml/descriptor`
   - Find the `<ds:X509Certificate>` element
   - Copy the certificate value (between the tags)

3. Update `sonar.properties` with the certificate:
   ```bash
   sudo vi /opt/sonarqube/conf/sonar.properties
   ```

4. Find the line `sonar.auth.saml.certificate.secured=` and paste the certificate value:
   ```properties
   sonar.auth.saml.certificate.secured=MIICnzCCAYcCBgGTg8...paste_full_cert_here...
   ```

5. Save and restart SonarQube:
   ```bash
   sudo systemctl restart sonarqube
   ```

---

## Part 3: Testing and Verification

### Step 3.1: Test SAML Login

1. Navigate to `https://sonar.local`
2. Click **Log in with SAML**
3. You will be redirected to Keycloak
4. Login with test user credentials:
   - Username: `demo.user`
   - Password: `demo123!`
5. After successful authentication, you should be redirected back to SonarQube
6. Verify you are logged in as `demo.user`

### Step 3.2: Verify User Creation

1. Login to SonarQube as admin (`admin` / `Sonar@2025`)
2. Go to **Administration** → **Security** → **Users**
3. Verify that `demo.user` was created automatically
4. Check that the user has:
   - ✅ Username: `demo.user`
   - ✅ Email: `demo@example.com`
   - ✅ Groups: `sonarqube-users`

### Step 3.3: Verify Group Synchronization

1. In SonarQube admin console, go to **Administration** → **Security** → **Groups**
2. Create the `sonarqube-users` group if it doesn't exist:
   - Click **Create Group**
   - **Name**: `sonarqube-users`
   - **Description**: `SonarQube Users from SAML`
   - Click **Create**

3. Create the `sonarqube-admins` group:
   - Click **Create Group**
   - **Name**: `sonarqube-admins`
   - **Description**: `SonarQube Administrators from SAML`
   - Click **Create**

4. Assign permissions to `sonarqube-admins`:
   - Select `sonarqube-admins` group
   - Go to **Permissions** tab
   - Grant **Administer System** permission

5. Assign permissions to `sonarqube-users`:
   - Select `sonarqube-users` group
   - Grant appropriate permissions (e.g., **Browse**, **Execute Analysis**)

### Step 3.4: Test Admin Access

1. In Keycloak, add `demo.user` to the `sonarqube-admins` group:
   - Go to **Users** → **demo.user** → **Groups**
   - Click **Join Group**
   - Select `devops/sonarqube-admins`
   - Click **Join**

2. In SonarQube, logout `demo.user`
3. Login again with SAML as `demo.user`
4. Verify that `demo.user` now has admin permissions in SonarQube
5. Check **Administration** menu is visible

---

## Part 4: User and Group Management

### Creating Additional Users

1. In Keycloak Admin Console, go to **Users**
2. Click **Create new user**
3. Fill in user details and credentials
4. Assign to appropriate groups:
   - `devops/sonarqube-users` for regular users
   - `devops/sonarqube-admins` for administrators

### Group Mapping Strategy

| Keycloak Group | SonarQube Group | Permissions |
|----------------|-----------------|-------------|
| `devops/sonarqube-admins` | `sonarqube-admins` | Full admin access |
| `devops/sonarqube-users` | `sonarqube-users` | Browse, Execute Analysis |

### Managing Permissions

1. Go to **Administration** → **Security** → **Global Permissions**
2. Configure permissions for groups:
   - `sonarqube-admins`: Grant all permissions
   - `sonarqube-users`: Grant browse and analysis permissions

---

## Troubleshooting

### Issue 1: "Found an Attribute element with duplicated Name"

**Symptoms**: Error in SonarQube logs when trying to login with SAML.

**Cause**: Keycloak has built-in default protocol mappers that conflict with custom mappers.

**Solution**:
1. In Keycloak, go to **Clients** → **sonarqube** → **Client scopes** → **sonarqube-dedicated** → **Mappers**
2. Delete ALL existing mappers
3. Add only the 4 custom mappers as described in Step 1.4
4. Ensure "Single Group Attribute" is set to `Off` for the groups mapper

### Issue 2: "You're not authorized to access this page"

**Symptoms**: User can login via SAML but gets unauthorized error.

**Cause**: User's groups from Keycloak don't exist in SonarQube, or don't have permissions.

**Solution**:
1. Create the groups in SonarQube: `sonarqube-users`, `sonarqube-admins`
2. Assign appropriate permissions to these groups
3. Verify the user is in the correct groups in Keycloak
4. Logout and login again

### Issue 3: SAML Button Not Appearing

**Symptoms**: No "Log in with SAML" button on SonarQube login page.

**Cause**: SAML not properly enabled in `sonar.properties`.

**Solution**:
1. Check `/opt/sonarqube/conf/sonar.properties`
2. Verify `sonar.auth.saml.enabled=true`
3. Restart SonarQube: `sudo systemctl restart sonarqube`
4. Check logs: `sudo tail -f /opt/sonarqube/logs/web.log`

### Issue 4: Invalid SAML Response

**Symptoms**: Error about invalid signature or certificate.

**Cause**: Missing or incorrect Keycloak certificate in SonarQube configuration.

**Solution**:
1. Download fresh certificate from Keycloak:
   ```bash
   curl -k https://keycloak.local/realms/master/protocol/saml/descriptor
   ```
2. Extract the X509Certificate value
3. Update `sonar.auth.saml.certificate.secured` in `sonar.properties`
4. Restart SonarQube

### Issue 5: Groups Not Synchronized

**Symptoms**: User can login but doesn't have correct groups.

**Cause**: Group mapper not configured correctly or groups don't exist in SonarQube.

**Solution**:
1. Verify groups mapper in Keycloak:
   - **Single Group Attribute**: `Off`
   - **Full group path**: `Off`
2. Create matching groups in SonarQube
3. Check user's group membership in Keycloak
4. Logout and login again to refresh SAML assertion

### Checking Logs

**SonarQube Logs**:
```bash
# Web logs (SAML authentication)
sudo tail -f /opt/sonarqube/logs/web.log

# Main SonarQube log
sudo tail -f /opt/sonarqube/logs/sonar.log
```

**Keycloak Logs** (if on separate server):
```bash
# Keycloak server logs
sudo journalctl -u keycloak -f
```

---

## Security Considerations

### 1. Certificate Validation

- Always use `sonar.auth.saml.certificate.secured` to validate Keycloak's signature
- Never set `Sign assertions` to `Off` in production
- Use HTTPS for both SonarQube and Keycloak

### 2. User Provisioning

- Enable `sonar.auth.saml.user.signUpEnabled=true` to auto-create users
- Set `sonar.auth.saml.user.defaultGroup` to control default permissions
- Regularly audit user accounts in SonarQube

### 3. Group Synchronization

- Keep Keycloak groups in sync with SonarQube groups
- Use descriptive group names that clearly indicate access level
- Document group-to-permission mappings

### 4. Session Management

- Configure appropriate session timeouts in SonarQube
- Enable Front Channel Logout in Keycloak for proper logout
- Test logout functionality regularly

### 5. Monitoring and Auditing

- Monitor SonarQube logs for SAML authentication failures
- Enable audit logging in both SonarQube and Keycloak
- Set up alerts for suspicious authentication patterns

### 6. Backup and Recovery

- Regularly backup `sonar.properties` configuration
- Document all SAML configuration settings
- Keep Keycloak certificate up to date

---

## Configuration Reference

### Complete sonar.properties SAML Section

```properties
# SAML Authentication
sonar.auth.saml.enabled=true
sonar.auth.saml.applicationId=sonarqube
sonar.auth.saml.providerName=Keycloak SAML
sonar.auth.saml.providerId=https://keycloak.local/realms/master
sonar.auth.saml.loginUrl=https://keycloak.local/realms/master/protocol/saml
sonar.auth.saml.certificate.secured=<KEYCLOAK_CERT_HERE>

# User Attributes
sonar.auth.saml.user.login=username
sonar.auth.saml.user.name=name
sonar.auth.saml.user.email=email
sonar.auth.saml.user.signUpEnabled=true
sonar.auth.saml.user.defaultGroup=sonarqube-users

# Group Mapping
sonar.auth.saml.group.name=groups

# Service Provider
sonar.auth.saml.sp.entityId=sonarqube
```

### Keycloak Client Configuration Summary

| Setting | Value |
|---------|-------|
| Client ID | `sonarqube` |
| Client Protocol | `SAML` |
| Sign Assertions | `On` |
| Force POST Binding | `On` |
| Front Channel Logout | `On` |
| Name ID Format | `username` |
| Valid Redirect URIs | `https://sonar.local/*` |
| Master SAML Processing URL | `https://sonar.local/oauth2/callback/saml` |

### Protocol Mappers Summary

| Mapper Name | Type | User Property | SAML Attribute | Notes |
|-------------|------|---------------|----------------|-------|
| username | User Property | username | username | Login identifier |
| email | User Property | email | email | User email |
| name | User Property | username | name | Display name |
| groups | Group List | - | groups | Group membership |

---

## Appendix: Automation with Ansible

This manual configuration can be automated using our Ansible role:

```bash
# Run from the feature/sonarqube-keycloak-saml-role branch
ansible-playbook -i inventory \
  playbooks/configure-sonarqube-keycloak-saml-role.yml \
  --ask-pass
```

The role automatically:
- Creates Keycloak SAML client with proper configuration
- Deletes default protocol mappers
- Creates custom protocol mappers
- Configures SonarQube sonar.properties
- Creates test users and groups
- Restarts SonarQube service

---

## Additional Resources

- [SonarQube SAML Documentation](https://docs.sonarqube.org/latest/instance-administration/authentication/saml/)
- [Keycloak SAML Documentation](https://www.keycloak.org/docs/latest/server_admin/#saml-clients)
- [SAML 2.0 Specification](http://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-26  
**Tested With**:
- SonarQube: 10.3.0.82913
- Keycloak: 26.0.7
- PostgreSQL: 15.x
