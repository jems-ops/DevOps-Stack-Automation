# PostgreSQL SRG — Backup & Rollback Procedure

## Overview

The `postgresql_SRG` role automatically creates a timestamped backup of all
PostgreSQL configuration files **before** enforcement tasks run.  If an
enforcement run causes issues (service failure, application breakage, etc.),
you can restore to the pre-enforcement state using the rollback playbook.

## What Gets Backed Up

| File | Description |
|------|-------------|
| `postgresql.conf` | Main server configuration |
| `pg_hba.conf` | Client authentication rules |
| `pg_ident.conf` | User name mapping |
| `postgresql.auto.conf` | Parameters set via `ALTER SYSTEM` |

Backups are stored as compressed tar archives in:

```
/var/lib/pgsql/srg-backups/srg-backup-<TIMESTAMP>.tar.gz
```

## Configuration Variables

Add these to your inventory or playbook vars to customise behaviour:

```yaml
# Enable/disable backup (default: true)
postgresql_srg_backup_enabled: true

# Backup storage location
postgresql_srg_backup_dir: /var/lib/pgsql/srg-backups

# Files to include
postgresql_srg_backup_configs:
  - "{{ postgresql_srg_data_dir }}/postgresql.conf"
  - "{{ postgresql_srg_data_dir }}/pg_hba.conf"
  - "{{ postgresql_srg_data_dir }}/pg_ident.conf"
  - "{{ postgresql_srg_data_dir }}/postgresql.auto.conf"

# Number of archives to retain (oldest pruned automatically)
postgresql_srg_backup_retention_count: 5
```

## Rollback Procedure

### 1. Restore from the most recent backup

```bash
ansible-playbook playbooks/services/postgresql-srg-rollback.yml
```

This will:
1. Auto-detect the running PostgreSQL service and data directory
2. Find the newest `srg-backup-*.tar.gz` archive
3. Stop PostgreSQL
4. Extract the archive, overwriting the current config files
5. Start PostgreSQL and wait for it to accept connections

### 2. Restore from a specific backup

List available backups first:

```bash
ansible sonarqube -b -m find -a \
  "paths=/var/lib/pgsql/srg-backups patterns='srg-backup-*.tar.gz'" \
  | grep path
```

Then pass the desired archive:

```bash
ansible-playbook playbooks/services/postgresql-srg-rollback.yml \
  -e srg_rollback_archive=/var/lib/pgsql/srg-backups/srg-backup-20260319T064500.tar.gz
```

### 3. Target a different host group

```bash
ansible-playbook playbooks/services/postgresql-srg-rollback.yml \
  -e target_hosts=db_servers
```

## Post-Rollback Verification

After rollback, confirm the service and application are healthy:

```bash
# Check PostgreSQL is running
ansible sonarqube -b -m command -a "systemctl status postgresql-16"

# Verify connectivity
ansible sonarqube -b -m command -a "/usr/pgsql-16/bin/pg_isready -h /var/run/postgresql"

# Check SonarQube can connect
curl -sk https://sonar.local/api/system/status | python3 -m json.tool
```

## Manual Rollback (Emergency)

If Ansible is unavailable, SSH to the host and run:

```bash
# 1. Stop PostgreSQL
sudo systemctl stop postgresql-16

# 2. List backups
ls -lt /var/lib/pgsql/srg-backups/

# 3. Extract the desired backup (overwrites current configs)
sudo tar -xzf /var/lib/pgsql/srg-backups/srg-backup-XXXXXXXX.tar.gz -C /

# 4. Fix ownership
sudo chown postgres:postgres /var/lib/pgsql/16/data/postgresql.conf \
  /var/lib/pgsql/16/data/pg_hba.conf \
  /var/lib/pgsql/16/data/pg_ident.conf \
  /var/lib/pgsql/16/data/postgresql.auto.conf

# 5. Start PostgreSQL
sudo systemctl start postgresql-16

# 6. Verify
sudo -u postgres /usr/pgsql-16/bin/pg_isready
```

## Notes

- Backups are created on every enforcement run when `postgresql_srg_backup_enabled: true`.
- Old backups beyond `postgresql_srg_backup_retention_count` are automatically pruned.
- The backup directory is owned by the `postgres` user with mode `0700`.
- Each archive preserves full absolute paths, so extraction to `/` restores files in place.
- The `.bak` files created by individual `lineinfile` tasks (Ansible's `backup: true`) are
  a separate, per-file mechanism and remain available as an additional safety net.
