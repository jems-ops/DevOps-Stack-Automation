## Manual Verification Steps

> **Note on DNS service name:** FreeIPA may run DNS as `named` or `named-pkcs11` depending on
> the installation. Auto-detected at runtime via:
> ```bash
> DNS_SVC=$(systemctl list-units --type=service --state=running | grep -oE 'named[a-z0-9-]*\.service' | head -1 | sed 's/\.service//')
> echo "DNS service: $DNS_SVC"
> ```
> Replace `named` in commands below with the detected service name if different.

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

---

## V-205157 — Limit Zone Transfers to Authorized Secondary Servers

**Severity:** CAT II
**SRG:** SRG-APP-000001-DNS-000001

```bash
# Verify named service is running
systemctl is-active named
# Expected: active

# List all DNS zones managed by FreeIPA
ipa dnszone-find --all --raw | grep 'idnsname:'
# Expected: lists zones (e.g. freeipa.local., reverse zone)

# Check zone transfer ACL for each zone
ipa dnszone-show freeipa.local. --all --raw | grep -Ei 'idnsallowtransfer'
# Expected: idnsallowtransfer: none; (or specific authorized IPs)

# Verify no wildcard/unrestricted transfers
ipa dnszone-show freeipa.local. --all --raw | grep -i 'any'
# Expected: no output (no "any" in transfer ACL)
```

**Pass criteria:** All zones have `idnsallowtransfer` set to `none;` or specific authorized secondary server IPs. No wildcard (`any`) transfers allowed.

---

## V-205158 — Limit Dynamic Update Clients via GSS-TSIG

**Severity:** CAT II
**SRG:** SRG-APP-000001-DNS-000115

```bash
# Verify named service is running
systemctl is-active named
# Expected: active

# Check FreeIPA zone update-policy (LDAP-backed)
ipa dnszone-show freeipa.local. --all --raw | grep -Ei 'idnsupdatepolicy|idnsallowdynupdate'
# Expected:
#   idnsupdatepolicy: grant FREEIPA.LOCAL krb5-self * A; grant FREEIPA.LOCAL krb5-self * AAAA; grant FREEIPA.LOCAL krb5-self * SSHFP;
#   idnsallowdynupdate: TRUE

# Verify krb5-self enforcement is present
ipa dnszone-show freeipa.local. --all --raw | grep 'krb5-self'
# Expected: one or more grant lines with krb5-self

# Confirm no anonymous update policies
ipa dnszone-show freeipa.local. --all --raw | grep -i 'grant.*any'
# Expected: no output (no anonymous grants)
```

**Pass criteria:** `idnsupdatepolicy` contains `krb5-self` grants restricting updates to Kerberos-authenticated hosts only. No anonymous or wildcard update grants present.

---

## V-205160 — DNS Audit Record Generation for DoD-Defined Events

**Severity:** CAT II
**SRG:** SRG-APP-000089-DNS-000005

```bash
# Verify named service is running
systemctl is-active named
# Expected: active

# Check for RNDC (privileged command) log entries
grep -Ei 'rndc|reload|stop|start' /var/named/data/named.run /var/log/* 2>/dev/null | head -n 10
# Expected: log entries showing RNDC administrative actions

# Check for denied/failed/unauthorized event logs
grep -Ei 'denied|failed|unauthorized|refused' /var/log/* 2>/dev/null | head -n 10
# Expected: log entries capturing failure/denial events

# Check journald for service lifecycle events
journalctl -u $DNS_SVC --no-pager | grep -Ei 'listening|no longer listening|shutting|loading' | tail -n 10
# Expected: lifecycle events logged with timestamps
```

**Pass criteria:** RNDC privileged actions are logged, failure/denial events are captured, and service lifecycle events appear in journald or system logs.

---

## V-205161 — DNS Audit Records Must Contain Event Type Information

**Severity:** CAT II
**SRG:** SRG-APP-000095-DNS-000006

```bash
# Detect DNS service name
DNS_SVC=$(systemctl list-units --type=service --state=running | grep -oE 'named[a-z0-9-]*\.service' | head -1 | sed 's/\.service//')

# Verify DNS service is running
systemctl is-active $DNS_SVC
# Expected: active

# Check print-category and print-severity are enabled
named-checkconf -p 2>/dev/null | grep -E 'print-category|print-severity'
# Expected:
#   print-category yes;
#   print-severity yes;

# Check logging channels and categories are defined
named-checkconf -p 2>/dev/null | grep -E 'channel|category'
# Expected: multiple channel and category definitions

# Verify structured log files exist with event data
ls -la /var/named/data/named.run /var/log/named*.log 2>/dev/null
# Expected: log files exist with recent timestamps
```

**Pass criteria:** `print-category` and `print-severity` are enabled, logging channels and categories are defined, and log files contain structured event type information.

