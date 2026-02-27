# PostgreSQL Database SRG Compliance

## Overview

This repository documents the PostgreSQL configuration baseline and automation used to enforce compliance with applicable **Database SRG audit and protection controls (V-206519 – V-206538)**.

Notes:
- This role **does not install PostgreSQL or pgaudit**.
- Install PostgreSQL 16.x + pgaudit during provisioning (for SonarQube hosts, use the `install-sonarqube` role).
- pgaudit-dependent validations/remediations are gated behind `postgresql_srg_pgaudit_enabled`.

## Usage

Run enforcement first (configures all STIG controls), then validation (verifies they took effect):

```bash
# Enforcement + validation in a single run (default)
ansible-playbook -i inventory playbooks/services/postgresql-srg.yml
```

To run enforcement only:

```bash
ansible-playbook -i inventory playbooks/services/postgresql-srg.yml \
  -e postgresql_srg_validation_enabled=false
```

To run validation only (after a prior enforcement run):

```bash
ansible-playbook -i inventory playbooks/services/postgresql-srg.yml \
  -e postgresql_srg_enforcement_enabled=false
```

To disable pgaudit controls (if pgaudit is not installed):

```bash
ansible-playbook -i inventory playbooks/services/postgresql-srg.yml \
  -e postgresql_srg_pgaudit_enabled=false
```

---

This baseline implements:

- DoD minimum auditable events  
- Event selection controls  
- Session auditing  
- Privilege and role auditing  
- Failed access auditing  
- Full audit record content (who / what / when / where / source / outcome)  
- OS-level audit log protection  

---

# Hardened PostgreSQL Audit Baseline

When pgaudit is installed and enabled, a typical baseline looks like:

```conf
shared_preload_libraries = 'pgaudit'
logging_collector = on

log_connections = on
log_disconnections = on
log_min_error_statement = error
log_truncate_on_rotation = off
log_timezone = 'UTC'
log_file_mode = 0600

pgaudit.log = 'ddl, role, write'
pgaudit.log_catalog = on

log_line_prefix = '%m %H %p %u %d %c %h %r %a %e '
```

---

# PostgreSQL Database SRG Mapping Matrix

| SRG ID   | Requirement Summary | PostgreSQL Control | Ansibleized | Status | Comments / Implementation Details |
|-----------|--------------------|-------------------|-------------|--------|-----------------------------------|
| V-206519 | Restrict modification of audit configuration | Superuser-only GUC enforcement + `log_min_error_statement = error` | ✅ Yes | ✅ Compliant | Unauthorized audit parameter changes denied and logged |
| V-206522 | Use individual accounts or capture individual identity | `%u` + `%a` in `log_line_prefix` | ✅ Yes | ✅ Compliant | Application identity captured via `application_name` |
| V-206523 | Support DoD minimum auditable events | `pgaudit.log`, connection logging | ✅ Yes | ✅ Compliant | DDL, ROLE, WRITE, login/logoff events enabled |
| V-206524 | Allow designated personnel to select audit events | Configurable `pgaudit.log` (superuser context) | ✅ Yes | ✅ Compliant | Audit classes adjustable by authorized admin |
| V-206525 | Audit retrieval of privileges/roles | `pgaudit.log = 'role, read'`, `pgaudit.log_catalog = on` | ✅ Yes | ✅ Compliant | System catalog and role queries logged |
| V-206526 | Audit denied access to privileges/roles | `log_min_error_statement = error` | ✅ Yes | ✅ Compliant | Permission denials logged with SQLSTATE |
| V-206527 | Enable session auditing | `log_connections`, `log_disconnections` | ✅ Yes | ✅ Compliant | Session start, end, duration logged |
| V-206528 | Include event type in audit record | `pgaudit.log` event classification | ✅ Yes | ✅ Compliant | Events labeled DDL, ROLE, WRITE, etc. |
| V-206529 | Include date and time of event | `%m`, `log_timezone = 'UTC'` | ✅ Yes | ✅ Compliant | Millisecond UTC timestamps enforced |
| V-206530 | Include where event occurred | `%H`, `%d`, `%c` | ✅ Yes | ✅ Compliant | Hostname, DB name, session ID logged |
| V-206531 | Include source of event | `%h`, `%r`, `%a` | ✅ Yes | ✅ Compliant | Client IP and application source logged |
| V-206532 | Include outcome of event | `%e`, error logging | ✅ Yes | ✅ Compliant | SQLSTATE and severity recorded |
| V-206533 | Include username | `%u` in prefix | ✅ Yes | ✅ Compliant | Database user logged for every event |
| V-206534 | Include organization-defined audit fields | Hardened prefix + pgaudit | ✅ Yes | ✅ Compliant | Consolidated audit content baseline applied |
| V-206538 | Protect audit logs from unauthorized access | `0600` files, `0700` directory, no truncation | ✅ Yes | ✅ Compliant | OS-level protection enforced via Ansible |

---

# Audit Record Content Coverage

Each audit record includes:

- Timestamp (UTC)
- Server hostname
- Process ID
- Username
- Database name
- Session ID
- Client IP and port
- Application name
- SQLSTATE (outcome)
- Explicit event type (DDL, ROLE, WRITE)

---

# Audit Log Protection Controls

| Control | Configuration |
|----------|--------------|
| Logging enabled | `logging_collector = on` |
| File permissions | `log_file_mode = 0600` |
| Directory permissions | `0700` |
| Ownership | `postgres:postgres` |
| Truncation disabled | `log_truncate_on_rotation = off` |


---

# Compliance Status

All PostgreSQL audit-related SRG controls (V-206519 – V-206538) are implemented and fully **Ansible-automated**.