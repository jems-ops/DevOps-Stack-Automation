# PostgreSQL SRG — Troubleshooting Guide

## Common Issues

### 1. PostgreSQL fails to start after enforcement

**Symptoms:** `systemctl status postgresql-16` shows failed state after playbook run.

**Likely causes:**
- `shared_preload_libraries` references a missing extension (pgaudit)
- Conflicting `listen_addresses` or `port` settings
- File permission changes prevent postgres from reading config

**Fix:**
```bash
# Check the PostgreSQL log
sudo journalctl -u postgresql-16 --no-pager -n 50

# Rollback to pre-enforcement backup
ansible-playbook playbooks/services/postgresql-srg-rollback.yml

# Or manually restore
sudo systemctl stop postgresql-16
sudo tar -xzf /var/lib/pgsql/srg-backups/srg-backup-XXXXXXXX.tar.gz -C /
sudo chown -R postgres:postgres /var/lib/pgsql/16/data/
sudo systemctl start postgresql-16
```

### 2. SonarQube cannot connect after STIG run

**Symptoms:** SonarQube web UI shows "Database connection error" or service won't start.

**Likely causes:**
- `pg_hba.conf` auth method changed (trust → scram-sha-256) but SonarQube password not SCRAM-hashed
- `listen_addresses` too restrictive for SonarQube's connection path
- Connection limit reached

**Fix:**
```bash
# Check pg_hba.conf
ansible sonarqube -b -m command -a "cat /var/lib/pgsql/16/data/pg_hba.conf"

# Verify SonarQube can authenticate
ansible sonarqube -b -u postgres -m command -a \
  "psql -c \"SELECT rolname, rolpassword LIKE 'SCRAM%' AS is_scram FROM pg_authid WHERE rolname='sonar';\""

# Re-hash password if needed
ansible sonarqube -b -u postgres -m command -a \
  "psql -c \"ALTER ROLE sonar PASSWORD 'newpassword';\""
```

### 3. pgaudit extension not found

**Symptoms:** PostgreSQL fails on startup with `could not access file "pgaudit"`.

**Fix:**
```bash
# Install pgaudit for your PostgreSQL version
ansible sonarqube -b -m package -a "name=pgaudit_16 state=present"

# Or disable pgaudit controls
# Set in your playbook vars:
#   postgresql_srg_pgaudit_enabled: false
```

### 4. Playbook skips all enforcement tasks

**Symptoms:** `ok=2 changed=0 skipped=everything`.

**Likely causes:**
- Auto-detect failed (no matching systemd service found)
- All per-control toggles set to `false`
- Running with wrong tags

**Fix:**
```bash
# Run with verbose to see what's being skipped
ansible-playbook playbooks/services/postgresql-srg.yml -v

# Check auto-detect results
ansible sonarqube -b -m systemd -a "name=postgresql-16"

# Verify defaults aren't overridden
grep 'enabled: false' roles/postgresql_SRG/defaults/main.yml | head
```

### 5. Destructive tasks not executing

**Symptoms:** V-206549 or V-206610 report warnings but don't drop databases or packages.

**Explanation:** This is by design. Destructive operations require explicit opt-in.

**Fix:**
```bash
# Enable destructive operations
ansible-playbook playbooks/services/postgresql-srg.yml \
  -e postgresql_srg_allow_removal=true
```

### 6. Tag-based run missing tasks

**Symptoms:** Running `-t access` doesn't include auto-detect or backup.

**Explanation:** Auto-detect and backup have their own tags. When filtering by category tag, infrastructure tasks without that tag are skipped.

**Fix:**
```bash
# Include multiple tags
ansible-playbook playbooks/services/postgresql-srg.yml \
  -t "access,backup"

# Or run full playbook without tag filter for complete execution
ansible-playbook playbooks/services/postgresql-srg.yml
```

### 7. File permission errors after ALTER SYSTEM

**Symptoms:** `postgresql.auto.conf` reverts to `0640` after `ALTER SYSTEM SET`.

**Explanation:** PostgreSQL resets `postgresql.auto.conf` permissions on every `ALTER SYSTEM` call.

**Fix:** The auditing category includes a final V-206542 re-enforcement pass that re-hardens permissions after all enforcement tasks complete. This runs automatically.

## Useful Diagnostic Commands

```bash
# Full playbook dry-run (check mode)
ansible-playbook playbooks/services/postgresql-srg.yml --check --diff

# Run only validation (no changes)
ansible-playbook playbooks/services/postgresql-srg.yml -t validate

# List all available tags
ansible-playbook playbooks/services/postgresql-srg.yml --list-tags

# Check PostgreSQL status remotely
ansible sonarqube -b -m command -a "/usr/pgsql-16/bin/pg_isready"

# Check SonarQube health
curl -sk https://sonar.local/api/system/status | python3 -m json.tool
```
