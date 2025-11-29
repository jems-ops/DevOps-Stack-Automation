# Artifactory SAML SSO Integration with Keycloak

This document provides manual instructions for integrating Artifactory with Keycloak using SAML SSO authentication.

## ⚠️ Important: License Requirement

**SAML SSO is NOT supported in Artifactory OSS (Community Edition)**. This feature requires Artifactory Pro or Enterprise license.

If you are running Artifactory OSS, SAML configuration can be set via API but will not function. The login page will not display any SSO/SAML login option.

To use SAML SSO, you must upgrade to:
- Artifactory Pro
- Artifactory Pro X
- Artifactory Enterprise
- Artifactory Enterprise X

## Prerequisites

- **Artifactory Pro or Enterprise** installed and accessible at https://artifactory.local
- Keycloak installed and accessible at https://keycloak.local
- Admin credentials for both systems
- User account for testing (demo.user)

## Architecture Overview

```
User Browser → Artifactory (https://artifactory.local)
                    ↓ (SAML Request)
               Keycloak (https://keycloak.local)
                    ↓ (SAML Response)
               Artifactory validates and creates session
```

## Step 1: Configure Keycloak

### 1.1 Create Artifactory Client

1. Login to Keycloak Admin Console: https://keycloak.local/admin
2. Navigate to: **Clients** → **Create client**
3. Configure client:
   - **Client type**: SAML
   - **Client ID**: `artifactory`
   - Click **Next**

4. Configure capability:
   - **Name**: Artifactory
   - **Description**: Artifactory SAML Integration
   - Click **Save**

5. Configure Settings tab:
   - **Valid redirect URIs**: `https://artifactory.local/*`
   - **IDP-Initiated SSO URL name**: `artifactory`
   - **Name ID format**: `username`
   - **Force POST binding**: `ON`
   - **Front channel logout**: `ON`
   - Click **Save**

### 1.2 Configure Client Scopes and Mappers

1. Go to **Client scopes** tab
2. Click on **artifactory-dedicated** scope
3. Go to **Mappers** tab → **Add mapper** → **By configuration**

Add the following mappers:

#### Username Mapper
- **Mapper type**: User Property
- **Name**: username
- **Property**: username
- **SAML Attribute Name**: username
- **SAML Attribute NameFormat**: Basic
- Click **Save**

#### Email Mapper
- **Mapper type**: User Property
- **Name**: email
- **Property**: email
- **SAML Attribute Name**: email
- **SAML Attribute NameFormat**: Basic
- Click **Save**

#### Name Mapper
- **Mapper type**: User Property
- **Name**: name
- **Property**: username
- **SAML Attribute Name**: name
- **SAML Attribute NameFormat**: Basic
- Click **Save**

#### Groups Mapper
- **Mapper type**: Group list
- **Name**: groups
- **Group attribute name**: groups
- **Single Group Attribute**: `OFF`
- **Full group path**: `ON`
- Click **Save**

### 1.3 Create User Group

1. Navigate to: **Groups** → **Create group**
2. Configure group:
   - **Name**: `devops`
   - Click **Create**

3. Create subgroup:
   - Click on **devops** group
   - Click **Create group** (child)
   - **Name**: `artifactory-users`
   - Click **Create**

### 1.4 Assign Users to Group

1. Navigate to: **Users** → Find your test user (demo.user)
2. Go to **Groups** tab
3. Click **Join Group**
4. Select `/devops/artifactory-users`
5. Click **Join**

### 1.5 Add Client Role to Group

1. Navigate to: **Groups** → **devops** → **artifactory-users**
2. Go to **Role mapping** tab
3. Click **Assign role**
4. Filter by clients: Select **artifactory**
5. Select the client role
6. Click **Assign**

## Step 2: Configure Artifactory SAML

### 2.1 Get Keycloak SAML Metadata

Download the SAML descriptor:
```bash
curl -k -o /tmp/keycloak-saml-descriptor.xml \
  https://keycloak.local/realms/master/protocol/saml/descriptor
```

### 2.2 Extract Certificate

Extract the X.509 certificate from the descriptor:
```bash
grep -oP '(?<=<ds:X509Certificate>).*?(?=</ds:X509Certificate>)' \
  /tmp/keycloak-saml-descriptor.xml
```

### 2.3 Configure SAML via API

Create a JSON file (`artifactory-saml-config.json`) with the following content:

```json
{
  "enableIntegration": true,
  "loginUrl": "https://keycloak.local/realms/master/protocol/saml",
  "logoutUrl": "https://keycloak.local/realms/master/protocol/saml",
  "serviceProviderName": "artifactory",
  "certificate": "<PASTE_CERTIFICATE_HERE>",
  "useEncryptedAssertion": false,
  "syncGroups": true,
  "groupAttribute": "groups",
  "emailAttribute": "email",
  "noAutoUserCreation": false,
  "allowUserToAccessProfile": true,
  "autoRedirect": false,
  "verifyAudienceRestriction": false
}
```

Replace `<PASTE_CERTIFICATE_HERE>` with the certificate extracted in Step 2.2.

