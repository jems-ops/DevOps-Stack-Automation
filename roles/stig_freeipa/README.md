# stig_freeipa

DISA STIG hardening role for a FreeIPA server. Covers the full FreeIPA application
stack — Apache httpd, PKI Tomcat/Dogtag CA, and the FreeIPA DNS service (named /
named-pkcs11). Applies enforcement, validation, and a post-health-check in a single
playbook run.

## Requirements

- FreeIPA server installed and running (use the `install-freeipa` role first)
- Target host in the `[freeipa]` inventory group
- Ansible 2.12+ with `ansible.posix` collection
- Vault password file at `.vault_pass` (credentials managed via `group_vars/all/vault.yml`)

---

## STIG Controls

All controls are **CAT II** severity.

### Webserver Controls (httpd / PKI Tomcat)

| STIG ID | Description | Result |
|---------|-------------|--------|
| V-264341 | Web server must generate audit records | Enforced |
| V-222998 | Changes to Tomcat `bin/` must be logged (auditd) | Enforced |
| V-222999 | Changes to Tomcat `conf/` must be logged (auditd) | Enforced |
| V-223000 | Changes to Tomcat `lib/` must be logged (auditd) | Enforced |
| V-206374 | Web server must not perform local user management | Enforced |
| V-206412 | Minimize web server identity in HTTP headers | Enforced |
| V-206437 | Protect session cookies with HttpOnly and Secure flags | Enforced |
| V-206380 | Disable MIME types that invoke OS shell programs (ExecCGI) | Enforced |
| V-206383 | Disable WebDAV | Enforced |
| V-206433 | Tune web server to prevent DoS (connection/timeout limits) | Enforced |

### DNS Controls (named / named-pkcs11)

> DNS service is auto-detected at runtime (`named` or `named-pkcs11`).

| STIG ID | Description | Result |
|---------|-------------|--------|
| V-205157 | Restrict zone transfers to authorized secondary servers | NOT A FINDING |
| V-205158 | Limit dynamic update clients via GSS-TSIG (Kerberos) | NOT A FINDING |
| V-205160 | DNS must generate audit records for DoD-defined events | NOT A FINDING |
| V-205161 | DNS audit records must contain event type information | NOT A FINDING |
| V-205224 | Audit records for DNS service start/stop events | NOT A FINDING |
| V-205225 | DNSSEC must use FIPS-validated cryptographic modules | NOT APPLICABLE |
| V-205227 | NSEC3 salt must be rotated on every zone re-signing | NOT APPLICABLE |
| V-205228 | RRSIG validity period must be 2–7 days | NOT APPLICABLE |
| V-205230 | NS records must point to active authoritative servers | NOT A FINDING |
| V-205231 | DNSSEC key files must have restricted permissions | NOT APPLICABLE |
| V-205233 | DNS configuration consistency (single NS server) | NOT A FINDING |
| V-205235 | DNSSEC must use FIPS-compliant signing algorithms | NOT APPLICABLE |
| V-205236 | DNS must be internal-only (no external exposure) | NOT A FINDING |

> **DNSSEC controls** are NOT APPLICABLE because DNSSEC is not enabled in this
> FreeIPA deployment. Network controls act as compensating controls.

### Auditing (named service)

| Control | Description | Result |
|---------|-------------|--------|
| Named Audit Rules | auditd file watches for named binary, `named.conf`, `/var/named` | NOT A FINDING |

---

## Role Structure

