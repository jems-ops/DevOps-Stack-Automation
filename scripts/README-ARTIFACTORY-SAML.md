# Artifactory SAML SSO Configuration Scripts

Scripts to configure Artifactory SAML SSO integration with Keycloak via API.

## Scripts

### 1. `get-keycloak-saml-cert.sh`
Extracts the SAML X.509 certificate from Keycloak.

**Usage:**
```bash
# Default (uses https://keycloak.local)
./get-keycloak-saml-cert.sh

# Custom Keycloak URL
KEYCLOAK_URL=https://keycloak.example.com ./get-keycloak-saml-cert.sh

# Custom realm
REALM=myrealm ./get-keycloak-saml-cert.sh
```

### 2. `configure-artifactory-saml.sh`
Configures Artifactory SAML SSO via REST API.

**Usage:**
```bash
# Set variables and run
export SAML_CERTIFICATE='MIICmzCCAYM...'
export ARTIFACTORY_ADMIN_PASSWORD='your_password'
./configure-artifactory-saml.sh

# Or inline
SAML_CERTIFICATE='MIICmzCCAYM...' \
ARTIFACTORY_ADMIN_PASSWORD='your_password' \
./configure-artifactory-saml.sh

# Custom Artifactory URL
ARTIFACTORY_URL=http://192.168.56.11:8080 \
SAML_CERTIFICATE='MIICmzCCAYM...' \
ARTIFACTORY_ADMIN_PASSWORD='your_password' \
./configure-artifactory-saml.sh
```

## Complete Workflow

### Step 1: Extract Certificate
```bash
./get-keycloak-saml-cert.sh
```

Copy the certificate output and save it to a variable.

### Step 2: Configure Artifactory
```bash
export SAML_CERTIFICATE='<paste_certificate_here>'
export ARTIFACTORY_ADMIN_PASSWORD='your_password'
./configure-artifactory-saml.sh
```

### Step 3: Test SSO Login
1. Go to https://artifactory.local/ui/login
2. Click "Login via SSO"
3. Login with Keycloak credentials

## Environment Variables

### Required:
- `ARTIFACTORY_ADMIN_PASSWORD` - Artifactory admin password
- `SAML_CERTIFICATE` - X.509 certificate from Keycloak (no BEGIN/END lines)

### Optional:
- `ARTIFACTORY_URL` - Default: `https://artifactory.local`
- `ARTIFACTORY_ADMIN_USER` - Default: `admin`
- `KEYCLOAK_SAML_URL` - Default: `https://keycloak.local/realms/master/protocol/saml`
- `KEYCLOAK_URL` - Default: `https://keycloak.local` (for cert extraction)
- `REALM` - Default: `master` (for cert extraction)

## Configuration Details

The script sends the following SAML configuration:

```json
{
  "name": "default",
  "enable_integration": true,
  "login_url": "https://keycloak.local/realms/master/protocol/saml",
  "logout_url": "https://keycloak.local/realms/master/protocol/saml",
  "service_provider_name": "https://keycloak.local/realms/master",
  "certificate": "...",
  "auto_user_creation": true,
  "allow_user_to_access_profile": true,
  "use_encrypted_assertion": false,
  "auto_redirect": false,
  "sync_groups": true,
  "group_attribute": "groups",
  "email_attribute": "email",
  "name_id_attribute": "username"
}
```

## Troubleshooting

### Certificate extraction fails
```bash
# Check if Keycloak is accessible
curl -k https://keycloak.local/realms/master/protocol/saml/descriptor

# If using different realm
REALM=myrealm ./get-keycloak-saml-cert.sh
```

### API returns 405 or 403
- Check if Artifactory is Pro/Enterprise (OSS doesn't support SAML)
- Verify admin credentials
- Check Artifactory license

### API returns 400 Bad Request
- Verify certificate format (no spaces, no BEGIN/END lines)
- Check JSON payload in temp file (printed in output)
- Ensure all URLs are correct

### Verify current configuration
```bash
curl -k -u admin:password \
  https://artifactory.local/artifactory/api/saml/config | jq
```

## Example: Complete Setup

```bash
# 1. Get certificate
CERT=$(./get-keycloak-saml-cert.sh | grep -A1 "Certificate" | tail -1)

# 2. Configure SAML
SAML_CERTIFICATE="$CERT" \
ARTIFACTORY_ADMIN_PASSWORD='Admin123!' \
./configure-artifactory-saml.sh

# 3. Verify
curl -k -u admin:Admin123! \
  https://artifactory.local/artifactory/api/saml/config | jq .enable_integration
```

## Notes

- Works with both DNS names and IP:PORT
- Supports self-signed certificates (`-k` flag)
- Automatically validates response
- Saves request payload to temp file for debugging
- Compatible with Artifactory Pro and Enterprise only
