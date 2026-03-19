# PostgreSQL SRG — STIG Control Mapping

## Categories

| Category | Tag | Description | Controls |
|----------|-----|-------------|----------|
| Access | `access` | Authentication, RBAC, sessions, passwords, privileges | 32 |
| Auditing | `auditing` | pgaudit, logging, audit record generation & protection | 43 |
| Config | `config` | postgresql.conf, pg_hba.conf, network, components | 6 |
| Crypto | `crypto` | FIPS, TLS, data-at-rest/transit, crypto modules | 10 |
| Lifecycle | `lifecycle` | Version management, patching, time sync, cleanup | 7 |
| Backup | `backup` | Pre-enforcement config backup with retention | N/A |

## CAT I Controls (14)

| V-ID | Category | Title |
|------|----------|-------|
| V-206520 | access | Integrate with org-level authentication |
| V-206521 | access | Enforce least-privilege access control |
| V-206545 | access | Restrict installation account usage |
| V-206555 | access | Protect password storage files |
| V-206556 | access | Store passwords using SCRAM-SHA-256 |
| V-206557 | access | Protect passwords during transmission |
| V-206559 | access | Protect PKI private keys |
| V-206561 | access | Do not display authentication secrets |
| V-206562 | crypto | Use FIPS 140-2/140-3 validated modules |
| V-206570 | crypto | Protect data at rest |
| V-206604 | crypto | Protect confidentiality of data in transit |
| V-206605 | crypto | Protect confidentiality of information |
| V-233495 | crypto | Use NSA-approved cryptography (FIPS) |
| V-265854 | lifecycle | DBMS must be a supported version |

## CAT II Controls — Access (24)

| V-ID | Title |
|------|-------|
| V-206519 | Limit concurrent sessions |
| V-206544 | Restrict DBMS software module modification |
| V-206547 | Database objects owned by authorized accounts |
| V-206548 | Restrict DDL modification to authorized users |
| V-206554 | Uniquely identify and authenticate non-org users |
| V-206565 | Invalidate session identifiers on logout |
| V-206566 | Generate session IDs using approved methods |
| V-206567 | Protect against MITM during authentication |
| V-206580 | Auto-terminate inactive sessions |
| V-206600 | Prevent privilege escalation without reauth |
| V-203602 | Disable expired accounts |
| V-203603 | Disable inactive accounts |
| V-263607 | Require individual authentication |
| V-263608 | Implement MFA where applicable |
| V-263609 | Implement MFA for non-local access |
| V-263610 | Maintain common password list |
| V-263611 | Update password list periodically |
| V-263612 | Password update requirements |
| V-263613 | Password verification on change |
| V-263614 | Password complexity requirements |
| V-263615 | Allow user-initiated password changes |
| V-263616 | Employ password encryption |
| V-263617 | Certificate status checking |
| V-263618 | Protect nonlocal maintenance sessions |

## CAT II Controls — Auditing (31)

| V-ID | Title |
|------|-------|
| V-206522 | Non-repudiation via connection logging |
| V-206523 | Generate DoD-defined audit records |
| V-206524 | Restrict audit configuration access |
| V-206525 | Audit privilege/role retrieval |
| V-206526 | Audit unsuccessful privilege attempts |
| V-206527 | Initiate session auditing on startup |
| V-206528 | Include event type in audit records |
| V-206529 | Include timestamps in audit records |
| V-206530 | Include event location in audit records |
| V-206531 | Include source/origin in audit records |
| V-206532 | Include event outcome in audit records |
| V-206533 | Include user identity in audit records |
| V-206534 | Include additional info in audit records |
| V-206537 | Use system clock for audit timestamps |
| V-206538 | Protect audit info from unauthorized read |
| V-206539 | Protect audit info from unauthorized deletion |
| V-206540 | Protect audit logs from unauthorized access |
| V-206541 | Protect audit features from unauthorized access |
| V-206542 | Protect audit config from modification |
| V-206543 | Protect audit features from unauthorized disable |
| V-206612 | Audit security-relevant configuration changes |
| V-206620–V-206638 | Audit record generation (19 sub-controls) |
| V-206642 | Off-load audit data to centralized log |
| V-203604 | Centrally review audit records |
| V-203605 | Alert personnel on audit events |

## CAT II Controls — Config (6)

| V-ID | Title |
|------|-------|
| V-206546 | Software/data directories on approved locations |
| V-206550 | Remove/disable unused DBMS components |
| V-206551 | Disable unnecessary integrated components |
| V-206552 | Restrict external executables |
| V-206553 | Restrict network ports/protocols/services |
| V-206643 | Configure in accordance with DoD security policy |

## CAT II Controls — Crypto (5)

| V-ID | Title |
|------|-------|
| V-206639 | Use FIPS modules for digital signatures |
| V-206640 | Use FIPS modules for hash generation |
| V-206641 | Implement FIPS for integrity verification |
| V-263619 | Maintain certificate trust store |
| V-263620 | Provide protected storage for crypto keys |

## CAT II Controls — Lifecycle (6)

| V-ID | Title |
|------|-------|
| V-206549 | Remove demo/sample databases and objects |
| V-206610 | Remove obsolete software components after update |
| V-206611 | Maintain latest security patches |
| V-263606 | Prevent unauthorized software installation |
| V-263621 | Synchronize system clocks |
| V-263622 | Compare clocks with authoritative source |