Apply the configuration:
```bash
curl -k -X PUT \
  -u admin:<ARTIFACTORY_ADMIN_PASSWORD> \
  -H "Content-Type: application/json" \
  -d @artifactory-saml-config.json \
  https://artifactory.local/artifactory/api/saml/config
```

### 2.4 Set Base URL (if not already set)

Ensure Artifactory has the correct base URL:
```bash
curl -k -X POST \
  -u admin:<ARTIFACTORY_ADMIN_PASSWORD> \
  -H "Content-Type: application/xml" \
  -d '<config><urlBase>https://artifactory.local</urlBase></config>' \
  https://artifactory.local/artifactory/api/system/configuration
```

## Step 3: Test SAML Login

### 3.1 Access Artifactory

1. Navigate to: https://artifactory.local
2. On the login page, look for:
   - "Login via SSO" button/link
   - Or direct SAML login: https://artifactory.local/ui/login?sso

### 3.2 Login Flow

1. Click "Login via SSO"
2. You will be redirected to Keycloak
3. Login with test user credentials:
   - **Username**: demo.user
   - **Password**: (stored in Ansible vault or Keycloak)
4. After successful authentication, you'll be redirected back to Artifactory
5. A new user should be auto-created if it doesn't exist

### 3.3 Verify User Creation

1. Login as admin to Artifactory
2. Navigate to: **Administration** → **Security** → **Users**
3. Verify that `demo.user` was created with email from Keycloak

## Managing SAML SSO

### Enable SAML SSO

Apply the SAML configuration using the API as shown in Step 2.3, or run the Ansible playbook:
```bash
ansible-playbook -i inventory \
  playbooks/configure-keycloak-saml-integration.yml \
  -e 'app=artifactory'
```

### Disable SAML SSO

To disable SAML and revert to local authentication:
```bash
curl -k -X PUT \
  -u admin:<ARTIFACTORY_ADMIN_PASSWORD> \
  -H "Content-Type: application/json" \
  -d '{"enableIntegration": false}' \
  https://artifactory.local/artifactory/api/saml/config
```

Or directly edit the configuration file on the Artifactory server:
```bash
# Edit /opt/jfrog/artifactory/etc/security/security.xml
# Set: <samlSettings enabled="false">
sudo systemctl restart artifactory
```

### Verify SAML Configuration

Check current SAML settings:
```bash
curl -k -u admin:<ARTIFACTORY_ADMIN_PASSWORD> \
  https://artifactory.local/artifactory/api/saml/config | jq
```

## Troubleshooting

### Issue: Cannot find SSO/SAML login option

**Solution**:
- Verify SAML is enabled: Check API endpoint `/artifactory/api/saml/config`
- Try direct URL: https://artifactory.local/ui/login?sso
- Check browser console for errors

### Issue: Redirect loop after login

**Solution**:
- Verify `urlBase` is set correctly to https://artifactory.local
- Check Keycloak redirect URIs include `https://artifactory.local/*`
- Ensure certificate is correct and matches Keycloak's signing certificate

### Issue: User not auto-created

**Solution**:
- Verify `noAutoUserCreation: false` in SAML config
- Check attribute mappings in Keycloak (username, email)
- Verify user is member of `/devops/artifactory-users` group

### Issue: User created but no permissions

**Solution**:
- Groups are synced from Keycloak
- Ensure user is member of appropriate group in Keycloak
- Check `syncGroups: true` in SAML config
- Map Keycloak groups to Artifactory permissions

## Important Configuration Details

### SAML Attributes Required
- **username**: User's login name (Property: username)
- **email**: User's email address (Property: email)
- **name**: User's display name (Property: username)
- **groups**: User's group memberships (Full path)

### Keycloak Configuration
- **Realm**: master
- **Client ID**: artifactory
- **Name ID Format**: username
- **Force POST Binding**: ON
- **Group Path**: Full path (e.g., /devops/artifactory-users)

### Artifactory Configuration
- **Base URL**: https://artifactory.local
- **Service Provider Name**: artifactory
- **Auto User Creation**: Enabled
- **Group Sync**: Enabled
- **Auto Redirect**: Disabled (users can choose SSO or local)

## Ansible Automation

The entire setup can be automated using the Ansible playbook:

```bash
ansible-playbook -i inventory \
  playbooks/configure-keycloak-saml-integration.yml \
  -e 'app=artifactory'
```

This will:
1. Configure Keycloak client with all required settings
2. Create groups and assign users
3. Configure Artifactory SAML integration via API
4. Test the integration

## Credentials

### Keycloak Admin Console
- **URL**: https://keycloak.local/admin
- **Username**: admin
- **Password**: (stored in Ansible vault)

### Artifactory Admin
- **URL**: https://artifactory.local
- **Username**: admin
- **Password**: (stored in Ansible vault)

### Test User
- **Username**: demo.user
- **Password**: (stored in Ansible vault or Keycloak)
- **Group**: /devops/artifactory-users

## Additional Notes

- SAML SSO and local authentication can coexist
- Admin users can always login with local credentials
- Group permissions must be configured in Artifactory separately
- SAML configuration is stored in `/opt/jfrog/artifactory/etc/security/security.xml`
- Certificate updates in Keycloak require updating Artifactory SAML config
