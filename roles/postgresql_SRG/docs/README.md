
# PostgreSQL SRG Automation

![SRG Compliance](https://img.shields.io/badge/SRG-CAT%20I%20Compliant-green)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%20%7C%2016-blue)
![Platform](https://img.shields.io/badge/Platform-RHEL%208-red)
![Automation](https://img.shields.io/badge/Automation-Ansible-yellow)

---

# Overview

This repository provides **Ansible automation for PostgreSQL Security Requirements Guide (SRG) controls**.

The automation implements:

- PostgreSQL security hardening
- SRG compliance enforcement
- Automated validation checks
- Compliance documentation artifacts

The implementation supports:

- PostgreSQL 15
- PostgreSQL 16
- Red Hat Enterprise Linux 8

The automation is designed for **DevSecOps pipelines, RMF submission, and STIG compliance validation**.

---

# Architecture

Application services interact with the PostgreSQL database locally within the system boundary.

Application (SonarQube)
│
│ JDBC (localhost)
▼
PostgreSQL Database
│
▼
RHEL 8 Operating System

Key architecture principles:

- Database access restricted to localhost
- Role-based access control enforced
- SCRAM-SHA-256 password hashing
- FIPS cryptographic modules enabled
- No external database exposure

---

# PostgreSQL SRG CAT I Compliance Summary

| Control ID | CAT | Implementation Status | Implementation Method | Validation Method | Evidence | Reason |
|---|---|---|---|---|---|---|
| V-206520 | CAT I | Not a Finding | Authentication managed at application and OS layer | Ansible validation checks | Access control enforced via OS authentication | Database not exposed to enterprise users |
| V-206521 | CAT I | Compliant | RBAC model enforced via PostgreSQL roles | Automated validation playbook | Authorized object access enforced | Least privilege access control |
| V-206545 | CAT I | Compliant | Hardened authentication configuration | Configuration validation | Sensitive authentication data protected | Authentication configuration secured |
| V-206555 | CAT I | Compliant | Credential storage review and protection | Configuration scanning and role audit | SCRAM-SHA-256 credential hashing | Password storage secured |
| V-206556 | CAT I | Compliant | SCRAM-SHA-256 password encryption | PostgreSQL configuration validation | Salted password hashing enforced | Secure password hashing |
| V-206557 | CAT I | Not a Finding | Localhost-only database communication | Architecture validation | No network password transmission | Application and database share host |
| V-206559 | CAT I | Not Applicable | No PKI private keys used | Configuration inspection | Control not applicable | System architecture excludes PKI |
| V-206561 | CAT I | Compliant | Authentication secrets protected | Logging and configuration validation | No secret exposure in logs | Secrets protected |
| V-206562 | CAT I | Compliant | FIPS cryptographic modules enabled | OS-level FIPS validation | OpenSSL FIPS modules used | Cryptographic compliance enforced |
| V-206570 | CAT I | Compliant | Database file system protections | Permission validation | Database files protected | Restricted file access |
| V-206604 | CAT I | Not a Finding | Internal application data only | Architecture review | No external data transmission | Internal service database |
| V-206605 | CAT I | Compliant | Cryptographic protections enforced | Configuration validation | Encryption mechanisms validated | Cryptographic protections enabled |
| V-233495 | CAT I | Compliant | FIPS-approved cryptography used | OS cryptographic verification | FIPS mode enabled | NSA-approved crypto standards |
| V-265854 | CAT I | Compliant | Supported PostgreSQL version maintained | Package validation checks | Security updates applied | Supported DBMS version |

---

# Running the Automation

## Run Full Enforcement


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


Run a Specific Control

Example:
```bash
ansible-playbook -i inventory playbooks/services/postgresql-srg.ym --tags V-206521
```

Supported Platforms

Platform	Version
Red Hat Enterprise Linux	8.x
PostgreSQL	15
PostgreSQL	16


⸻

Compliance Frameworks

This automation supports:
	•	DISA PostgreSQL SRG
	•	NIST 800-53
	•	RMF / ATO Documentation
	•	DevSecOps Compliance Pipelines

⸻

Evidence Collection

Validation artifacts can be stored in:

/rmf/evidence/

Examples include:
	•	Role audit outputs
	•	PostgreSQL configuration snapshots
	•	Ansible validation logs
	•	Database privilege reports

⸻

Author

Jemal Miftah
DevSecOps Engineer

⸻

License

Internal Security Automation

---