```
stig_freeipa/
├── defaults/
│   └── main.yml                       # Default variables (freeipa_admin_password, etc.)
├── handlers/
│   └── main.yml                       # Handlers: restart httpd, auditd, named-pkcs11, journald
├── tasks/
│   ├── main.yml                       # Orchestrator: shared setup → enforcement → validation → health check
│   ├── common/
│   │   ├── webserver/                 # Webserver enforcement (httpd / PKI Tomcat)
│   │   │   ├── main.yml
│   │   │   ├── resolve-tomcat-paths.yml  # Resolves PKI Tomcat symlink paths
│   │   │   └── V-2641341/222998/999/000/206374/380/383/412/433/437.yml
│   │   └── dns/                       # DNS enforcement (named / named-pkcs11)
│   │       ├── main.yml
│   │       ├── common-dns-facts.yml      # Shared DNS facts (dns_named_active, dns_named_journal, etc.)
│   │       ├── named-audit-rules.yml     # auditd rules for named (enforcement + validation)
│   │       └── V-205157/158/160/161/224/225/227/228/230/231/233/235/236.yml
│   ├── validation/
│   │   ├── main.yml                   # Orchestrates all validation tasks
│   │   ├── auditing/                  # V-264341, V-222998/999/000 validation
│   │   ├── authentication/            # V-206374 validation
│   │   ├── availability/              # V-206433 validation
│   │   ├── networking/                # V-205157–V-205236 validation
│   │   └── security-hardening/        # V-206380/383/412/437 validation
│   ├── post-health-check.yml          # Verifies services, ports, web endpoints
│   ├── backup-configs.yml             # Snapshots configs before enforcement
│   └── rollback-configs.yml           # Restores pre-STIG configs from backup
├── docs/
│   ├── MANUAL_VERIFICATION.md         # Manual verification steps for all controls
│   ├── STIG_FIXES.md                  # Bug fix changelog and enforcement strategy
│   └── FREEIPA_UI_FIX.md
├── defaults/main.yml
├── handlers/main.yml
└── meta/main.yml
```

---

## Execution Flow

```
tasks/main.yml
  1. backup-configs.yml          — snapshot configs (--tags backup)
  2. resolve-tomcat-paths.yml    — resolve PKI Tomcat symlinks (always)
  3. common-dns-facts.yml        — gather DNS service facts (always)
  4. named-audit-rules.yml       — enforce + validate named auditd rules
  5. common/webserver/main.yml   — enforce all webserver controls
  6. common/dns/main.yml         — enforce all DNS controls
  7. flush_handlers              — apply pending restarts before validation
  8. validation/main.yml         — validate all controls
  9. post-health-check.yml       — verify service health
```

---

## Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `freeipa_admin_password` | `FreeIPA123!` | Admin password for `kinit` during validation |
| `freeipa_admin_user` | `admin` | FreeIPA admin username |

> Sensitive values should be stored in `group_vars/all/vault.yml`
> using `vault_freeipa_admin_password`.

---

## How to Run

### Prerequisites

```bash
# Verify connectivity
ansible freeipa -i inventory -m ping

# Verify FreeIPA services are running
ansible freeipa -i inventory -m shell -a "ipactl status"
```

### Run Full Playbook (Enforcement + Validation + Health Check)

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml
```

### Run Enforcement Only

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags enforcement
```

### Run Validation Only

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags validation
```

### Run Health Check Only

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags health-check
```

### Run a Specific Control

```bash
# Single control
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags V-205157

# Multiple controls
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags "V-205157,V-205158"
```

### Run DNS Controls Only

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml \
  --tags "V-205157,V-205158,V-205160,V-205161,V-205224,V-205225,V-205227,V-205228,V-205230,V-205231,V-205233,V-205235,V-205236"
```

### Rollback to Pre-STIG State

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags rollback
```

### Backup Configs Only

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags backup
```

---

## Playbook

`playbooks/apply-stig-freeipa.yml`:

```yaml
---
- name: Apply STIG Hardening to FreeIPA Server
  hosts: freeipa
  gather_facts: true
  become: true
  roles:
    - stig_freeipa
```

---

## Adding a New Control

1. **Enforcement task** — create `tasks/common/webserver/V-XXXXXX.yml` or
   `tasks/common/dns/V-XXXXXX.yml` depending on the application area.
2. **Validation task** — create `tasks/validation/<category>/V-XXXXXX_validate.yml`.
3. **Wire it up** — add `include_tasks` entries in `common/<category>/main.yml`
   and `validation/main.yml`.
4. **Manual steps** — add a section to `docs/MANUAL_VERIFICATION.md`.

---

## Documentation

| File | Description |
|------|-------------|
| `docs/MANUAL_VERIFICATION.md` | Manual verification commands for all controls |
| `docs/STIG_FIXES.md` | Enforcement strategy and bug fix changelog |

---

## License

MIT
