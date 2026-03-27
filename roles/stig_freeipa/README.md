# stig_freeipa

STIG hardening role for FreeIPA web server (Apache httpd + Tomcat/Dogtag CA).

Applies enforcement, validation, and post-health-check for DISA STIG controls targeting the FreeIPA web application stack.

## STIG Controls

All controls are **CAT II** severity.

| STIG ID | SRG ID | Description |
|---------|--------|-------------|
| V-264341 | SRG-APP-000805 | Web server must generate audit records |
| V-206412 | SRG-APP-000266-WSR-000159 | Minimize web server identity in headers |
| V-206433 | SRG-APP-000516-WSR-000174 | Tune web server to prevent DoS |
| V-206437 | SRG-APP-000439-WSR-000154 | Protect cookies with HttpOnly/Secure |
| V-206374 | SRG-APP-000141-WSR-000015 | No local user management (.htpasswd) |
| V-206380 | SRG-APP-000141-WSR-000081 | Disable MIME types invoking OS shell (ExecCGI) |
| V-206383 | SRG-APP-000141-WSR-000075 | Disable WebDAV |

## Role Structure

```
stig_freeipa/
├── defaults/main.yml              # Default variables
├── handlers/main.yml              # Service restart handlers
├── tasks/
│   ├── main.yml                   # Orchestrates enforcement → validation → health check
│   ├── enforcement/
│   │   ├── main.yml               # Includes all enforcement tasks
│   │   ├── V-264341.yml           # Audit logging
│   │   ├── V-206412.yml           # Header hardening
│   │   ├── V-206433.yml           # DoS tuning
│   │   ├── V-206437.yml           # Cookie flags
│   │   ├── V-206374.yml           # Local user management
│   │   ├── V-206380.yml           # ExecCGI
│   │   └── V-206383.yml           # WebDAV
│   ├── validation/
│   │   ├── main.yml               # Includes all validation tasks
│   │   ├── V-264341_validate.yml
│   │   ├── V-206412_validate.yml
│   │   ├── V-206433_validate.yml
│   │   ├── V-206437_validate.yml
│   │   ├── V-206374_validate.yml
│   │   ├── V-206380_validate.yml
│   │   └── V-206383_validate.yml
│   └── post-health-check.yml      # Service/port/endpoint verification
├── vars/main.yml
├── meta/main.yml
└── tests/
```

## Execution Flow

1. **Enforcement** — applies all STIG remediations
2. **Flush handlers** — restarts httpd/auditd so changes take effect
3. **Validation** — verifies each control is compliant
4. **Health check** — confirms all FreeIPA services, ports, and endpoints are healthy

## Requirements

- FreeIPA server installed and running (use `install-freeipa` role)
- Target host in the `[freeipa]` inventory group
- Ansible 2.9+

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `freeipa_srg_httpd_conf` | `/etc/httpd/conf/httpd.conf` | Path to Apache httpd config |

## How to Run

**Run all STIG controls:**

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml
```

**Run enforcement only:**

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags enforcement
```

**Run validation only:**

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags validation
```

**Run health check only:**

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags health-check
```

**Run a specific control:**

```bash
ansible-playbook -i inventory playbooks/apply-stig-freeipa.yml --tags V-206383
```

## Playbook

`playbooks/apply-stig-freeipa.yml`:

```yaml
---
- name: Apply STIG Hardening to FreeIPA Server
  hosts: freeipa
  gather_facts: yes
  become: yes
  roles:
    - stig_freeipa
```

## Adding New Controls

1. Create enforcement task: `tasks/enforcement/V-XXXXXX.yml`
2. Create validation task: `tasks/validation/V-XXXXXX_validate.yml`
3. Add include entries in `tasks/enforcement/main.yml` and `tasks/validation/main.yml`

## License

MIT
