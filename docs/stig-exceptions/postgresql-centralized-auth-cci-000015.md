# PostgreSQL STIG Exception (POA&M / Risk Acceptance)
## Control
- STIG ID: (TBD for your PostgreSQL STIG release)
- CCI: CCI-000015
- Title: Centralized authentication (enterprise identity integration)

## Finding
PostgreSQL authentication is currently configured in `pg_hba.conf` using locally-managed authentication methods, such as:
- `peer`
- `scram-sha-256`

The environment is not yet using centralized authentication methods such as:
- `gss` (Kerberos/GSSAPI)
- `sspi` (Windows SSPI)
- `ldap`

## Justification for Exception
This PostgreSQL instance is operating in a pre-production / lab environment and is awaiting enterprise identity integration.
At this time, the system is not integrated with an organization-level authentication mechanism (LDAP / Kerberos / SSPI).

Authentication is managed locally within PostgreSQL using:
- SCRAM-SHA-256 (password-based)
- Role-based access control (least privilege)

## Risk Mitigation / Compensating Controls
The following compensating controls are in place to reduce risk while centralized authentication is pending:
1. Localhost-only database access (where applicable)
2. Firewall restrictions / restricted network exposure
3. Strong password enforcement for database roles
4. Account lockout policies (where applicable)
5. Role-based least privilege
6. OS-level hardening and STIG controls applied
7. Audit / security logging enabled (as configured)
8. Encrypted connections (TLS/SSL) when applicable

## Risk Statement
While centralized authentication is preferred, the current implementation is not intended for broad external exposure.
The database is expected to operate within a controlled boundary.
Risk is accepted temporarily until enterprise identity integration is implemented.

## Remediation Plan (POA&M)
- Planned remediation: Integrate PostgreSQL authentication with enterprise IAM (LDAP and/or Kerberos) and update `pg_hba.conf` accordingly.
- Target completion date: TBD
- Owner: TBD
- Approver (risk acceptance): TBD
