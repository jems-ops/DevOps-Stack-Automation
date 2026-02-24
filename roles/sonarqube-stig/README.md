# sonarqube-stig

Wrapper Ansible role that applies the upstream **RHEL8 DISA STIG** baseline (vendored in this repo as `roles/rhel8-stig`) with a place to add SonarQube-specific tailoring.

## What this role does

- Validates the target OS is EL8 (optional)
- Includes the upstream `rhel8-stig` role
- Allows passing a dictionary of overrides to disable/tune specific STIG rules

## Role Variables

```yaml
# Master enable/disable
sonarqube_stig_enabled: true

# Run the upstream baseline role
sonarqube_stig_run_rhel8_stig: true

# Safety check
sonarqube_stig_enforce_el8: true

# Variables to pass through to the upstream roles/rhel8-stig role
sonarqube_stig_rhel8_stig_vars: {}
```

## Example playbook usage
```yaml
---
- name: Apply SonarQube-tailored RHEL8 STIG
  hosts: sonarqube
  become: true
  roles:
    - role: sonarqube-stig
      vars:
        # Tailoring examples (adjust for your environment)
        sonarqube_stig_rhel8_stig_vars:
          DISA_STIG_RHEL_08_040135: false
          package_fapolicyd_installed: false
```

## STIG tailoring / exceptions
In this repo, exceptions are tracked for the `sonarqube` host group in `group_vars/sonarqube/main.yml` under:
- `sonarqube_stig_exceptions` (human-readable register)
- `sonarqube_stig_rhel8_stig_vars` (actual override map applied to the upstream role)

### Current exception register (copy/paste into Confluence)
```yaml
sonarqube_stig_exceptions:
  - id: DISA_STIG_RHEL_08_010358
    var: DISA_STIG_RHEL_08_010358
    value: false
    reason: Rocky 9 does not ship a 'mailx' package (commonly replaced by s-nail).
  - id: DISA_STIG_RHEL_08_010358
    var: package_mailx_installed
    value: false
    reason: Skip mailx install gate on Rocky 9.
  - id: DISA_STIG_RHEL_08_040310
    var: aide_verify_acls
    value: false
    reason: Avoid upstream conditional type issue; revisit later.
  - id: DISA_STIG_RHEL_08_040300
    var: aide_verify_ext_attributes
    value: false
    reason: Avoid upstream conditional type issue; revisit later.
  - id: DISA_STIG_RHEL_08_020210
    var: DISA_STIG_RHEL_08_020210
    value: false
    reason: Prevent immediate password expiration of existing accounts during automation.
  - id: DISA_STIG_RHEL_08_020210
    var: accounts_password_set_max_life_existing
    value: false
    reason: Prevent immediate password expiration of existing accounts during automation.
  - id: DISA_STIG_RHEL_08_020180
    var: DISA_STIG_RHEL_08_020180
    value: false
    reason: Avoid forced password aging changes during automation.
  - id: DISA_STIG_RHEL_08_020180
    var: accounts_password_set_min_life_existing
    value: false
    reason: Avoid forced password aging changes during automation.
```

## Running the STIG playbook
Recommended entrypoint:
- `playbooks/services/sonarqube-stig.yml`
  - always runs the upstream base OS hardening first (`roles/rhel8-stig` via `playbooks/baseos/rhel8-stig.yml`)
  - then applies the SonarQube wrapper role (`roles/sonarqube-stig`) without re-running the full baseline again

Examples:
```bash
# Prompt for SSH + sudo password (lab-style)
ansible-playbook -i inventory playbooks/services/sonarqube-stig.yml -kK

# Target a specific host or group
ansible-playbook -i inventory playbooks/services/sonarqube-stig.yml -kK -e target_hosts=sonar.local
ansible-playbook -i inventory playbooks/services/sonarqube-stig.yml -kK -e target_hosts=sonarqube

# Dry-run / preview changes
ansible-playbook -i inventory playbooks/services/sonarqube-stig.yml -kK --check
```

If you only want the upstream baseline (base OS stage) and nothing else:
```bash
ansible-playbook -i inventory playbooks/baseos/rhel8-stig.yml -kK -e target_hosts=sonarqube
```

## Notes
- This repo vendors the upstream baseline as a git submodule at `roles/rhel8-stig`.
  After cloning, run `git submodule update --init --recursive`.
- Base OS tailoring overrides for the upstream `rhel8-stig` role are applied from `baseos_rhel8_stig_vars`.
- SonarQube wrapper tailoring overrides are tracked in `group_vars/sonarqube/main.yml` under:
  - `sonarqube_stig_exceptions` (human-readable register)
  - `sonarqube_stig_rhel8_stig_vars` (applied when the wrapper runs the upstream baseline)
