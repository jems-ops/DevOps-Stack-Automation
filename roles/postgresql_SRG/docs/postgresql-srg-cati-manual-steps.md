# PostgreSQL SRG — CAT I Manual Verification Steps

Target host: `sonar.local` (192.168.56.18)
PostgreSQL version: 16 (service: `postgresql-16`)
Data directory: `/var/lib/pgsql/16/data`

> SSH into the host first: `ssh vagrant@sonar.local`
> Most commands require `sudo` or running as the `postgres` user.

---

## V-265854 — Vendor-Supported PostgreSQL Version

**Requirement:** PostgreSQL must be a vendor-supported version.

```bash
# Check installed version
psql --version

# Or from inside psql
sudo -u postgres psql -c "SELECT version();"
```

**Expected:** PostgreSQL 16.x (any supported minor version).
Major versions 15 and 16 are currently supported.

---

## V-233495 — FIPS / NSA-Approved Cryptography

**Requirement:** DBMS must use FIPS 140-2/140-3 validated crypto modules.

```bash
# 1. Check OS-level FIPS mode
cat /proc/sys/crypto/fips_enabled
# Expected: 1 (enabled) — will be 0 in lab

# 2. Check system crypto policy
update-crypto-policies --show
# Expected: FIPS

# 3. Check OpenSSL FIPS provider
openssl list -providers 2>/dev/null | grep -i fips
# Expected: fips provider listed
```

**Lab note:** FIPS is disabled in this lab (`postgresql_srg_fips_required: false`).
For production, enable FIPS at OS level: `fips-mode-setup --enable` and reboot.

---

## V-206520 — Authentication / Role Control

**Requirement:** Integrate with org-level auth or document/justify local accounts.

### A. Verify localhost-only binding
```bash
sudo -u postgres psql -c "SHOW listen_addresses;"
# Expected: localhost
```

### B. Verify no external access in pg_hba.conf
```bash
sudo grep -v '^#' /var/lib/pgsql/16/data/pg_hba.conf | grep -v '^$'
# Expected: Only local/127.0.0.1 entries, no 0.0.0.0/0 or external CIDRs
```

### C. Verify no trust authentication
```bash
sudo grep -i 'trust' /var/lib/pgsql/16/data/pg_hba.conf
# Expected: No matches (or only in comments)
```

### D. Verify network binding
```bash
ss -tulnp | grep 5432
# Expected: Listening on 127.0.0.1:5432 only
```

### E. Audit login roles
```bash
sudo -u postgres psql -c "SELECT rolname, rolcanlogin FROM pg_roles WHERE rolcanlogin = true;"
# Expected: Only approved accounts (postgres, sonar, stig_validate_role, stig_limited)
```

---

## V-206521 — Access Control / Least Privilege

**Requirement:** Users permitted access only to authorized objects.

### A. Verify PUBLIC CREATE revoked on database
```bash
sudo -u postgres psql -c "SELECT datacl FROM pg_database WHERE datname = current_database();"
# Expected: No 'C' (CREATE) for PUBLIC (=C/ should NOT appear without a role prefix)
```

### B. Verify PUBLIC CREATE revoked on schemas
```bash
sudo -u postgres psql -c "SELECT nspname, nspacl FROM pg_namespace WHERE nspname = 'public';"
# Expected: No permissive PUBLIC privileges
```

### C. Verify default privileges hardened
```bash
sudo -u postgres psql -c "SELECT * FROM pg_default_acl;"
# Expected: Entries showing restricted defaults
```

### D. Verify readonly role exists
```bash
sudo -u postgres psql -c "SELECT rolname FROM pg_roles WHERE rolname = 'app_readonly';"
# Expected: app_readonly role exists
```

### E. Verify superuser restriction
```bash
sudo -u postgres psql -c "SELECT rolname FROM pg_roles WHERE rolsuper = true;"
# Expected: Only 'postgres'
```

---

## V-206545 — Installation Account Control

**Requirement:** DBA OS account must be controlled and audited.

### A. Verify postgres shell is restricted
```bash
grep '^postgres' /etc/passwd
# Expected: shell is /sbin/nologin
```

### B. Verify postgres account is locked
```bash
sudo passwd -S postgres
# Expected: 'L' or 'LK' (locked)
```

### C. Verify sudo config exists
```bash
sudo ls /etc/sudoers.d/ | grep -i dbadmins
# Expected: sudoers file for dbadmins group
```

### D. Verify audit rules for postgres binaries
```bash
sudo auditctl -l | grep postgres
# Expected: Audit rules monitoring postgres binaries/data
```

---

## V-206555 — Password Storage Security

**Requirement:** Passwords must be hashed with one-way salted hashing; files protected.

### A. Verify password_encryption setting
```bash
sudo -u postgres psql -c "SHOW password_encryption;"
# Expected: scram-sha-256
```

