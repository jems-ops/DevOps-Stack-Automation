# Tenable.sc SAML SSO Integration with Keycloak
## Manual Configuration Guide (Step-by-Step)

---

## Overview

This document describes how to configure SAML 2.0 SSO between Tenable.sc and Keycloak using manual configuration (not auto-provisioning).

- **IdP**: Keycloak
- **SP**: Tenable.sc
- **Authentication**: SAML 2.0
- **User Provisioning**: Disabled (manual user creation)

---

## 1. Tenable.sc – SAML Configuration

### 1.1 Navigate to SAML Settings

```
System → Configuration → SAML
```

---

### 1.2 General SAML Settings

| Field | Value |
|-------|-------|
| Source | Entry |
| Type | SAML 2.0 |
| Entity ID | `https://keycloak.local/realms/master` |
| Identity Provider (IdP) | `https://keycloak.local/realms/master` |
| Username Attribute | `email` |
| User Provisioning | OFF |

---

### 1.3 Identity Provider Endpoints

| Field | Value |
|-------|-------|
| Single Sign-On Service | `https://keycloak.local/realms/master/protocol/saml` |
| Single Logout Service | `https://keycloak.local/realms/master/protocol/saml` |

---

### 1.4 Certificate Configuration

1. **Open the Keycloak metadata URL:**
   ```
   https://keycloak.local/realms/master/protocol/saml/descriptor
   ```

2. **Copy the `<X509Certificate>` value:**
   ```xml
   <X509Certificate>
     xxxxxxxxxxxxxxxxxxxxxxxxx
   </X509Certificate>
   ```

3. **Paste the certificate** into the Certificate field in Tenable.sc.

---

### 1.5 Save Configuration

Click **Submit** to save the SAML configuration.

---

## 2. Tenable.sc – Create SAML User

### 2.1 Navigate to Users

```
Users → Create User
```

### 2.2 User Details

| Field | Value |
|-------|-------|
| Authentication Type | SAML |
| Username | `demo@dns.com` |
| Email | `demo@dns.com` |
| First Name | `demo` |
| Last Name | `user` |
| Enabled | Yes |

### 2.3 Roles

Assign at least one valid role (example):
- Security Manager
- Administrator
- Scan Operator

⚠️ **A user with no roles will fail login (Error 74).**

Save the user.

---

### 2.4 Download Tenable Metadata

From `System → Configuration → SAML`:
- Download the **Service Provider metadata XML**
- This file will be used when configuring Keycloak

---

## 3. Keycloak – SAML Client Configuration

### 3.1 Create Client

```
Clients → Create client
```

| Field | Value |
|-------|-------|
| Client type | SAML |
| Client ID | `https://tenable.sc` |
| Name | `tenable.sc` |

---

### 3.2 Client URLs

| Field | Value |
|-------|-------|
| Root URL | `https://tenable.local` |
| Home URL | `https://tenable.local` |
| Valid Redirect URIs | `https://tenable.local/saml/module.php/saml/sp/saml2-acs.php/1` |

⚠️ **Note**: Path must be `saml2-acs.php` (no typo).

---

## 4. Keycloak – SAML Capabilities

| Setting | Value |
|---------|-------|
| Name ID Format | Email |
| Force POST Binding | ON |
| Include AuthnStatement | ON |

---

## 5. Keycloak – Signature & Encryption

| Setting | Value |
|---------|-------|
| Sign Assertions | ON |
| Signature Algorithm | RSA_SHA256 |
| SAML Signature Key Name | NONE |
| Canonicalization Method | Exclusive |
| Encrypt Assertions | OFF |
| Sign Documents | OFF |

---

## 6. Keycloak – Logout Settings

| Setting | Value |
|---------|-------|
| Front Channel Logout | ON |

---

## 7. Keycloak – Attribute Mappers

Navigate to:
```
Clients → tenable.sc → Client Scopes (or Mappers)
```

### 7.1 Email Mapper

| Field | Value |
|-------|-------|
| Mapper Type | User Property |
| Name | `email` |
| Property | `email` |
| SAML Attribute Name | `email` |
| Name Format | Unspecified |

---

### 7.2 Username Mapper (Required)

| Field | Value |
|-------|-------|
| Mapper Type | User Property |
| Name | `username` |
| Property | `email` |
| SAML Attribute Name | `username` |
| Name Format | Unspecified |

⚠️ **Tenable.sc requires at least one AttributeStatement, not just NameID.**

