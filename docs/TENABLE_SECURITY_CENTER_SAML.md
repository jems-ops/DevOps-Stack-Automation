# Tenable Security Center SAML Integration with Keycloak

This guide explains how to configure SAML SSO for Tenable Security Center using Keycloak as the Identity Provider.

## Prerequisites

- Tenable Security Center installed and accessible
- Keycloak server running and configured
- Valid Tenable Security Center license
- Network connectivity between Security Center and Keycloak

## Configuration Overview

The SAML configuration uses these exact URLs from Security Center metadata:

```yaml
Entity ID: https://tennable.sc
ACS URL: https://securitycenter.local/saml/module.php/saml/sp/saml2-acs.php/1
SLO URL: https://securitycenter.local/saml/module.php/saml/sp/saml2-logout.php/1
```

## Step 1: Configure Keycloak Client

Run the Ansible playbook to create the Keycloak SAML client:

```bash
ansible-playbook playbooks/configure-keycloak-saml-integration.yml \
  -i inventory \
  -e "app=securitycenter" \
  --ask-vault-pass
```

This will:
- Create a SAML client in Keycloak with ID: `https://tennable.sc`
- Configure redirect URIs to match Security Center's endpoints
- Set up protocol mappers for username, email, firstName, lastName
- Create test user and groups
- Generate configuration notes file

## Step 2: Configure Security Center

### Option A: Import Keycloak Metadata (Recommended)

1. Log into Security Center as admin: `https://securitycenter.local`
2. Navigate to: **Admin → Authentication → SAML**
3. Click "Import IDP Metadata"
4. Enter Keycloak metadata URL:
   ```
   https://keycloak.local/realms/master/protocol/saml/descriptor
   ```
5. Set Entity ID: `https://tennable.sc`
6. Save configuration

### Option B: Manual Configuration

1. Log into Security Center as admin
2. Navigate to: **Admin → Authentication → SAML**
3. Configure SAML settings:

   **Service Provider (SP) Settings:**
   - Entity ID: `https://tennable.sc`
   - ACS URL: `https://securitycenter.local/saml/module.php/saml/sp/saml2-acs.php/1`
   - SLO URL: `https://securitycenter.local/saml/module.php/saml/sp/saml2-logout.php/1`
   - Name ID Format: `email`

   **Identity Provider (IDP) Settings:**
   - IDP Entity ID: `https://keycloak.local/realms/master`
   - SSO Service URL: `https://keycloak.local/realms/master/protocol/saml`
   - SLO Service URL: `https://keycloak.local/realms/master/protocol/saml`
   - IDP Certificate: (paste certificate from Keycloak or use metadata import)

   **Attribute Mappings:**
   - Username: `username`
   - Email: `email`
   - First Name: `firstName`
   - Last Name: `lastName`

4. Save configuration

## Step 3: Test SAML Login

1. In Security Center, click "Test SAML Configuration"
2. You should be redirected to Keycloak login page
3. Log in with test user:
   - Username: `demo.user`
   - Password: `demo123!`
4. You should be redirected back to Security Center and logged in

## Troubleshooting

### Issue: Redirects to `/baseuser/dns/saml.php`

**Solution:** The Entity ID or ACS URL doesn't match. Verify:
- Keycloak Client ID is exactly: `https://tennable.sc`
- ACS URL in Keycloak includes the full path:
  ```
  https://securitycenter.local/saml/module.php/saml/sp/saml2-acs.php/1
  ```

### Issue: "Invalid SAML Response"

**Solution:** Certificate mismatch. Options:
1. Import Keycloak metadata (easiest)
2. Manually copy certificate from Keycloak realm settings
3. Check that Force POST Binding is enabled in Keycloak client

### Issue: User not authorized after SAML login

**Solution:** User doesn't have proper permissions:
1. Check user is in the correct group: `/devops/securitycenter-users`
2. Verify group mappings in Security Center
3. Grant appropriate role to the user

### View Logs

**Security Center:**
```bash
tail -f /opt/sc/support/logs/sc.log | grep -i saml
```

**Keycloak:**
```bash
tail -f /opt/keycloak/data/log/keycloak.log | grep -i saml
```

## Keycloak Client Configuration Summary

The playbook creates a client with these settings:

```yaml
Client ID: https://tennable.sc
Client Protocol: saml
Valid Redirect URIs:
  - https://securitycenter.local/*
  - https://securitycenter.local/saml/module.php/saml/sp/saml2-acs.php/*
Master SAML Processing URL: https://securitycenter.local/saml/module.php/saml/sp/saml2-acs.php/1
Force POST Binding: ON
Sign Assertions: ON
Include AuthnStatement: ON
Name ID Format: email
```

## Verification Steps

1. **Verify Keycloak client exists:**
   ```bash
   # SSH to Keycloak server
   /opt/keycloak/bin/kcadm.sh config credentials \
     --server http://localhost:8080 \
     --realm master \
     --user admin \
     --password 'YourPassword'

   /opt/keycloak/bin/kcadm.sh get clients -r master \
     --fields clientId,redirectUris | grep -A 5 "tennable.sc"
   ```

2. **Test metadata URL:**
   ```bash
   curl -k https://keycloak.local/realms/master/protocol/saml/descriptor
   ```

3. **Test Security Center accessibility:**
   ```bash
   curl -k -I https://securitycenter.local
   ```

## Additional Resources

- [Tenable Security Center SAML Documentation](https://docs.tenable.com/)
- [Keycloak SAML Documentation](https://www.keycloak.org/docs/latest/server_admin/#saml-clients)

## Support

If you encounter issues:
1. Check the configuration notes file generated by the playbook: `/tmp/securitycenter_saml_config_*.txt`
2. Review logs on both Security Center and Keycloak
3. Verify network connectivity and DNS resolution
4. Ensure all URLs use HTTPS with valid certificates
