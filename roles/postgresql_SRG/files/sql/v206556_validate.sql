-- ============================================================
-- V-206556 — Password Encryption Validation
-- Output: key=value pairs for Ansible parsing
-- ============================================================

-- 1. Current password_encryption setting
SELECT 'password_encryption=' || current_setting('password_encryption');

-- 2. Count roles with weak (non-SCRAM) password hashes
SELECT 'weak_hash_count='
  || count(*)::text
FROM pg_authid
WHERE rolpassword IS NOT NULL
  AND rolpassword NOT LIKE 'SCRAM-SHA-256%';

-- 3. List roles with weak hashes (comma-separated, empty if none)
SELECT 'weak_hash_roles='
  || coalesce(string_agg(rolname, ','), '')
FROM pg_authid
WHERE rolpassword IS NOT NULL
  AND rolpassword NOT LIKE 'SCRAM-SHA-256%';
