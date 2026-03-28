# FreeIPA STIG Manual Verification Guide

SSH into the FreeIPA server to run these commands:

```bash
ssh vagrant@192.168.56.14
```

---

## V-264341 — Web Server Must Generate Audit Records

**Severity:** CAT II
**SRG:** SRG-APP-000805

```bash
# Check CustomLog directive
grep -i '^CustomLog' /etc/httpd/conf/httpd.conf
# Expected: CustomLog "/var/log/httpd/access_log" combined

# Check ErrorLog directive
grep -i '^ErrorLog' /etc/httpd/conf/httpd.conf
# Expected: ErrorLog "/var/log/httpd/error_log"

# Verify log files exist and have content
ls -la /var/log/httpd/access_log /var/log/httpd/error_log
# Expected: both files exist with non-zero size

# Verify auditd is running
systemctl is-active auditd
# Expected: active

# Verify PKI Tomcat logs exist
ls -ld /var/log/pki/pki-tomcat
# Expected: directory exists, owned by pkiuser
```

**Pass criteria:** All log directives present, log files exist, auditd active, Tomcat log directory present.

---

## V-206412 — Minimize Web Server Identity in Headers

**Severity:** CAT II
**SRG:** SRG-APP-000266-WSR-000159

```bash
# Check ServerTokens and ServerSignature
grep -E '^ServerTokens|^ServerSignature' /etc/httpd/conf/httpd.conf
# Expected:
#   ServerTokens Prod
#   ServerSignature Off

# Verify security.conf exists with header hardening
cat /etc/httpd/conf.d/security.conf
# Expected: ServerTokens Prod, ServerSignature Off, Header always set Server "Apache"

# Verify mod_headers is loaded
httpd -M | grep headers_module
# Expected: headers_module (shared)

# Test actual response header
curl -k -I https://localhost
# Expected: "Server: Apache" (no version number like "Apache/2.4.x")
```

**Pass criteria:** Server header shows only "Apache" with no version, OS, or module info.

---

## V-206433 — Tune Web Server to Prevent DoS

**Severity:** CAT II
**SRG:** SRG-APP-000516-WSR-000174

```bash
# Check Apache tuning config
cat /etc/httpd/conf.d/tuning.conf
# Expected:
#   ServerLimit 150
#   MaxRequestWorkers 150
#   Timeout 60
#   KeepAlive On
#   KeepAliveTimeout 30

# Check OS file descriptor limits
ulimit -n
# Expected: 65536

# Check limits config
cat /etc/security/limits.d/99-freeipa.conf
# Expected:
#   * soft nofile 65536
#   * hard nofile 65536

# Check systemd limits
grep DefaultLimitNOFILE /etc/systemd/system.conf
# Expected: DefaultLimitNOFILE=65536

# Check LDAP tuning (389-DS)
grep nsslapd-maxdescriptors /etc/dirsrv/slapd-*/dse.ldif
# Expected: nsslapd-maxdescriptors: 65536
```

**Pass criteria:** Apache tuned, OS limits >= 65536, systemd aligned, LDAP descriptors set.

---

## V-206437 — Protect Cookies with HttpOnly and Secure Flags

**Severity:** CAT II
**SRG:** SRG-APP-000439-WSR-000154

```bash
# Check cookie_security.conf exists and has directive
cat /etc/httpd/conf.d/cookie_security.conf
# Expected: Header always edit Set-Cookie ^(.*)$ "$1; HttpOnly; Secure"

# Check ipa.conf also has the directive
grep -i 'Header always edit Set-Cookie' /etc/httpd/conf.d/ipa.conf
# Expected: Header always edit Set-Cookie line present

# Verify mod_headers is loaded
httpd -M | grep headers_module
# Expected: headers_module (shared)

# Runtime check (Dogtag CA sets cookies)
curl -k -s -D - -o /dev/null https://localhost:8443/ca/ee/ca | grep -i Set-Cookie
# Expected: Set-Cookie line includes HttpOnly and Secure
```

**Pass criteria:** Config directive present in cookie_security.conf and ipa.conf; runtime cookies include HttpOnly and Secure flags.

---

## V-206374 — Web Server Must Not Perform Local User Management

**Severity:** CAT II
**SRG:** SRG-APP-000141-WSR-000015

```bash
# Check .ht* files are blocked (should return 403)
curl -k -s -o /dev/null -w "%{http_code}" https://localhost/.htaccess
# Expected: 403

curl -k -s -o /dev/null -w "%{http_code}" https://localhost/.htpasswd
# Expected: 403

# Verify no AuthUserFile directives in config
grep -Ri "^[^#]*AuthUserFile" /etc/httpd/conf/ /etc/httpd/conf.d/ 2>/dev/null
# Expected: no output (empty)

# Verify the deny block exists in httpd.conf
grep -A2 'Files ".ht\*"' /etc/httpd/conf/httpd.conf
# Expected:
#   <Files ".ht*">
#       Require all denied
#   </Files>
```

**Pass criteria:** HTTP 403 for .ht* files, no AuthUserFile directives present.

---

## V-206380 — Disable MIME Types That Invoke OS Shell Programs

**Severity:** CAT II
**SRG:** SRG-APP-000141-WSR-000081

```bash
# Check for active ExecCGI directives (uncommented lines only)
grep -RInI "^[^#]*ExecCGI" /etc/httpd/conf /etc/httpd/conf.d
# Expected: no output (empty)

# Check for CGI script handlers
grep -RInI "^[^#]*cgi-script" /etc/httpd/conf /etc/httpd/conf.d
# Expected: no output (empty)

# Check for executable MIME type mappings
grep -RInI "application/x-httpd-cgi" /etc/httpd/conf /etc/httpd/conf.d
# Expected: no output (empty)
```

**Pass criteria:** No ExecCGI, no cgi-script handlers, no executable MIME type mappings in active config.

---

## V-206383 — Web Server Must Have WebDAV Disabled

**Severity:** CAT II
**SRG:** SRG-APP-000141-WSR-000075

```bash
# Check DAV modules are commented out
cat /etc/httpd/conf.modules.d/00-dav.conf
# Expected: all LoadModule lines commented (prefixed with #)

# Verify no DAV modules loaded
httpd -M | grep -i dav
# Expected: no output (empty)

# Check no active DAV directives in config
grep -Ri "^[^#]*DAV" /etc/httpd/ --include='*.conf'
# Expected: no output (empty)

# Test HTTP OPTIONS for WebDAV methods
curl -k -X OPTIONS https://localhost -i 2>/dev/null | grep -i "DAV:"
# Expected: no output (no DAV header exposed)
```

**Pass criteria:** DAV modules not loaded, no DAV directives, no DAV methods in HTTP OPTIONS response.
