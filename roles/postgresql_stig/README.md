# postgresql_stig

Skeleton Ansible role intended to hold **PostgreSQL STIG** (database-specific) hardening controls.

## What this role does (currently)
- Optionally enforces EL8 (disabled by default)
- Auto-detects a PostgreSQL systemd service name (or you can provide one)
- Optionally ensures the PostgreSQL service is enabled and running

## Role variables
```yaml
# Master enable/disable switch
postgresql_stig_enabled: true

# Optional safety check
postgresql_stig_enforce_el8: false

# If true, fail when PostgreSQL is not detected
postgresql_stig_fail_if_postgres_missing: false

# If empty, role tries to auto-detect among common service names
postgresql_stig_service_name: ""

# Best-effort service verification
postgresql_stig_ensure_service_running: true

# Tailoring map for future controls
postgresql_stig_vars: {}
```

## Example usage
```yaml
---
- name: Apply PostgreSQL STIG controls
  hosts: sonarqube
  become: true
  roles:
    - role: postgresql_stig
      vars:
        postgresql_stig_service_name: postgresql
```

## Next step
Tell me which PostgreSQL STIG/benchmark source you want to align to (DISA STIG, CIS, OpenSCAP content, etc.) and which PostgreSQL major version you’re running, and I can start implementing concrete controls + a CSV report for Postgres findings similar to the OS exceptions report.
