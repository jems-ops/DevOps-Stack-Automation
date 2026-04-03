# FreeIPA UI Fix — Manual Recovery Guide

After STIG hardening, the FreeIPA web UI may break due to three enforcement
directives that conflict with FreeIPA's Apache configuration. This guide
covers manual recovery steps.

## Symptoms and Fixes

### 1. White/Blank Page (ExecCGI stripped)

**Cause:** V-206380 strips `Options ExecCGI` from all configs including `ipa.conf`,
disabling the WSGI handler for `/usr/share/ipa/wsgi/plugins.py`.

**Verify:**
```bash
grep -A5 'Directory "/usr/share/ipa/wsgi"' /etc/httpd/conf.d/ipa.conf | grep Options
# If output shows "Options" with nothing after it → broken
```

**Fix:**
```bash
sed -i 's/^\(\s*Options\)\s*$/\1 ExecCGI/' /etc/httpd/conf.d/ipa.conf
```

---

### 2. "Forbidden" Dialog (WSGI access denied)

**Cause:** V-206374 enforces `<Directory /> Require all denied` which blocks
filesystem access to `/usr/share/ipa/wsgi.py` (the IPA JSON-RPC API).

**Verify:**
```bash
test -f /etc/httpd/conf.d/ipa-stig-exception.conf && echo "EXISTS" || echo "MISSING"
```

**Fix:**
```bash
cat > /etc/httpd/conf.d/ipa-stig-exception.conf << 'EOF'
# STIG Exception: FreeIPA WSGI Application Access
<Directory "/usr/share/ipa">
    Require all granted
</Directory>
EOF
```

---

### 3. Login Returns 401 (AuthType/Require stripped)

**Cause:** V-206374 strips `AuthType` and `Require valid-user` from all configs.
FreeIPA needs `AuthType GSSAPI` and `Require valid-user` inside the
`<Location "/ipa">` block for Kerberos and password authentication.

**Verify:**
```bash
grep -n 'AuthType GSSAPI' /etc/httpd/conf.d/ipa.conf
grep -n 'Require valid-user' /etc/httpd/conf.d/ipa.conf
# Both should exist inside the <Location "/ipa"> block (around lines 65-85)
# If missing or at the very end of file → broken
```

**Fix (insert at correct location):**
```bash
# Remove any wrongly appended lines at end of file first
sed -i '/^  AuthType GSSAPI$/d; /^  Require valid-user$/d' /etc/httpd/conf.d/ipa.conf

# Insert at correct locations
sed -i '/AuthName "Kerberos Login"/a\  AuthType GSSAPI' /etc/httpd/conf.d/ipa.conf
sed -i '/GssapiUseS4U2Proxy/a\  Require valid-user' /etc/httpd/conf.d/ipa.conf
```

---

### 4. 500 Internal Server Error (duplicate Set-Cookie headers)

**Cause:** Multiple `Header always edit Set-Cookie` directives in `ssl.conf`,
`ipa.conf`, and `cookie_security.conf` cascade and corrupt cookies, causing
a `TypeError` in the WSGI app.

**Verify:**
```bash
grep -rc 'Header.*Set-Cookie' /etc/httpd/conf.d/*.conf
# If cookie_security.conf exists or ssl.conf has Set-Cookie → duplicates
```

**Fix:**
```bash
rm -f /etc/httpd/conf.d/cookie_security.conf
sed -i '/^Header always edit Set-Cookie/d' /etc/httpd/conf.d/ssl.conf
```

---

## Apply and Verify

```bash
systemctl restart httpd

# Test UI
curl -sk -o /dev/null -w '%{http_code}\n' https://$(hostname -f)/ipa/ui/
# Expected: 200

# Test login
curl -sk -o /dev/null -w '%{http_code}\n' -X POST \
  "https://$(hostname -f)/ipa/session/login_password" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H "Referer: https://$(hostname -f)/ipa/ui/" \
  --data-urlencode 'user=admin' \
  --data-urlencode 'password=<ADMIN_PASSWORD>'
# Expected: 200

# Test plugins endpoint
curl -sk -o /dev/null -w '%{http_code}\n' https://$(hostname -f)/ipa/wsgi/plugins.py
# Expected: 200
```

## Prevention

The playbook now handles all of the above automatically:
- `ipa.conf` is excluded from ExecCGI, AuthType, and Require valid-user stripping
- WSGI exception file is deployed idempotently
- Duplicate cookie headers are removed when `ipa.conf` already handles cookies
- Anchor checks prevent directives from being appended to end of file