---

## 8. Keycloak – Advanced Configuration

### Fine Grain SAML Endpoint Configuration

| Field | URL |
|-------|-----|
| Assertion Consumer Service POST Binding | `https://tenable.local/saml/module.php/saml/sp/saml2-acs.php/1` |
| Logout Service POST Binding URL | `https://tenable.local/saml/module.php/saml/sp/saml2-logout.php/1` |
| Logout Service SOAP Binding URL | `https://tenable.local/saml/module.php/saml/sp/saml2-logout.php/1` |

---

## 9. Keycloak – Create User

Navigate to:
```
Users → Add User
```

### 9.1 User Details

| Field | Value |
|-------|-------|
| Username | `demo.user` |
| Email | `demo@dns.com` |
| Email Verified | ON |
| First Name | `demo` |
| Last Name | `user` |
| Enabled | ON |

---

### 9.2 Set Password

1. Go to **Credentials** tab
2. Set a password
3. **Temporary** = OFF

---

## 10. Login Flow (Important)

### Correct Login Method

1. Go to Tenable.sc
2. Click **Sign in using SAML**
3. You are redirected to Keycloak
4. Login using:
   ```
   Username: demo.user
   Password: <Keycloak password>
   ```

### Mapping Logic

| System | Value |
|--------|-------|
| Keycloak login | `demo.user` |
| SAML NameID | `demo@dns.com` |
| SAML username attribute | `demo@dns.com` |
| Tenable username | `demo@dns.com` |

---

## 11. Validation Checklist

✅ Redirect from Tenable → Keycloak  
✅ Successful Keycloak login  
✅ SAML POST to `/saml2-acs.php/1`  
✅ No "no attribute detected" error  
✅ No "Error 74 – early login denied"  
✅ Tenable UI loads successfully  

---

## Notes / Common Issues

- **User must exist in Tenable.sc** (no auto-provisioning)
- **User must have at least one role**
- **Attribute names are case-sensitive**
- **Assertion must be signed, not encrypted**
- **NameID alone is not sufficient**

---

## Troubleshooting

### Issue: "No attribute detected"
**Solution**: Ensure at least one SAML attribute mapper is configured in Keycloak (username or email).

### Issue: "Error 74 – early login denied"
**Solution**: User exists in Tenable but has no roles assigned. Assign at least one role.

### Issue: Redirect loops
**Solution**: 
- Verify Entity ID matches exactly
- Check ACS URL path is correct: `/saml2-acs.php/1` (not `/saml-acs.php/1`)

### Issue: Certificate validation error
**Solution**: 
- Ensure certificate is copied correctly from Keycloak metadata
- Remove any extra whitespace or line breaks

---

## Quick Reference Commands

### Download Keycloak Metadata
```bash
curl -k -s https://keycloak.local/realms/master/protocol/saml/descriptor \
  -o keycloak-saml-metadata.xml
```

### Extract Certificate from Metadata
```bash
curl -k -s https://keycloak.local/realms/master/protocol/saml/descriptor | \
  sed -n 's/.*<ds:X509Certificate>\(.*\)<\/ds:X509Certificate>.*/\1/p' | head -1
```

### Verify Keycloak Endpoint
```bash
curl -k -I https://keycloak.local/realms/master/protocol/saml
```

---

## Architecture Diagram

```
┌─────────────┐         HTTPS/SAML        ┌──────────────┐
│             │ ───────────────────────►  │              │
│ Tenable.sc  │                           │   Keycloak   │
│     (SP)    │                           │    (IdP)     │
│             │ ◄─────────────────────── │              │
└─────────────┘    SAML Response         └──────────────┘
                   + Attributes
                   
User Flow:
1. User → Tenable.sc (click "Sign in using SAML")
2. Tenable.sc → Keycloak (SAML AuthnRequest)
3. User logs into Keycloak
4. Keycloak → Tenable.sc (SAML Response with attributes)
5. Tenable.sc validates & creates session
```

---

## Version Information

- **Tenable.sc Version**: 6.x
- **Keycloak Version**: 23.x+
- **SAML Version**: 2.0
- **Last Updated**: 2026-01-13

---

## References

- [Tenable.sc SAML Documentation](https://docs.tenable.com/)
- [Keycloak SAML Documentation](https://www.keycloak.org/docs/latest/server_admin/#saml-clients)

---

✅ **End of Document**
