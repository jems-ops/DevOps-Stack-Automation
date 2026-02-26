# postgresql_stig

PostgreSQL hardening role used by `playbooks/services/sonarqube-stig.yml`.

## Defaults
This role defaults to the distro PostgreSQL layout:
- `postgresql_stig_service_name: postgresql`
- `postgresql_stig_data_dir: /var/lib/pgsql/data`

## Supporting PostgreSQL 15 layout
This role also supports the PGDG-style PostgreSQL 15 layout:
- `postgresql_stig_service_name: postgresql-15`
- `postgresql_stig_data_dir: /var/lib/pgsql/15/data`

You can either:
- Override variables in `group_vars` / inventory / `-e`, **or**
- Keep `postgresql_stig_auto_detect: true` and let the role select the first matching unit from `postgresql_stig_candidate_services`.

## Parameterizing other versions/layouts
Override these variables in `group_vars` / inventory / `-e`:
```yaml
postgresql_stig_service_name: postgresql-15
postgresql_stig_data_dir: /var/lib/pgsql/15/data
postgresql_stig_conf_file: "{{ postgresql_stig_data_dir }}/postgresql.conf"
postgresql_stig_hba_file: "{{ postgresql_stig_data_dir }}/pg_hba.conf"
```

## STIG fixes applied by this role
This role currently enforces the following (simple, file-based) PostgreSQL hardening items:
- `max_connections` (via `postgresql_stig_max_connections`)
- `client_min_messages = error`
- Local `pg_hba.conf` rules to require `scram-sha-256` for `127.0.0.1/32` and `::1/128`
- STIG exception: `pgaudit` (audit extension) is **not** enabled/enforced by this role in this repo at this time
- STIG exception: centralized authentication (CCI-000015) pending enterprise IAM integration (see `docs/stig-exceptions/postgresql-centralized-auth-cci-000015.md`)
- STIG exception: SSL enforcement + hostssl + client certificate validation (CCI-002422) pending enterprise PKI (see `docs/stig-exceptions/postgresql-ssl-enforcement-cci-002422.md`)
- Connection + timeout controls (`tcp_keepalives_*`, `statement_timeout`)
- Syslog logging (`log_destination = 'syslog'`) and disables `logging_collector` by default
- (Optional) log directory/filename if you enable the collector (`log_directory`, `log_filename`)

## Notes
- The role can auto-detect a supported systemd unit (`postgresql`, `postgresql-15`, etc.) when `postgresql_stig_auto_detect` is enabled.
- If `postgresql_stig_conf_file` or `postgresql_stig_hba_file` are missing, the role fails early with a clear error.
- Exception reports (if enabled) are generated on the controller in `roles/postgresql_stig/exceptions-report/<host>/`.
