-- ============================================================
-- PostgreSQL SRG — Revoke PUBLIC Schema Privileges
-- Removes unnecessary PUBLIC privileges from application
-- schemas and databases.
--
-- Usage:
--   psql -d <database> -f revoke_public.sql
--
-- References: V-206521, V-206544
-- ============================================================

-- Revoke CREATE on the current database from PUBLIC
REVOKE CREATE ON DATABASE current_database() FROM PUBLIC;

-- Revoke CREATE and USAGE on public schema from PUBLIC
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- ============================================================
-- Audit: check remaining PUBLIC privileges
-- ============================================================

-- Check database-level privileges
SELECT datname,
       has_database_privilege('public', datname, 'CREATE') AS public_can_create
FROM pg_database
WHERE datistemplate = false;

-- Check schema-level privileges
SELECT nspname,
       has_schema_privilege('public', oid, 'CREATE') AS public_can_create,
       has_schema_privilege('public', oid, 'USAGE')  AS public_can_usage
FROM pg_namespace
WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast');

-- Check for PUBLIC grants on tables
SELECT schemaname, tablename, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'PUBLIC'
  AND table_schema NOT IN ('pg_catalog', 'information_schema');
