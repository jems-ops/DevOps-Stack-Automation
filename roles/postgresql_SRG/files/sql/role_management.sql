-- ============================================================
-- PostgreSQL SRG — Role Management
-- Creates and verifies DBA group, readonly role, and
-- application service account roles.
--
-- Usage:
--   psql -d postgres -f role_management.sql
--
-- References: V-206520, V-206521, V-206545, V-206600
-- ============================================================

-- DBA administrative group
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dbadmins') THEN
    CREATE ROLE dbadmins NOSUPERUSER NOCREATEDB NOCREATEROLE NOLOGIN;
    RAISE NOTICE 'Created role: dbadmins';
  ELSE
    RAISE NOTICE 'Role already exists: dbadmins';
  END IF;
END $$;

-- Grant dbadmins to postgres (DBA membership)
GRANT dbadmins TO postgres;

-- Read-only application role (no login, no elevated privs)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_readonly') THEN
    CREATE ROLE app_readonly NOSUPERUSER NOCREATEDB NOCREATEROLE NOLOGIN;
    RAISE NOTICE 'Created role: app_readonly';
  ELSE
    RAISE NOTICE 'Role already exists: app_readonly';
  END IF;
END $$;

-- STIG validation role (limited, no superuser)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stig_validate_role') THEN
    CREATE ROLE stig_validate_role LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
    RAISE NOTICE 'Created role: stig_validate_role';
  ELSE
    RAISE NOTICE 'Role already exists: stig_validate_role';
  END IF;
END $$;

-- STIG limited role
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stig_limited') THEN
    CREATE ROLE stig_limited LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
    RAISE NOTICE 'Created role: stig_limited';
  ELSE
    RAISE NOTICE 'Role already exists: stig_limited';
  END IF;
END $$;

-- DDL role (for V-206548)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'db_ddl') THEN
    CREATE ROLE db_ddl NOSUPERUSER NOCREATEDB NOCREATEROLE NOLOGIN;
    RAISE NOTICE 'Created role: db_ddl';
  ELSE
    RAISE NOTICE 'Role already exists: db_ddl';
  END IF;
END $$;

-- ============================================================
-- Audit: list all roles and their attributes
-- ============================================================
SELECT rolname,
       rolsuper    AS superuser,
       rolcanlogin AS can_login,
       rolcreatedb AS createdb,
       rolcreaterole AS createrole,
       rolconnlimit AS conn_limit
FROM pg_roles
ORDER BY rolname;
