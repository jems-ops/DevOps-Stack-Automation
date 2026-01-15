# Test Scripts

## test-sc-saml-api.sh

Test script to verify Tenable Security Center SAML API connectivity and retrieve current SAML configuration.

### Prerequisites

- `curl` installed
- `jq` installed for JSON parsing
- Access to Tenable Security Center instance
- Valid admin credentials

### Usage

Basic usage with default URL (https://tenable.local):
```bash
SC_PASSWORD='your_admin_password' ./test-sc-saml-api.sh
```

Custom configuration:
```bash
SC_URL='https://securitycenter.example.com' \
SC_USERNAME='admin' \
SC_PASSWORD='your_password' \
./test-sc-saml-api.sh
```

### What it does

1. Authenticates to Security Center REST API
2. Retrieves current SAML configuration from `/rest/configSection/8/1`
3. Displays SAML settings in readable format
4. Logs out and closes session
5. Provides summary of SAML status

### Example Output

```
ℹ️  Testing Security Center SAML API
ℹ️  URL: https://tenable.local
ℹ️  Username: admin

ℹ️  Step 1: Authenticating to Security Center...
✅ Authentication successful
ℹ️  Session token: 1234567890abcdef1234...

ℹ️  Step 2: Retrieving SAML configuration...
✅ SAML configuration retrieved successfully

ℹ️  SAML Configuration:
{
  "name": "SAML",
  "description": "SAML SSO Integration with Keycloak",
  "samlEnabled": "true",
  "entityID": "https://keycloak.local/realms/master",
  "idp": "https://keycloak.local/realms/master",
  "usernameAttribute": "email",
  "singleSignOnService": "https://keycloak.local/realms/master/protocol/saml",
  "singleLogoutService": "https://keycloak.local/realms/master/protocol/saml",
  "hasCertificate": true
}

ℹ️  Step 3: Logging out...
✅ Session closed

ℹ️  === Test Summary ===
✅ SAML is ENABLED

ℹ️  Entity ID: https://keycloak.local/realms/master
ℹ️  Identity Provider: https://keycloak.local/realms/master
ℹ️  Username Attribute: email
ℹ️  SSO Service: https://keycloak.local/realms/master/protocol/saml
✅ Test completed successfully
```

### Troubleshooting

**SSL Certificate Errors**: The script uses `-k` flag to skip certificate verification. Remove this for production environments with valid certificates.

**Authentication Failed**: Verify credentials and ensure the admin account is not locked.

**Connection Refused**: Ensure Security Center is running and accessible at the specified URL.

**jq Command Not Found**: Install jq:
- macOS: `brew install jq`
- RHEL/CentOS: `sudo yum install jq`
- Ubuntu/Debian: `sudo apt-get install jq`