---

## V-205224 — Audit Records for Named Service Start/Stop Events

**Severity:** CAT II
**SRG:** SRG-APP-000504-DNS-000074

```bash
# Detect DNS service name
DNS_SVC=$(systemctl list-units --type=service --state=running | grep -oE 'named[a-z0-9-]*\.service' | head -1 | sed 's/\.service//')

# Verify DNS service is running
systemctl is-active $DNS_SVC
# Expected: active

# Check journald for BIND lifecycle events
journalctl -u $DNS_SVC --no-pager | grep -Ei 'start|stop|starting|stopping|listening|no longer listening|shutting|running|loading' | tail -n 20
# Expected: log entries showing service lifecycle events

# Verify systemd tracks the service unit
systemctl show $DNS_SVC --property=ActiveState,SubState,ExecMainStartTimestamp
# Expected: ActiveState=active, SubState=running, with a valid start timestamp
```

**Pass criteria:** Journald contains BIND lifecycle events and systemd tracks the DNS service with valid state information.

---

## V-205225 — DNSSEC FIPS-Validated Cryptographic Modules

**Severity:** CAT II
**SRG:** SRG-APP-000504-DNS-000082

```bash
# Check if DNSSEC is configured
grep -Ei 'dnssec-enable[[:space:]]*yes|inline-signing[[:space:]]*yes|auto-dnssec' /etc/named.conf
# Expected: no output (DNSSEC not enabled → NOT APPLICABLE)

# If DNSSEC were enabled, verify FIPS-approved algorithms in signing policy
grep -Ei 'RSASHA256|RSASHA512|ECDSAP256SHA256|ECDSAP384SHA384' /etc/named.conf /var/named/*.conf 2>/dev/null
# Expected: only FIPS-approved algorithms listed

# Check OS FIPS mode
cat /proc/sys/crypto/fips_enabled
# Expected: 1 (if FIPS required)
```

**Pass criteria:** DNSSEC not enabled → NOT APPLICABLE. If enabled, only RSASHA256/ECDSA algorithms used and OS FIPS mode is active.

---

## V-205227 — NSEC3 Salt Rotation

**Severity:** CAT II
**SRG:** SRG-APP-000516-DNS-000077

```bash
# Check if DNSSEC/NSEC3 is configured
grep -Ei 'nsec3|auto-dnssec|inline-signing' /etc/named.conf /var/named/*.conf 2>/dev/null
# Expected: no output (DNSSEC not enabled → NOT APPLICABLE)

# If NSEC3 were in use, verify salt rotation policy
# Check current NSEC3 parameters for each signed zone
dig +short NSEC3PARAM <zone>.
# Expected: NSEC3PARAM record with salt field present
```

**Pass criteria:** DNSSEC/NSEC3 not enabled → NOT APPLICABLE. If enabled, salt must be rotated on every complete zone re-signing.

---

## V-205228 — RRSIG Validity Period (2–7 Days)

**Severity:** CAT II
**SRG:** SRG-APP-000516-DNS-000078

```bash
# Check if DNSSEC is active
grep -cEi 'dnssec-enable[[:space:]]*yes|inline-signing[[:space:]]*yes|auto-dnssec' /etc/named.conf
# Expected: 0 (DNSSEC not configured → NOT APPLICABLE)

# Check for signed zone files
find /var/named -maxdepth 2 \( -name '*.db' -o -name '*.zone' \) | xargs grep -l 'RRSIG' 2>/dev/null
# Expected: no output (no signed zones)

# If DNSSEC were enabled, check RRSIG validity window
zone="freeipa.local."
dig +short +dnssec @localhost DNSKEY "$zone" | awk '/RRSIG/ {print $5, $6}'
# Output: <expiry_YYYYMMDDHHMMSS> <inception_YYYYMMDDHHMMSS>
# Calculate days: (expiry_epoch - inception_epoch) / 86400
# Expected: 2 ≤ validity_days ≤ 7
```

**Pass criteria:** DNSSEC disabled → NOT APPLICABLE. If enabled: RRSIG validity window must be ≥ 2 days and ≤ 7 days.

---

## V-205230 — NS Records Point to Active Authoritative Servers

**Severity:** CAT II
**SRG:** SRG-APP-000516-DNS-000085

```bash
# Get NS records for the domain
dig +short NS freeipa.local.
# Expected: ipa.freeipa.local. (or configured NS)

# Resolve each NS to an IP
dig +short A ipa.freeipa.local.
# Expected: IP address (e.g. 192.168.56.14)

# Verify each NS responds authoritatively (SOA)
dig @ipa.freeipa.local. +short SOA freeipa.local.
# Expected: SOA record returned

# Confirm NS is listed in zone
ipa dnsrecord-find freeipa.local. --type=NS
# Expected: NS record pointing to ipa.freeipa.local.
```

