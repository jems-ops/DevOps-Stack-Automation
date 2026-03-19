# PostgreSQL SRG Role — Documentation

## Quick Start

```bash
# Run full enforcement + validation + healthcheck
ansible-playbook playbooks/services/postgresql-srg.yml

# Run only enforcement
ansible-playbook playbooks/services/postgresql-srg.yml -t enforce

# Run only validation (read-only checks)
ansible-playbook playbooks/services/postgresql-srg.yml -t validate

# Run a specific category
ansible-playbook playbooks/services/postgresql-srg.yml -t access
ansible-playbook playbooks/services/postgresql-srg.yml -t auditing
ansible-playbook playbooks/services/postgresql-srg.yml -t config
ansible-playbook playbooks/services/postgresql-srg.yml -t crypto
ansible-playbook playbooks/services/postgresql-srg.yml -t lifecycle

# Rollback to pre-enforcement state
ansible-playbook playbooks/services/postgresql-srg-rollback.yml

# Enable destructive operations (drop DBs, remove packages)
ansible-playbook playbooks/services/postgresql-srg.yml -e postgresql_srg_allow_removal=true
```

## Role Structure

```
roles/postgresql_SRG/
  defaults/main.yml              # All configurable variables
  handlers/main.yml              # Restart/Reload PostgreSQL handlers
  tasks/
    main.yml                     # Orchestrator: detect → backup → enforce → validate → healthcheck
    auto-detect.yml              # Find active PostgreSQL service
    post_stig_healthcheck.yml    # Verify PG + SonarQube health
    common/normalize.yml         # Normalize detected paths
    enforcement/
      main.yml                   # Category loader
      access/                    # Auth, RBAC, sessions, privileges (32 controls)
      auditing/                  # pgaudit, logging, audit protection (43 controls)
      config/                    # postgresql.conf, network, components (6 controls)
      crypto/                    # FIPS, TLS, crypto modules (10 controls)
      lifecycle/                 # Versioning, patching, cleanup (7 controls)
      backup/                    # Pre-enforcement config backup
    validation/
      CATI/                      # CAT I validation tasks
      CATII/                     # CAT II validation tasks
  files/sql/                     # Reference SQL scripts
```

## Safety

Destructive operations (DROP DATABASE, remove packages, revoke superuser) are **disabled by default**.
Set `postgresql_srg_allow_removal: true` to enable them. Without this flag, destructive tasks
only report warnings.

Backups are created automatically before every enforcement run. See
[postgresql-srg-rollback.md](postgresql-srg-rollback.md) for rollback procedures.

## Related Documentation

- [STIG Control Mapping](stig-mapping.md) — V-ID → category → description
- [Troubleshooting Guide](troubleshooting.md) — Common issues and fixes
- [Rollback Procedure](postgresql-srg-rollback.md) — Backup/restore details
- [CAT I Manual Steps](postgresql-srg-cati-manual-steps.md) — Manual verification commands

---

## PostgreSQL SRG CAT I Compliance Summary (RMF Artifact)

| Control ID | CAT | Implementation Status | Implementation Method | Validation Method | Evidence / Notes |
|-------------|------|----------------------|----------------------|------------------|-----------------|
| V-206520 | CAT I | Not a Finding | Authentication managed at application and OS layer. PostgreSQL instance does not require enterprise directory integration in this architecture. | Ansible validation checks and configuration review | Access control enforced through OS authentication and application-layer identity management. |
| V-206521 | CAT I | Remediated | Database role-based access control enforced through PostgreSQL configuration managed via Ansible automation. | Automated validation playbook and manual configuration verification | Users restricted to authorized database objects and data only. |
| V-206545 | CAT I | Remediated | Authentication and security configuration hardened through Ansible enforcement tasks. | Ansible validation and configuration inspection | Prevents exposure of authentication information. |
| V-206555 | CAT I | Not a Finding | Database objects, configuration files, and associated scripts reviewed to ensure credentials are not stored in plaintext. | Automated Ansible validation scanning configuration paths | Password storage mechanisms validated and protected. |
| V-206556 | CAT I | Remediated | Secure password hashing enforced using PostgreSQL SCRAM-SHA-256 authentication via Ansible configuration management. | Ansible validation tasks and PostgreSQL configuration verification | Ensures salted one-way hashing functions protect stored credentials. |
| V-206557 | CAT I | Not a Finding | No password transmission occurs across the network in the current deployment architecture. | Architecture review and Ansible configuration validation | System operates within controlled internal environment. |
| V-206559 | CAT I | Not a Finding | No DBMS PKI private keys exist in this PostgreSQL implementation. | Configuration inspection and validation playbook | Control not applicable to the current system architecture. |
| V-206561 | CAT I | Not a Finding | PostgreSQL instance does not manage or expose authentication secrets. | Configuration validation via Ansible | No mechanisms exist that could display authentication secrets. |
| V-206562 | CAT I | Not a Finding | System operates in FIPS mode using FIPS 140-2/140-3 validated cryptographic modules. | OS-level validation and Ansible checks | PostgreSQL relies on OpenSSL FIPS module provided by the operating system. |
| V-206570 | CAT I | Compliant | Database files protected through strict filesystem permissions and controlled access mechanisms. | Ansible validation tasks and permission checks | Encryption at rest and integrity controls protect database files. |
| V-206604 | CAT I | Not a Finding | Database stores internal operational metadata and analysis data only. | Configuration review and validation automation | No external transmission of sensitive data occurs. |
| V-206605 | CAT I | Not a Finding | DBMS and operating system provide required cryptographic protection for operational classification. | Configuration inspection and Ansible validation | Cryptographic protections align with system classification requirements. |
| V-233495 | CAT I | Not a Finding | PostgreSQL operates in FIPS-approved mode using NSA-approved cryptographic standards. | OS cryptographic module verification and Ansible validation | Cryptographic compliance confirmed through FIPS configuration. |
| V-265854 | CAT I | Compliant | PostgreSQL DBMS and associated components are actively maintained and supported. | Package validation and system update checks | System components are current and maintained with vendor security updates. |
