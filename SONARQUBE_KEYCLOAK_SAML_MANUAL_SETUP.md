# SonarQube Keycloak SAML Integration - Manual Setup Guide

## Overview
SonarQube is now running at: **http://192.168.201.16:9000**
Keycloak is running at: **http://192.168.201.12:8080**

Default SonarQube credentials: **admin/admin** (change after first login)

## Step 1: Keycloak SAML Client Configuration

### 1.1 Access Keycloak Admin Console
1. Navigate to: http://192.168.201.12:8080
2. Login to the admin console
3. Select your realm (usually 'master' or create a new one)

### 1.2 Create SAML Client
1. Go to **Clients** → **Create Client**
2. **Client Type**: `SAML`
3. **Client ID**: `sonarqube`
4. Click **Save**

### 1.3 Configure Client Settings
Navigate to the client settings and configure:

**General Settings:**
- **Client ID**: `sonarqube`
- **Name**: `SonarQube`
- **Enabled**: `ON`

**Access Settings:**
- **Root URL**: `http://192.168.201.16:9000`
- **Valid redirect URIs**: `http://192.168.201.16:9000/oauth2/callback/saml`
- **Base URL**: `http://192.168.201.16:9000`
- **Master SAML Processing URL**: `http://192.168.201.16:9000/oauth2/callback/saml`

**SAML Settings:**
- **Name ID Format**: `username`
- **Force Authentication**: `OFF`
- **Include AuthnStatement**: `ON`
- **Sign Documents**: `ON`
- **Sign Assertions**: `OFF`
- **Client Signature Required**: `OFF`
- **Force POST Binding**: `OFF`
- **Front Channel Logout**: `ON`

## Step 2: Configure Attribute Mappers

Go to **Client Scopes** → Find your client → **Mappers** → **Add Mapper**

### 2.1 Name Mapper
- **Name**: `name`
- **Mapper Type**: `User Attribute`
- **User Attribute**: `name`
- **SAML Attribute Name**: `name`
- **SAML Attribute NameFormat**: `Basic`

### 2.2 Email Mapper
- **Name**: `email`
- **Mapper Type**: `User Attribute`
- **User Attribute**: `email`
- **SAML Attribute Name**: `email`
- **SAML Attribute NameFormat**: `Basic`

### 2.3 Groups Mapper
- **Name**: `groups`
- **Mapper Type**: `Group Membership`
- **SAML Attribute Name**: `groups`
- **SAML Attribute NameFormat**: `Basic`

## Step 3: Get SAML Metadata

Get the SAML IdP metadata URL (replace {realm-name} with your actual realm):
```
http://192.168.201.12:8080/realms/{realm-name}/protocol/saml/descriptor
```

Example for 'master' realm:
```
http://192.168.201.12:8080/realms/master/protocol/saml/descriptor
```

## Step 4: Configure SonarQube SAML Settings

### 4.1 Login to SonarQube
1. Navigate to: http://192.168.201.16:9000
2. Login with: **admin/admin**
3. You'll be prompted to change the password - do this first

### 4.2 Install SAML Plugin (if not installed)
1. Go to **Administration** → **Marketplace**
2. Search for "SAML 2.0"
3. Install the SAML Authentication plugin
4. Restart SonarQube

### 4.3 Configure SAML Authentication
1. Go to **Administration** → **Configuration** → **General Settings** → **Security** → **SAML**

Configure these settings:

**Basic Configuration:**
- **Enabled**: `true`
- **Application ID**: `sonarqube`
- **Provider ID**: `http://192.168.201.12:8080/realms/master` (adjust realm name)
- **Provider Name**: `Keycloak`

**Identity Provider:**
- **SAML login URL**: `http://192.168.201.12:8080/realms/master/protocol/saml`
- **Provider certificate**: (Get from Keycloak SAML metadata)

**Service Provider:**
- **SP Entity ID**: `sonarqube`
- **SP Assertion Consumer Service URL**: `http://192.168.201.16:9000/oauth2/callback/saml`

**User Attributes:**
- **Login attribute**: `name` or `username`
- **Name attribute**: `name`
- **Email attribute**: `email`
- **Group attribute**: `groups` (optional)

## Step 5: Test SAML Authentication

### 5.1 Create Test User in Keycloak
1. In Keycloak, go to **Users** → **Add User**
2. Fill in:
   - **Username**: `testuser`
   - **Email**: `testuser@example.com`
   - **First Name**: `Test`
   - **Last Name**: `User`
3. Set password in **Credentials** tab

### 5.2 Test Login
1. Logout from SonarQube admin
2. On SonarQube login page, look for "Log in with Keycloak" or similar button
3. Try logging in with the test user
4. You should be redirected to Keycloak, authenticate, and return to SonarQube

## Step 6: Configure Group Mappings (Optional)

### 6.1 In Keycloak
1. Create groups: **Administration** → **Groups**
2. Create groups like: `sonar-admins`, `sonar-users`
3. Assign users to groups

### 6.2 In SonarQube
1. Go to **Administration** → **Security** → **Groups**
2. Map Keycloak groups to SonarQube permissions

## Troubleshooting

### Common Issues:

1. **SAML Response Issues**
   - Check SonarQube logs: `/opt/sonarqube/logs/web.log`
   - Verify URLs match exactly (no trailing slashes)

2. **Certificate Issues**
   - Download certificate from Keycloak SAML metadata
   - Ensure it's properly formatted in SonarQube

3. **Attribute Mapping Issues**
   - Check attribute names in SAML response
   - Verify mapper configurations in Keycloak

### Log Locations:
- **SonarQube**: `/opt/sonarqube/logs/web.log`
- **Keycloak**: Check Keycloak admin events and server logs

## Security Notes:

1. **Change default passwords** immediately
2. **Use HTTPS** in production (configure SSL certificates)
3. **Review user permissions** and group mappings
4. **Enable audit logging** in both systems

## Quick Commands for Troubleshooting:

```bash
# Check SonarQube logs
ansible sonarqube-prod -m shell -a "tail -50 /opt/sonarqube/logs/web.log"

# Restart SonarQube if needed
ansible sonarqube-prod -m shell -a "sudo systemctl restart sonarqube"

# Check SonarQube status
ansible sonarqube-prod -m shell -a "sudo systemctl status sonarqube"
```

---

**Next Steps:**
1. Complete Keycloak client configuration
2. Configure SonarQube SAML settings
3. Test authentication flow
4. Set up user/group mappings as needed

**Remember**: After configuring SAML, the admin user will still work locally, but new users will authenticate via Keycloak.
