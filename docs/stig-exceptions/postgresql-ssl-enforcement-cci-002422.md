# PostgreSQL STIG Exception (POA&M / Risk Acceptance)
## Control
- STIG ID: (TBD for your PostgreSQL STIG release)
- CCI: CCI-002422
- Title: SSL/TLS enforcement (`ssl=on`) and `hostssl` + client certificate validation (`clientcert=1`)

## Finding
### Parameter: `ssl`
- Expected: `ssl = on`
- Detected: `ssl = off`

### `pg_hba.conf` rules (SSL enforcement)
- Expected:
  - Connection type should be `hostssl`
  - Rules should include `clientcert=1` (client certificate validation)
- Detected (example):
  - `local all all trust`
  - `host all all 127.0.0.1/32 md5`
  - `host all all ::1/128 md5`

## Justification for Exception
This PostgreSQL instance is operating within an isolated, non-internet-accessible boundary.
SSL/TLS enforcement and client certificate integration with enterprise PKI are scheduled for implementation during the production deployment phase.

## Risk Mitigation / Compensating Controls
The following compensating controls are in place to reduce risk while SSL/TLS and client certificate validation are pending:
1. Localhost-only database access (where applicable)
2. Firewall restrictions / restricted network exposure
3. Encrypted network segment (where applicable)
4. OS STIG hardening applied
5. Strong password policies for database roles
6. Audit / security logging enabled (as configured)

## Risk Statement
While SSL/TLS and client certificate validation are preferred, the current implementation is intended for controlled use within a restricted boundary.
Risk is accepted temporarily until enterprise PKI integration and production deployment hardening are implemented.

## Remediation Plan (POA&M)
- Planned remediation: Enable `ssl=on`, enforce `hostssl` rules in `pg_hba.conf`, and require client certificates (`clientcert=1`) with enterprise PKI.
- Target completion date: TBD
- Owner: TBD
- Approver (risk acceptance): TBD
