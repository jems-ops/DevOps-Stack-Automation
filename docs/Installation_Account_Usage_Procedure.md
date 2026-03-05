Installation Account Usage Procedure

Control Reference: V-206545
System: PostgreSQL DBMS
Applies To: DBMS Software Installation Account (postgres)
Classification: Administrative + Technical Control

⸻

1. Purpose

This procedure defines the requirements and controls governing the use of the PostgreSQL DBMS installation account (postgres).

The objective is to:
	•	Restrict use of the installation account to authorized personnel only
	•	Prevent routine operational use
	•	Ensure all usage is logged and auditable
	•	Maintain least privilege and accountability

⸻

2. Scope

This procedure applies to:
	•	All PostgreSQL database servers
	•	All environments (Development, Test, Production)
	•	All system administrators and database administrators (DBAs)

⸻

3. Definition

The DBMS installation account refers to:
	•	OS account: postgres
	•	Database superuser role: postgres

This account has unrestricted access and can:
	•	Modify database configuration
	•	Create or alter superusers
	•	Bypass access controls
	•	Modify audit settings
	•	Access all database objects

Because of its elevated privileges, strict governance is required.

⸻

4. Policy Requirements

4.1 Authorized Use

The postgres account may only be used for:
	•	Initial DBMS installation
	•	Emergency maintenance
	•	Security configuration changes
	•	Audit configuration changes
	•	Superuser-level recovery operations

It must NOT be used for:
	•	Application connections
	•	Routine database queries
	•	Daily operational tasks
	•	Development activities

⸻

4.2 Access Restrictions

The following restrictions shall be enforced:
	•	Direct SSH login as postgres is prohibited
	•	Password authentication for postgres is disabled or locked
	•	Access must occur via authorized sudo elevation
	•	Use requires prior approval (ticket or change request)

Example approved method:

sudo -u postgres psql


⸻

4.3 Authentication Requirements
	•	Access must be performed using an individual named account
	•	Shared accounts are prohibited
	•	Multi-factor authentication (MFA) is required where supported
	•	sudo access must be restricted to approved DBAs

⸻

4.4 Logging and Auditing

All usage of the installation account must be logged:
	•	OS-level sudo logs
	•	PostgreSQL connection logs
	•	Session activity logs (pgaudit enabled)
	•	Centralized SIEM ingestion (if applicable)

Required PostgreSQL settings:

log_connections = on
log_disconnections = on
pgaudit.log = 'all'


⸻

4.5 Monitoring and Review
	•	Installation account usage must be reviewed at least monthly
	•	Emergency usage must be reviewed within 72 hours
	•	Any unauthorized use must be investigated

Audit review includes:
	•	Who accessed the account
	•	When access occurred
	•	What actions were performed
	•	Whether access was authorized

⸻

4.6 Superuser Control

The number of superuser accounts must be minimized.

Validation query:

SELECT rolname FROM pg_roles WHERE rolsuper = true;

Only approved accounts shall have superuser privileges.

⸻

5. Emergency Access Procedure

In case of emergency:
	1.	Change ticket must be opened
	2.	Approval from Security or System Owner required
	3.	Access performed via sudo
	4.	Activities documented in ticket
	5.	Logs reviewed post-event

⸻

6. Prohibited Actions

The following actions are strictly prohibited:
	•	Sharing the postgres account
	•	Embedding postgres credentials in applications
	•	Allowing direct SSH login as postgres
	•	Disabling audit logging
	•	Creating undocumented superusers

Violation may result in disciplinary action.

⸻

7. Technical Enforcement Summary

Control	Implementation
Password disabled	passwd -l postgres
No direct SSH login	sshd_config restriction
sudo logging	/var/log/secure or journal
Session auditing	PostgreSQL log settings
Superuser review	Periodic SQL validation


⸻

8. Compliance Evidence

The following artifacts demonstrate compliance with V-206545:
	•	/etc/passwd showing locked postgres account
	•	SSH configuration showing restricted login
	•	PostgreSQL logs showing audited sessions
	•	sudo logs showing user elevation
	•	This documented procedure
	•	Change management tickets

⸻

9. Review and Maintenance

This procedure shall be reviewed:
	•	Annually
	•	After major PostgreSQL upgrades
	•	After security incidents
	•	Upon STIG updates

⸻

10. Approval

Role	Name	Date
System Owner
Security Officer
DBA Lead


⸻

Compliance Statement

This procedure satisfies SRG control V-206545 by documenting and enforcing restrictions and monitoring requirements for the DBMS installation account.
