# Security Center SAML Ansible Configuration Updates

## Overview

Updated Ansible configuration files to match the exact specifications from the Confluence guide:
**`docs/TENABLE_SC_SAML_CONFIGURATION_GUIDE.md`**

---

## Files Updated

### 1. **`roles/keycloak_saml_integration/vars/apps/securitycenter.yml`**

#### Key Changes:

**Client ID:**
- Changed from: `https://tennable.sc` (typo)
- Changed to: `https://tenable.sc` ✅ (Per Section 3.1)

**Hostname:**
- Changed from: `securitycenter.local`
- Changed to: `tenable.local` ✅ (Per Section 3.2)

**Protocol Mappers:**
- Removed: `firstName` and `lastName` mappers
- Kept: `email` and `username` mappers only ✅ (Per Section 7)
- Updated `username` mapper to use `email` property (Per Section 7.2)
- Changed Name Format from `Basic` to `Unspecified` ✅ (Per Section 7)

**SAML Capabilities:**
- Added explicit canonicalization method: `Exclusive` ✅ (Per Section 5)
- Confirmed Force POST Binding: `ON` ✅ (Per Section 4)
- Confirmed Include AuthnStatement: `ON` ✅ (Per Section 4)

**Signature Settings:**
- Sign Assertions: `ON` ✅ (Per Section 5)
- Sign Documents: `OFF` ✅ (Per Section 5)
- Signature Algorithm: `RSA_SHA256` ✅ (Per Section 5)
- Encrypt Assertions: `OFF` ✅ (Per Section 5)

**Advanced Configuration:**
- Added SOAP binding URL for logout ✅ (Per Section 8)

---

### 2. **`roles/keycloak_saml_integration/defaults/main.yml`**

#### Test User Configuration:

Changed test user to match Confluence Guide Section 9:

```yaml
username: "demo.user"          # Keycloak login
email: "demo@dns.com"         # SAML NameID & username attribute
first_name: "demo"
last_name: "user"
email_verified: true          # Added
```

**Mapping Logic:**
- Keycloak login: `demo.user`
- SAML NameID: `demo@dns.com`
- SAML username attribute: `demo@dns.com`
- Tenable username: `demo@dns.com`

---

### 3. **`inventory`**

Updated hostname:
```ini
[securitycenter_servers]
tenable.local ansible_host=192.168.56.10
```

---

### 4. **`group_vars/all/main.yml`**

Updated site_backends:
```yaml
- server_name: "tenable.local"
  ip: "192.168.56.10"
  port: "443"
```

---

### 5. **`group_vars/all/saml_integration.yml`**

Added comment referencing Confluence guide for clarity.

---

## Configuration Summary

The Ansible playbook will now create a Keycloak SAML client with these exact specifications:

### Client Configuration

| Setting | Value |
|---------|-------|
| Client ID | `https://tenable.sc` |
| Client Type | SAML |
| Root URL | `https://tenable.local` |
| Valid Redirect URIs | `https://tenable.local/saml/module.php/saml/sp/saml2-acs.php/1` |
| Name ID Format | Email |
| Force POST Binding | ON |
| Include AuthnStatement | ON |
| Sign Assertions | ON |
| Signature Algorithm | RSA_SHA256 |
| Front Channel Logout | ON |

### Protocol Mappers

| Mapper Name | Type | Property | SAML Attribute | Name Format |
|-------------|------|----------|----------------|-------------|
| email | User Property | email | email | Unspecified |
| username | User Property | email | username | Unspecified |

### Test User

| Field | Value |
|-------|-------|
| Keycloak Username | demo.user |
| Email | demo@dns.com |
| First Name | demo |
| Last Name | user |
| Email Verified | true |

---

## How to Deploy

### 1. Delete Existing Client (if any)

```bash
ansible keycloak -i inventory -m shell -a \
  "cd /opt/keycloak && \
   bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password 'Keycloak@2025' && \
   bin/kcadm.sh get clients -r master -q clientId='https://tenable.sc' --fields id | grep '\"id\"' | cut -d'\"' -f4 | \
   xargs -I {} bin/kcadm.sh delete clients/{} -r master" -b
```

### 2. Run Ansible Playbook

```bash
ansible-playbook playbooks/configure-keycloak-saml-integration.yml \
  -i inventory \
  -e "app=securitycenter" \
  -e "skip_client_roles=true" \
  --ask-vault-pass
```

Enter vault password: `techno2009`

### 3. Verify Configuration

```bash
# Check client exists
ansible keycloak -i inventory -m shell -a \
  "cd /opt/keycloak && \
   bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password 'Keycloak@2025' && \
   bin/kcadm.sh get clients -r master -q clientId='https://tenable.sc' --fields clientId,redirectUris" -b

# Check protocol mappers
ansible keycloak -i inventory -m shell -a \
  "cd /opt/keycloak && \
   CLIENT_ID=\$(bin/kcadm.sh get clients -r master -q clientId='https://tenable.sc' --fields id | grep '\"id\"' | cut -d'\"' -f4) && \
   bin/kcadm.sh get clients/\$CLIENT_ID/protocol-mappers/models -r master --fields name,protocolMapper" -b
```

---

## Expected Output

After running the playbook, you should see:

✅ SAML client created: `https://tenable.sc`
✅ 2 protocol mappers: `email`, `username`
✅ Test user created: `demo.user` with email `demo@dns.com`
✅ No client scopes attached (prevents duplicate attributes)
✅ Configuration matches Confluence guide exactly

---

## Next Steps

After Ansible deployment is complete:

1. **Configure Tenable.sc** (Manual - via UI):
   - System → Configuration → SAML
   - Import Keycloak metadata or configure manually
   - Entity ID: `https://keycloak.local/realms/master`
   - Username Attribute: `email`

2. **Create Tenable User** (Manual - via UI):
   - Users → Create User
   - Authentication Type: SAML
   - Username: `demo@dns.com`
   - Email: `demo@dns.com`
   - Assign at least one role

3. **Test SAML Login**:
   - Click "Sign in using SAML"
   - Login with: `demo.user` / `demo123!`
   - Should redirect and authenticate successfully

---

## Troubleshooting

If issues occur, refer to:
- **Confluence Guide**: `docs/TENABLE_SC_SAML_CONFIGURATION_GUIDE.md` (Section 11)
- **Keycloak Metadata**: `https://keycloak.local/realms/master/protocol/saml/descriptor`

---

## References

- Source Configuration: `docs/TENABLE_SC_SAML_CONFIGURATION_GUIDE.md`
- Last Updated: 2026-01-13
