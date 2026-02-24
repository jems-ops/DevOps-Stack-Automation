# postgresql_stig

PostgreSQL hardening role used by `playbooks/services/sonarqube-stig.yml`.

## Defaults
This role **defaults to PostgreSQL 15** (PGDG-style layout):
- `postgres_service_name: postgresql-15`
- `pg_data_dir: /var/lib/pgsql/15/data`

## Parameterizing other versions/layouts
If your host uses a different service name or data directory layout, override these variables in `group_vars` / inventory / `-e`:
```yaml
postgres_service_name: postgresql
pg_data_dir: /var/lib/pgsql/data
pg_conf_file: "{{ pg_data_dir }}/postgresql.conf"
pg_hba_file: "{{ pg_data_dir }}/pg_hba.conf"
```

## STIG fixes applied by this role
This role currently enforces the following (simple, file-based) PostgreSQL hardening items:
- `max_connections` (via `pg_max_connections`)
- `client_min_messages = error`
- Local `pg_hba.conf` rules to require `scram-sha-256` for `127.0.0.1/32` and `::1/128`
- Optional `pgaudit` enablement (installs `pg_pgaudit_package` and ensures `shared_preload_libraries` includes `pgaudit`)
- Logging collector + log directory/filename (`logging_collector`, `log_directory`, `log_filename`)

## Notes
- The role defaults to PostgreSQL 15 paths/service and does not attempt cross-version auto-detection.
- If `pg_conf_file` or `pg_hba_file` are missing, the role fails early with a clear error.
