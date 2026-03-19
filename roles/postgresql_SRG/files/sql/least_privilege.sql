-- ============================================================
-- PostgreSQL SRG — Least-Privilege Access Model
-- Hardens default privileges and grants minimal access to
-- the readonly role for application schemas.
--
-- Usage:
--   psql -d <database> -f least_privilege.sql
--
-- References: V-206521, V-206544, V-206548, V-206600
-- ============================================================

-- ============================================================
-- 1. Harden default privileges on public schema
--    Prevents future objects from inheriting PUBLIC access
-- ============================================================
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL ON TABLES FROM PUBLIC;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL ON SEQUENCES FROM PUBLIC;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL ON FUNCTIONS FROM PUBLIC;

-- ============================================================
-- 2. Grant minimal access to readonly role
-- ============================================================

-- Grant USAGE on public schema (read-only needs this)
GRANT USAGE ON SCHEMA public TO app_readonly;

-- Grant SELECT on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;

-- Grant SELECT on future tables automatically
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO app_readonly;

-- ============================================================
-- 3. Restrict DDL to authorized role only
-- ============================================================

-- Only db_ddl and postgres should be able to create objects
-- (CREATE was already revoked from PUBLIC in revoke_public.sql)
GRANT CREATE ON SCHEMA public TO db_ddl;

-- ============================================================
-- 4. Set connection limits for application roles
--    (prevents connection exhaustion attacks)
-- ============================================================
-- ALTER ROLE sonar CONNECTION LIMIT 30;
-- ALTER ROLE stig_validate_role CONNECTION LIMIT 5;
-- ALTER ROLE stig_limited CONNECTION LIMIT 5;

-- ============================================================
-- Audit: verify privilege assignments
-- ============================================================

-- Default privileges
SELECT * FROM pg_default_acl;

-- Role memberships
SELECT r.rolname AS role,
       m.rolname AS member_of
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
ORDER BY r.rolname;

-- Superuser audit
SELECT rolname, rolsuper, rolcanlogin
FROM pg_roles
WHERE rolsuper = true;
