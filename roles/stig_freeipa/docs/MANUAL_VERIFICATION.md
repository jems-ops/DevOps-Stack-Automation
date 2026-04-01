## Manual Logs

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

---

## V-222998 — Changes to Tomcat bin/ Folder Must Be Logged

**Severity:** CAT II
**SRG:** SRG-APP-000504-AS-000229

**Finding Details:**
If audit rules do not include monitoring of the Tomcat bin directory (`-w <path>/bin -p wa -k tomcat`), modifications to startup and control scripts will not be logged. This prevents detection of unauthorized execution changes, persistence mechanisms, or tampering with service control scripts.

**Comments:**
The bin directory contains critical execution scripts (startup/shutdown). Audit rules are applied to the resolved (non-symlink) path to ensure accurate monitoring in FreeIPA/PKI environments. Persistent rules are configured under `/etc/audit/rules.d/` and loaded using `augenrules`.

> **Note:** FreeIPA PKI Tomcat uses symlinks. Audit rules must target the
> resolved (real) path since auditd monitors actual filesystem objects.

```bash
# Step 1: Resolve the real path for Tomcat bin (follows symlinks)
BIN_PATH=$(readlink -f /var/lib/pki/pki-tomcat/bin 2>/dev/null || readlink -f /usr/share/tomcat/bin 2>/dev/null)
echo "Resolved bin path: $BIN_PATH"
# Expected: /usr/share/tomcat/bin

# Step 2: Verify the resolved directory exists
ls -ld "$BIN_PATH"
# Expected: directory exists

# Step 3: Check persistent audit rule targets the real path
cat /etc/audit/rules.d/tomcat.rules 2>/dev/null | grep bin
# Expected: -w /usr/share/tomcat/bin -p wa -k tomcat

# Step 4: Check active audit rules
auditctl -l | grep bin | grep tomcat
# Expected: -w /usr/share/tomcat/bin -p wa -k tomcat

# Verify the symlink chain
ls -la /var/lib/pki/pki-tomcat/bin
# Expected: lrwxrwxrwx ... /var/lib/pki/pki-tomcat/bin -> /usr/share/tomcat/bin
```

**Pass criteria:** Audit rule exists for the resolved real path of Tomcat bin with `-p wa -k tomcat` flags.

---

## V-222999 — Changes to Tomcat conf/ Folder Must Be Logged

**Severity:** CAT II
**SRG:** SRG-APP-000504-AS-000229

**Finding Details:**
If audit rules do not include monitoring of the Tomcat conf directory (`-w <path>/conf -p wa -k tomcat`), configuration changes will not be captured. This allows unauthorized modifications to server behavior, authentication settings, and security controls without audit visibility.

**Comments:**
The conf directory contains critical configuration files (e.g., `server.xml`, `web.xml`). In FreeIPA environments, this path is typically resolved to `/etc/pki/pki-tomcat`. Audit rules ensure traceability of configuration changes for compliance and forensic analysis.

> **Note:** FreeIPA PKI Tomcat `conf/` symlinks to `/etc/pki/pki-tomcat`.
> The resolved path is already the real directory.

```bash
# Step 1: Resolve the real path for Tomcat conf
CONF_PATH=$(readlink -f /var/lib/pki/pki-tomcat/conf 2>/dev/null || readlink -f /etc/pki/pki-tomcat 2>/dev/null)
echo "Resolved conf path: $CONF_PATH"
# Expected: /etc/pki/pki-tomcat

# Step 2: Verify the resolved directory exists
ls -ld "$CONF_PATH"
# Expected: directory exists, contains ca/, Catalina/, server.xml, etc.

# Step 3: Check persistent audit rule targets the real path
cat /etc/audit/rules.d/tomcat.rules 2>/dev/null | grep conf
# Expected: -w /etc/pki/pki-tomcat -p wa -k tomcat

# Step 4: Check active audit rules
auditctl -l | grep conf | grep tomcat
# Expected: -w /etc/pki/pki-tomcat -p wa -k tomcat

# Verify the symlink chain
ls -la /var/lib/pki/pki-tomcat/conf
# Expected: lrwxrwxrwx ... /var/lib/pki/pki-tomcat/conf -> /etc/pki/pki-tomcat
```

**Pass criteria:** Audit rule exists for the resolved real path of Tomcat conf with `-p wa -k tomcat` flags.

---

## V-223000 — Changes to Tomcat lib/ Folder Must Be Logged

**Severity:** CAT II
**SRG:** SRG-APP-000504-AS-000229

**Finding Details:**
If audit rules do not include monitoring of the Tomcat lib directory (`-w <path>/lib -p wa -k tomcat`), changes to Java libraries (JAR files) will not be logged. This introduces risk of malicious code injection or unauthorized modification of application components without detection.

**Comments:**
The lib directory contains application libraries and runtime dependencies. In FreeIPA environments, this path is commonly resolved to `/usr/share/pki/server/lib`. Audit rules ensure integrity monitoring of executable components and support detection of tampering.

> **Note:** FreeIPA PKI Tomcat `lib/` symlinks to `/usr/share/pki/server/lib`.

```bash
# Step 1: Resolve the real path for Tomcat lib
LIB_PATH=$(readlink -f /var/lib/pki/pki-tomcat/lib 2>/dev/null || readlink -f /usr/share/pki/server/lib 2>/dev/null)
echo "Resolved lib path: $LIB_PATH"
# Expected: /usr/share/pki/server/lib

# Step 2: Verify the resolved directory exists
ls -ld "$LIB_PATH"
# Expected: directory exists, contains jar files

# Step 3: Check persistent audit rule targets the real path
cat /etc/audit/rules.d/tomcat.rules 2>/dev/null | grep lib
# Expected: -w /usr/share/pki/server/lib -p wa -k tomcat

# Step 4: Check active audit rules
auditctl -l | grep lib | grep tomcat
# Expected: -w /usr/share/pki/server/lib -p wa -k tomcat

# Verify the symlink chain
ls -la /var/lib/pki/pki-tomcat/lib
# Expected: lrwxrwxrwx ... /var/lib/pki/pki-tomcat/lib -> /usr/share/pki/server/lib
```

**Pass criteria:** Audit rule exists for the resolved real path of Tomcat lib with `-p wa -k tomcat` flags.
