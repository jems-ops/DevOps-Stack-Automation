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
├── defaults/main.yml              # Role variables (freeipa_admin_password, etc.)
├── handlers/main.yml              # Service restart handlers (httpd, auditd, named)
├── docs/
│   ├── MANUAL_VERIFICATION.md     # Manual verification steps per control
│   └── STIG_FIXES.md              # Fix changelog and enforcement strategy
└── tasks/
    ├── main.yml                   # Orchestrator (entry point)
    ├── common/                    # Shared helper files only (no controls here)
    │   ├── webserver/
    │   │   └── resolve-tomcat-paths.yml
    │   └── dns/
    │       ├── common-dns-facts.yml   # DNS service detection + shared facts
    │       └── named-audit-rules.yml  # V-205160 auditd rules (enforce + validate)
    ├── auditing/                  # ← add auditing controls here
    │   ├── main.yml
    │   └── V-XXXXXX.yml
    ├── authentication/            # ← add authentication controls here
    │   ├── main.yml
    │   └── V-XXXXXX.yml
    ├── hardening/                 # ← add security hardening controls here
    │   ├── main.yml
    │   └── V-XXXXXX.yml
    ├── availability/              # ← add availability controls here
    │   ├── main.yml
    │   └── V-XXXXXX.yml
    ├── networking/                # ← add DNS/networking controls here
    │   ├── main.yml
    │   └── V-XXXXXX.yml
    ├── validation/                # Validation tasks mirror enforcement structure
    │   ├── main.yml
    │   ├── auditing/
    │   ├── authentication/
    │   ├── availability/
    │   ├── networking/
    │   └── security-hardening/
    ├── backup-configs.yml
    ├── rollback-configs.yml
    └── post-health-check.yml
```

---

## Execution Flow

```
tasks/main.yml
  1. backup-configs.yml              — snapshot configs  (--tags backup)
  2. common/webserver/               — resolve Tomcat paths (always)
  3. common/dns/common-dns-facts.yml — detect DNS service, gather facts (always)
  4. common/dns/named-audit-rules.yml— V-205160 auditd rules
  5. auditing/main.yml               — enforce auditing controls
  6. authentication/main.yml         — enforce authentication controls
  7. hardening/main.yml              — enforce hardening controls
  8. availability/main.yml           — enforce availability controls
  9. networking/main.yml             — enforce networking/DNS controls
  10. flush_handlers                 — apply restarts before validation
  11. validation/main.yml            — validate all controls
  12. post-health-check.yml          — verify service health
```

---

## Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `freeipa_admin_password` | `FreeIPA123!` | Admin password for `kinit` during validation |
| `freeipa_admin_user` | `admin` | FreeIPA admin username |

> Store sensitive values in `group_vars/all/vault.yml` using `vault_freeipa_admin_password`.

---

## How to Run

### Prerequisites

```bash
# Verify connectivity
ansible freeipa -i inventory -m ping

# Verify FreeIPA is up
ansible freeipa -i inventory -m shell -a "ipactl status"
```

### Full Run (Enforcement + Validation + Health Check)

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml
```

### Enforcement Only

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags enforcement
```

### Validation Only

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags validation
```

### Health Check Only

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags health-check
```

### Single Control

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags V-205157
```

### Rollback / Backup

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags rollback
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags backup
```

---

## Adding a New Control

Pick the right category folder and follow the 4-step pattern:

**Step 1 — Create enforcement task**
```
tasks/<category>/V-XXXXXX.yml
```

**Step 2 — Register in category main.yml**
```yaml
# tasks/<category>/main.yml
- name: "V-XXXXXX | <description>"
  ansible.builtin.include_tasks:
    file: V-XXXXXX.yml
    apply:
      tags: [V-XXXXXX, enforcement]
  tags: [V-XXXXXX, enforcement]
```

**Step 3 — Create validation task**
```
tasks/validation/<category>/V-XXXXXX_validate.yml
```

**Step 4 — Register in validation/main.yml**
```yaml
# tasks/validation/main.yml
- name: "V-XXXXXX | <description>"
  ansible.builtin.include_tasks:
    file: <category>/V-XXXXXX_validate.yml
    apply:
      tags: [V-XXXXXX, validation]
  tags: [V-XXXXXX, validation]
```

> Add manual verification steps to `docs/MANUAL_VERIFICATION.md`.

---

## Playbook

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

## Documentation

| File | Description |
|------|-------------|
| `docs/MANUAL_VERIFICATION.md` | Manual verification commands for every control |
| `docs/STIG_FIXES.md` | Enforcement strategy and bug fix changelog |

---

## License

MIT