### B. Verify no plaintext/md5 passwords in roles
```bash
sudo -u postgres psql -c "SELECT rolname, rolpassword IS NOT NULL AS has_pw FROM pg_authid;"
# If passwords exist, verify they are SCRAM:
sudo -u postgres psql -c "SELECT rolname FROM pg_authid WHERE rolpassword LIKE 'md5%';"
# Expected: No rows returned
```

### C. Check file permissions on data directory
```bash
ls -ld /var/lib/pgsql/16/data
# Expected: drwx------ postgres postgres (0700)

ls -l /var/lib/pgsql/16/data/postgresql.conf
ls -l /var/lib/pgsql/16/data/pg_hba.conf
# Expected: -rw------- postgres postgres (0600)
```

### D. Find and check .pgpass files
```bash
sudo find /root /home /var/lib/pgsql -name '.pgpass' -ls 2>/dev/null
# Expected: 0600 permissions, owned by postgres
```

---

## V-206556 — SCRAM Password Hashing Enforcement

**Requirement:** Passwords must use one-way salted hashing (SCRAM-SHA-256).

### A. Verify encryption setting
```bash
sudo -u postgres psql -c "SHOW password_encryption;"
# Expected: scram-sha-256
```

### B. Verify no weak (md5) hashes
```bash
sudo -u postgres psql -c "SELECT rolname FROM pg_authid WHERE rolpassword LIKE 'md5%';"
# Expected: No rows returned
```

### C. Verify SCRAM hashes (if passwords exist)
```bash
sudo -u postgres psql -c "SELECT rolname, left(rolpassword, 14) FROM pg_authid WHERE rolpassword IS NOT NULL;"
# Expected: All start with 'SCRAM-SHA-256$'
```

---

## V-206557 — Encrypt Passwords in Transit

**Requirement:** Passwords must be encrypted during network transmission.

### A. Verify no insecure auth methods
```bash
sudo grep -Ev '^#|^$' /var/lib/pgsql/16/data/pg_hba.conf | grep -E 'trust|password[[:space:]]|md5'
# Expected: No matches
```

### B. Verify SCRAM enforced for host connections
```bash
sudo grep -Ev '^#|^$' /var/lib/pgsql/16/data/pg_hba.conf | grep 'host'
# Expected: All host entries use scram-sha-256
```

### C. Verify postgres uses peer auth
```bash
sudo grep -Ev '^#|^$' /var/lib/pgsql/16/data/pg_hba.conf | grep 'local.*postgres.*peer'
# Expected: Match found
```

---

## V-206559 — PKI Private Key Storage

**Requirement:** DBMS PKI private keys must be stored in FIPS-validated module.

### A. Check for server.key
```bash
sudo ls -l /var/lib/pgsql/16/data/server.key 2>/dev/null
# Expected: File not found (Not Applicable — SSL not enabled)
```

### B. Verify SSL is off
```bash
sudo -u postgres psql -c "SHOW ssl;"
# Expected: off
```

**If SSL IS enabled:** Verify `server.key` is 0600, owned by postgres.

---

## V-206561 — Prevent Display of Authentication Secrets

**Requirement:** Auth secrets must not be displayed in logs, configs, or tools.

### A. Verify log_statement is not 'all' (prevents password logging)
```bash
sudo -u postgres psql -c "SHOW log_statement;"
# Expected: ddl or mod (not 'all' which would log CREATE ROLE ... PASSWORD)
```

### B. Search for plaintext passwords in config files
```bash
sudo grep -rni 'password' /var/lib/pgsql/16/data/postgresql.conf | grep -v '^#'
# Expected: Only references to password_encryption setting, no plaintext values
```

### C. Check .pgpass permissions
```bash
sudo find /var/lib/pgsql /root /home -name '.pgpass' -exec ls -l {} \; 2>/dev/null
# Expected: 0600, owned by appropriate user
```

### D. Check config file permissions
```bash
stat -c '%a %U:%G %n' /var/lib/pgsql/16/data/postgresql.conf /var/lib/pgsql/16/data/pg_hba.conf
# Expected: 600 postgres:postgres for both
```

---

## V-206562 — FIPS 140-2/140-3 Cryptographic Modules

**Requirement:** DBMS must use FIPS-validated crypto modules.

```bash
# Same checks as V-233495:
cat /proc/sys/crypto/fips_enabled
# Expected: 1

update-crypto-policies --show
# Expected: FIPS

openssl list -providers 2>/dev/null | grep -i fips
# Expected: fips provider listed
```

**Lab note:** Same as V-233495 — FIPS disabled in lab.

---

## V-206570 — Protect Data at Rest

**Requirement:** Protect confidentiality and integrity of data at rest.

