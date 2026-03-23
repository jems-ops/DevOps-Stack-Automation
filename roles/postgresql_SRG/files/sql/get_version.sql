-- ============================================================
-- Get PostgreSQL server version (used by V-265854 validation)
-- Output: single line with version string, e.g. "16.4"
-- ============================================================
SELECT current_setting('server_version');
