-- ============================================================
-- V-206520 — Authentication / Isolation Validation
-- Output: key=value pairs for Ansible parsing
-- ============================================================

-- 1. Listen addresses
SELECT 'listen_addresses=' || current_setting('listen_addresses');

-- 2. Count login roles (excluding postgres)
SELECT 'login_role_count='
  || count(*)::text
FROM pg_roles
WHERE rolcanlogin = true
  AND rolname != 'postgres';

-- 3. List login roles (comma-separated)
SELECT 'login_roles='
  || coalesce(string_agg(rolname, ','), '')
FROM pg_roles
WHERE rolcanlogin = true
  AND rolname != 'postgres';
