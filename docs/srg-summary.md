# PostgreSQL STIG / SRG Compliance Matrix

**System:** PostgreSQL 16  
**Platform:** RHEL 8.x  
**Application:** SonarQube Backend Database  
**Automation:** Ansible  
**Environment:** Isolated Localhost Deployment  

This repository implements automated validation and enforcement of PostgreSQL Security Requirements Guide (SRG) / STIG controls using Ansible.  
Each control is verified through configuration inspection, PostgreSQL queries, and host-level security checks.

---

# Compliance Status Overview

| Control ID | Status | Comment | Finding Details |
|------------|--------|---------|----------------|
| V-206520 | Not Applicable / Not a Finding | Database operates in an isolated architecture and does not support enterprise interactive users. Access restricted to localhost and application service accounts. Ansible validates role assignments and `pg_hba.conf` restrictions. | PostgreSQL listens only on localhost, no external authentication sources used, and only approved roles exist. |
| V-206521 | Not a Finding | PostgreSQL enforces least privilege through role-based access control (RBAC). PUBLIC privileges revoked and object access granted through authorized roles only. Ansible validates schema privileges and role assignments. | Queries confirm no unauthorized privileges, superuser restricted to `postgres`, and object access granted only through approved roles. |
| V-206545 | Not a Finding | DBMS installation account (`postgres`) usage is restricted. Direct login disabled and administrative access controlled via sudo from authorized DBA accounts. Ansible validates account shell configuration and superuser roles. | Only `postgres` role has SUPERUSER privileges and administrative actions are logged through PostgreSQL logging and pgAudit. |
| V-206555 | Not a Finding | PostgreSQL does not manage passwords in this deployment. Peer authentication is used exclusively and password-based authentication methods are disabled. Ansible verifies authentication configuration. | `pg_hba.conf` contains peer authentication only and no roles store passwords in `pg_authid`. |
| V-206556 | Not a Finding | Inventory of database objects, configuration files, scripts, and environment files maintained. Passwords are stored using SCRAM-SHA-256 hashing when present. Ansible scans for password locations and verifies secure file permissions. | Password hashes stored securely and `.pgpass` files restricted to mode 0600 with proper ownership. |
| V-206557 | Not a Finding | Password transmission encryption not applicable. Database operates localhost-only using peer authentication and does not transmit credentials across the network. Ansible validates `pg_hba.conf` and listen address configuration. | No TCP password authentication enabled and no remote connections permitted. |
| V-206559 | Not a Finding | PostgreSQL does not use SSL/TLS certificates or PKI private keys in this deployment. Peer authentication is used exclusively. Ansible verifies SSL is disabled and no certificate files exist. | No DBMS PKI private keys present; therefore storage in FIPS cryptographic modules is not applicable. |
| V-206561 | Not a Finding | Authentication secrets are not displayed or stored. Peer authentication is used and no `.pgpass` or password environment variables exist. Ansible scans configuration directories to confirm absence of credentials. | No authentication secrets detected in configuration files, logs, or environment variables. |
| V-206562 | Not a Finding | PostgreSQL runs on RHEL 8.x with FIPS mode enabled. All cryptographic operations use OS-provided FIPS-validated modules. Ansible validates system FIPS status and crypto policy configuration. | `/proc/sys/crypto/fips_enabled` returns `1` confirming FIPS cryptographic modules are active. |
| V-206570 | Not a Finding | Data at rest protected through file permission controls, infrastructure encryption, and database integrity mechanisms. Ansible validates PGDATA permissions and configuration file protections. | Database directories restricted to `postgres` ownership with secure permissions and checksums enabled. |
| V-206604 | Not a Finding | Cryptographic protection appropriate for system classification is enforced through FIPS-enabled OS crypto policy and restricted database access. Ansible verifies FIPS mode and system crypto policy. | Database stores internal DevOps operational data and runs in isolated localhost environment. |
| V-206605 | Not a Finding | Required cryptographic protection provided through OS-level FIPS cryptographic modules and strict security configuration. PostgreSQL inherits cryptographic protections from the operating system. | FIPS mode active and PostgreSQL uses system OpenSSL library with FIPS-approved algorithms. |
| V-233495 | Not a Finding | PostgreSQL deployment uses vendor-supported packages linked to FIPS-approved OpenSSL libraries and operates in FIPS mode. Ansible verifies system cryptographic configuration. | DBMS compatible with NSA-approved cryptographic standards. |
| V-265854 | Not a Finding | PostgreSQL version 16.x deployed on supported RHEL 8.x platform. System receives vendor security updates and no unsupported components are installed. Ansible validates DBMS version and package sources. | PostgreSQL and associated components remain within vendor support lifecycle. |

---

# Automation Architecture

The STIG implementation is automated using Ansible roles.

Example repository structure: