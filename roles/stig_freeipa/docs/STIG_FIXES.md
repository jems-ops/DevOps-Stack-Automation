# STIG FreeIPA — Fixes & Enforcement Summary

## Overview

This document summarises fixes applied to the `stig_freeipa` role and describes
what each networking enforcement task does. Task files are preserved even when a
control is excluded from the active run.

---

## Bug Fixes Applied

### 1. Kerberos Ticket Expiry (V-205157 validation)

**Problem:** `klist` returns `rc=0` even for expired tickets, so the pre-check
passed but `ipa dnszone-find` subsequently failed with `Ticket expired`.

**Fix:**
- Changed `klist` → `klist -s` which returns non-zero for expired/missing tickets.
- Added a `kinit admin` renewal step (via `expect` module, `no_log: true`) that
  runs only when the ticket is expired or missing.
- Added `freeipa_admin_password` default to `stig_freeipa/defaults/main.yml`.

---

### 2. Hardcoded `named` Service Name

**Problem:** All enforcement and validation tasks hardcoded `named` as the DNS
service name. FreeIPA can use either `named` or `named-pkcs11` depending on
the installation configuration.

**Fix:**
- `common-dns-facts.yml` now auto-detects the active DNS service at runtime:
  ```bash
  systemctl list-units --type=service --state=running \
    | grep -oE 'named[a-z0-9-]*\.service' | head -1 | sed 's/\.service//'
  ```
- Sets `dns_service_name` fact used everywhere (journal collection, health check,
  validation conditionals).
- `post-health-check.yml` uses `{{ dns_service_name | default('named') }}`.

---

### 3. Duplicate Service Check Tasks

**Problem:** 10 validation files each duplicated `systemctl is-active named`
independently. 8 enforcement files each duplicated `Ensure named/journald
is enabled/running` blocks.

**Fix:**
- `common-dns-facts.yml` gathers all shared DNS facts once:
  `dns_named_active`, `dns_named_journal`, `dns_domain`, `dns_named_conf`,
  `dns_ns_records`, `dns_dnssec_config`, `dns_dnssec_keys`, `dns_zone_files`.
- All validation tasks removed their individual `systemctl is-active` checks
  and use the shared `dns_named_active` fact via `when: dns_named_active | bool`.
- Duplicate `journalctl -u named` calls removed from V-205160 and V-205224
  validation; replaced with `dns_named_journal` fact.
- Duplicate service ensure tasks removed from all 8 enforcement files.

---

### 4. `named-pkcs11.service` is Masked (Cannot Be Enabled by systemd)

**Problem:** `named-pkcs11.service` is masked by design — FreeIPA manages it
via `ipactl`, not direct systemd. Attempting `systemd: name: named-pkcs11,
enabled: true` caused a fatal error.

**Fix:**
- Removed direct systemd enable/start of `named-pkcs11` from all tasks.
- Health check and enforcement now use the `dns_service_name` variable
  (auto-detected at runtime) rather than a hardcoded unit name.
- Handlers use `ipactl restart {{ dns_service_name }}` instead of `systemctl`.

---

### 5. `resolve-dns-facts.yml` → `common-dns-facts.yml`

**Problem:** `resolve-dns-facts.yml` was a helper file that duplicated many
checks already done per-task.

**Fix:**
- Renamed and improved to `common-dns-facts.yml`.
- Added `dns_service_name` detection and `dns_named_journal` fact.
- Included in `tasks/main.yml` with `apply: tags: [always]` so inner tasks
  always run regardless of tag filtering (`--tags validation`, `--tags enforcement`).

---

### 6. Controls Excluded from Active Run

The following controls have task files preserved in the role but are **not
included** in the active enforcement or validation run. They are commented out
in `enforcement/main.yml` and `validation/main.yml`:

| Control | Title | Reason |
|---|---|---|
| V-205230 | NS Record Validation | Not applicable in FreeIPA-managed DNS |
| V-205231 | DNSSEC Key File Protection | DNSSEC not enabled |
| V-205233 | SOA Consistency | FreeIPA manages SOA internally |
| V-205235 | DNSSEC FIPS-Compliant Algorithms | DNSSEC not enabled |
| V-205236 | DNS Zone Separation | Not applicable in single-server FreeIPA |

To re-enable any control, uncomment its `include_tasks` block in both
`enforcement/main.yml` and `validation/main.yml`.

---

## Enforcement Task Summary — Networking Controls

### V-205157 — Zone Transfer Restriction
**Status:** NOT A FINDING
**Strategy:** Informational enforcement — FreeIPA manages zone transfer ACLs
(`idnsallowtransfer`) via LDAP. No direct file edits to avoid conflicts with
FreeIPA's DNS management layer. Validation confirms `Allow transfer: none;`
on all zones via `ipa dnszone-show`.

---

### V-205158 — Dynamic Update Client Restriction
**Status:** NOT A FINDING
**Strategy:** Informational enforcement — FreeIPA enforces dynamic update
restrictions via LDAP-backed `update-policy` using GSS-TSIG (Kerberos). The
`idnsupdatepolicy` field uses `krb5-self` grants, restricting updates to
Kerberos-authenticated hosts only. No anonymous or wildcard grants are present.

---

### V-205160 — DNS Audit Record Generation
**Status:** NOT A FINDING
**Strategy:** Verifies `systemd-journald` is active. FreeIPA DNS relies on
journald for audit record generation — lifecycle, query, and failure events
are captured automatically by systemd. No changes to `named.conf` are made
to avoid conflicting with FreeIPA's configuration management.

---

### V-205161 — DNS Audit Event Type Logging
**Status:** NOT A FINDING
**Strategy:** Verifies `systemd-journald` is active. Journald automatically
captures structured event type information (start/stop, errors, queries) for
the DNS service. The validation confirms presence of lifecycle and activity
log entries in journald output.

---

### V-205224 — Audit Records for Named Service Start/Stop
**Status:** NOT A FINDING
**Strategy:** Ensures `systemd-journald` is running. Journald records all
service lifecycle events automatically. Validation checks for `listening`,
`loading`, and `stopping` keywords in the DNS service journal output.

---

### V-205225 — DNSSEC FIPS Cryptographic Modules
**Status:** NOT APPLICABLE
**Strategy:** Informational only — DNSSEC is not enabled in this FreeIPA
environment. No DNSSEC keys, signed zones, or cryptographic operations exist.
If DNSSEC is introduced in the future, RSASHA256/ECDSA algorithms with
FIPS-validated modules must be enforced.

---

### V-205227 — NSEC3 Salt Rotation
**Status:** NOT APPLICABLE
**Strategy:** Informational only — DNSSEC (including NSEC3) is not enabled.
No signed zones or NSEC3 records exist. If DNSSEC with NSEC3 is introduced,
salt values must be rotated during each complete zone re-signing.

---

### V-205230, V-205231, V-205233, V-205235, V-205236 — Excluded Controls
**Status:** Task files preserved, excluded from active run.
See exclusion table above for reasons. Re-enable by uncommenting entries in
`enforcement/main.yml` and `validation/main.yml`.
