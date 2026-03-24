-- ============================================================
-- V-265854 — PostgreSQL Version Validation
-- Output: key=value pairs for Ansible parsing
-- ============================================================

-- Full version string (e.g. 16.4)
SELECT 'server_version=' || current_setting('server_version');

-- Major version only (e.g. 16)
SELECT 'major_version=' || split_part(current_setting('server_version'), '.', 1);