**Pass criteria:** All NS records resolve to an IP, each NS responds with a valid SOA for the zone.

---

## V-205231 — DNSSEC Key File Permissions

**Severity:** CAT II
**SRG:** SRG-APP-000516-DNS-000086

```bash
# Check for DNSSEC key files
find /var/named -type f \( -name '*.key' -o -name '*.private' \)
# Expected: no output (DNSSEC not enabled → NOT APPLICABLE)

# If key files exist, verify permissions and ownership
find /var/named -type f \( -name '*.key' -o -name '*.private' \) -exec stat -c "%n %a %U:%G" {} \;
# Expected: mode 640 or 600, owned by root:named
```

**Pass criteria:** No DNSSEC keys present → NOT APPLICABLE. If present, all key files must be mode ≤ 640 owned by root:named.

---

## V-205233 — DNS Configuration Consistency (Single NS)

**Severity:** CAT II
**SRG:** SRG-APP-000516-DNS-000087

```bash
# Count authoritative name servers
dig +short NS freeipa.local. | wc -l
# Expected: 1 (single NS → NOT A FINDING)
# If > 1: verify zone replication is consistent across all NS

# If multiple NS, compare SOA serial across all
for ns in $(dig +short NS freeipa.local.); do
  echo "$ns: $(dig @$ns +short SOA freeipa.local. | awk '{print $3}')"
done
# Expected: all SOA serials match
```

**Pass criteria:** Single authoritative NS → NOT A FINDING. Multiple NS → verify consistent SOA serial across all.

---

## V-205235 — DNSSEC FIPS-Compliant Signing Algorithms

**Severity:** CAT II
**SRG:** SRG-APP-000516-DNS-000089

```bash
# Check for DNSSEC signing configuration
named-checkconf -p 2>/dev/null | grep -Ei 'dnssec-enable|dnssec-validation|inline-signing|auto-dnssec'
# Expected: no active DNSSEC directives (NOT APPLICABLE)

# Check for DNSSEC key files (indicates signing is active)
find /var/named -name '*.key' -o -name '*.private' 2>/dev/null
# Expected: no output

# Check for signed records in zone data
find /var/named -name '*.db' -o -name '*.zone' 2>/dev/null | xargs grep -l 'RRSIG' 2>/dev/null
# Expected: no output

# If DNSSEC were active, verify only FIPS-compliant algorithms used
dig +short +dnssec @localhost DNSKEY freeipa.local. | awk '/DNSKEY/ {print $5}'
# Expected: 8 (RSASHA256) or 13 (ECDSAP256SHA256) or 14 (ECDSAP384SHA384)
```

**Pass criteria:** DNSSEC not active → NOT APPLICABLE. If active, algorithm field must be 8, 13, or 14.

---

## V-205236 — DNS Internal-Only / No External Exposure

**Severity:** CAT II
**SRG:** SRG-APP-000516-DNS-000090

```bash
# Check listen-on configuration
named-checkconf -p 2>/dev/null | grep -E 'listen-on'
# Expected: listen-on { 127.0.0.1; <internal_ip>; }; (no 0.0.0.0 or any)

# Check allow-query configuration
named-checkconf -p 2>/dev/null | grep -E 'allow-query'
# Expected: allow-query { any; }; is acceptable for internal DNS
# OPEN if external IPs or any are present on public-facing interface

# Verify no external exposure via firewall
firewall-cmd --list-services | grep dns
# Expected: dns (if listening on internal interface only)

# Confirm DNS port is not exposed externally
ss -tlnp | grep ':53'
# Expected: listening on internal IP only, not 0.0.0.0
```

**Pass criteria:** DNS service listens only on internal/loopback interfaces. No external exposure detected.

---

## Named Service Audit Rules

**Control:** auditd file watch rules for DNS service
**Category:** Auditing

```bash
# Check active audit rules for named
auditctl -l | grep -E 'named_exec|named_conf|named_data'
# Expected (3 rules):
#   -w /sbin/named -p x -k named_exec
#   -w /etc/named.conf -p rwa -k named_conf
#   -w /var/named -p wa -k named_data

# Check persistent rules file
cat /etc/audit/rules.d/named.rules
# Expected: the 3 rules above

# Verify audit rules are loaded (augenrules)
augenrules --check 2>/dev/null && echo 'Rules up to date' || echo 'Rules need reload'

# Test audit is capturing named.conf access
touch /etc/named.conf  # trigger an audit event
audit2allow -i /var/log/audit/audit.log 2>/dev/null | grep named_conf | tail -3
```

**Pass criteria:** All 3 audit rules present and loaded in the kernel (`auditctl -l` shows all 3 keys).
