# postgresql_stig

PostgreSQL hardening role used by `playbooks/services/sonarqube-stig.yml`.

## Defaults
This role **defaults to PostgreSQL 15** (PGDG-style layout):
- `postgresql_stig_service_name: postgresql-15`
- `postgresql_stig_data_dir: /var/lib/pgsql/15/data`

## Parameterizing other versions/layouts
If your host uses a different service name or data directory layout, override these variables in `group_vars` / inventory / `-e`:
```yaml
postgresql_stig_service_name: postgresql
postgresql_stig_data_dir: /var/lib/pgsql/data
postgresql_stig_conf_file: "{{ postgresql_stig_data_dir }}/postgresql.conf"
postgresql_stig_hba_file: "{{ postgresql_stig_data_dir }}/pg_hba.conf"
```

## STIG fixes applied by this role
This role currently enforces the following (simple, file-based) PostgreSQL hardening items:
- `max_connections` (via `pg_max_connections`)
- `client_min_messages = error`
- Local `pg_hba.conf` rules to require `scram-sha-256` for `127.0.0.1/32` and `::1/128`
- Optional `pgaudit` enablement (installs `postgresql_stig_pgaudit_package` and ensures `shared_preload_libraries` includes `pgaudit`)
- Connection + timeout controls (`tcp_keepalives_*`, `statement_timeout`)
- Syslog logging (`log_destination = 'syslog'`) and disables `logging_collector` by default
- (Optional) log directory/filename if you enable the collector (`log_directory`, `log_filename`)

## Notes
- The role defaults to PostgreSQL 15 paths/service and does not attempt cross-version auto-detection.
- If `pg_conf_file` or `pg_hba_file` are missing, the role fails early with a clear error.