### A. Verify data directory ownership and permissions
```bash
ls -ld /var/lib/pgsql/16/data
# Expected: drwx------ postgres postgres (0700)
```

### B. Verify config file permissions
```bash
stat -c '%a %U:%G %n' /var/lib/pgsql/16/data/postgresql.conf \
  /var/lib/pgsql/16/data/pg_hba.conf \
  /var/lib/pgsql/16/data/pg_ident.conf
# Expected: 600 postgres:postgres for all
```

### C. Verify auto.conf permissions (if exists)
```bash
ls -l /var/lib/pgsql/16/data/postgresql.auto.conf
# Expected: 0600 postgres:postgres
```

### D. Check SELinux context
```bash
ls -Zd /var/lib/pgsql/16/data
# Expected: postgresql_db_t label
```

### E. Check data page checksums (optional integrity check)
```bash
sudo -u postgres /usr/pgsql-16/bin/pg_controldata /var/lib/pgsql/16/data | grep checksum
# Expected: "Data page checksum version: 1" if enabled
```

---

## V-206604 — Cryptographic Protection for Disclosure

**Requirement:** Configure required crypto protection for data requiring confidentiality.

### A. Verify localhost-only binding
```bash
sudo -u postgres psql -c "SHOW listen_addresses;"
# Expected: localhost
```

### B. Verify no external host entries
```bash
sudo grep -Ev '^#|^$' /var/lib/pgsql/16/data/pg_hba.conf | grep -v '127.0.0.1' | grep -v '::1' | grep 'host'
# Expected: No matches (no external host access)
```

### C. Verify listening ports
```bash
ss -tulnp | grep 5432
# Expected: 127.0.0.1:5432 only
```

---

## V-206605 — Cryptographic Protection for Transmission

**Requirement:** Configure required crypto for data in transit.

### A. Verify localhost-only binding (same as V-206604)
```bash
sudo -u postgres psql -c "SHOW listen_addresses;"
# Expected: localhost
```

### B. Verify no remote host connections configured
```bash
sudo grep -Ev '^#|^$' /var/lib/pgsql/16/data/pg_hba.conf | grep -E 'host.*0\.0\.0\.0|host.*/0'
# Expected: No matches
```

**Note:** Since PostgreSQL operates localhost-only with no external network communication,
DBMS-level TLS is not required. Protection is via network isolation.

---

## Manual Verification Results (2026-03-19)

Host: `sonar.local` (192.168.56.18) — PostgreSQL 16.13 on Rocky Linux 9

- **V-265854** (Supported Version): PASS — PostgreSQL 16.13
- **V-233495** (FIPS / NSA Crypto): EXCEPTION — `fips_enabled=0`; crypto policy is FIPS; lab exception documented (`postgresql_srg_fips_required: false`)
- **V-206520** (Auth / Role Control): PASS — localhost-only, no trust auth, SCRAM enforced, only approved roles (postgres, sonar, stig_limited)
- **V-206521** (Least Privilege): PASS — PUBLIC CREATE revoked, defaults hardened, `app_readonly` role exists, only `postgres` is superuser
- **V-206545** (Install Account): PASS — postgres shell `/sbin/nologin`, account locked (LK), audit rules present for data dir and binaries
- **V-206555** (Password Storage): PASS — SCRAM-SHA-256 enabled, no md5 hashes, data dir 0700, configs 0600, no .pgpass files
- **V-206556** (SCRAM Hashing): PASS — `sonar` role uses `SCRAM-SHA-256$` hash, no weak hashes
- **V-206557** (Encrypt Passwords in Transit): PASS — no insecure methods (trust/md5/password), all host entries scram-sha-256, postgres uses peer
- **V-206559** (PKI Key Storage): PASS (N/A) — no server.key, SSL off
- **V-206561** (Auth Secret Display): PASS — `log_statement=ddl`, no plaintext passwords in config, configs 0600
- **V-206562** (FIPS Crypto Modules): EXCEPTION — same as V-233495; lab exception
- **V-206570** (Data at Rest): PASS — data dir 0700, configs 0600, SELinux `postgresql_db_t` context
- **V-206604** (Crypto for Disclosure): PASS — localhost-only, no external host entries
- **V-206605** (Crypto for Transmission): PASS — no remote/wildcard pg_hba entries

**Health Check:** PostgreSQL-16 active, SonarQube active, web API status=UP (v10.3.0.82913)

**Summary:** 12/14 PASS, 2/14 EXCEPTION (FIPS — documented lab exception)

---

## Post-Verification Health Check

After running all checks, verify services are still healthy:

```bash
# PostgreSQL service
sudo systemctl status postgresql-16
# Expected: active (running)

# SonarQube service
sudo systemctl status sonarqube
# Expected: active (running)

# SonarQube web API
curl -sk https://sonar.local/api/system/status
# Expected: {"status":"UP", ...}
```
