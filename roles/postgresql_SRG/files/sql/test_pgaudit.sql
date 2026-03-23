-- ============================================================
-- PostgreSQL SRG — pgaudit Test Script
-- Exercises auditable operations to verify pgaudit is logging
-- DDL, DML (read/write), role changes, and connection events.
--
-- Usage:
--   psql -d sonarqube -f test_pgaudit.sql
--
-- After running, check the PostgreSQL log for audit entries:
--   sudo tail -100 /var/lib/pgsql/16/data/log/postgresql-*.log \
--     | grep AUDIT
--
-- References: V-206522, V-206523, V-206524, V-206525, V-206526,
--             V-206527, V-206528, V-206529, V-206530, V-206531,
--             V-206532, V-206533, V-206534, V-206537, V-206538,
--             V-206539, V-206540, V-206541, V-206542, V-206543,
--             V-206612, V-206620 through V-206638
-- ============================================================

-- ============================================================
-- 0. Verify pgaudit is loaded and configured
-- ============================================================
\echo '--- pgaudit configuration ---'
SHOW shared_preload_libraries;
SHOW pgaudit.log;
SHOW pgaudit.log_catalog;
SHOW pgaudit.log_relation;
SHOW pgaudit.log_statement_once;
SHOW log_connections;
SHOW log_disconnections;
SHOW log_line_prefix;
SHOW log_destination;
SHOW logging_collector;

-- ============================================================
-- 1. DDL — should appear as AUDIT: DDL in the log
--    Covers: V-206522, V-206524, V-206534, V-206612
-- ============================================================
\echo '--- DDL tests ---'

CREATE TABLE IF NOT EXISTS stig_audit_test (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    value TEXT,
    created_at TIMESTAMP DEFAULT now()
);

ALTER TABLE stig_audit_test ADD COLUMN IF NOT EXISTS notes TEXT;

CREATE INDEX IF NOT EXISTS idx_stig_audit_name ON stig_audit_test(name);

-- ============================================================
-- 2. DML WRITE — should appear as AUDIT: WRITE in the log
--    Covers: V-206523, V-206525, V-206526, V-206527, V-206528
-- ============================================================
\echo '--- DML WRITE tests ---'

INSERT INTO stig_audit_test (name, value) VALUES
    ('pgaudit_test_1', 'insert test'),
    ('pgaudit_test_2', 'insert test 2');

UPDATE stig_audit_test SET value = 'updated' WHERE name = 'pgaudit_test_1';

DELETE FROM stig_audit_test WHERE name = 'pgaudit_test_2';

-- ============================================================
-- 3. DML READ — should appear as AUDIT: READ in the log
--    Covers: V-206529, V-206530, V-206531, V-206532, V-206533
-- ============================================================
\echo '--- DML READ tests ---'

SELECT * FROM stig_audit_test;

SELECT count(*) FROM stig_audit_test WHERE name LIKE 'pgaudit%';

-- ============================================================
-- 4. ROLE — should appear as AUDIT: ROLE in the log
--    Covers: V-206538, V-206539, V-206540, V-206541, V-206600
-- ============================================================
\echo '--- ROLE tests ---'

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stig_audit_testrole') THEN
        CREATE ROLE stig_audit_testrole NOSUPERUSER NOCREATEDB NOCREATEROLE NOLOGIN;
    END IF;
END $$;

GRANT SELECT ON stig_audit_test TO stig_audit_testrole;

REVOKE SELECT ON stig_audit_test FROM stig_audit_testrole;

-- ============================================================
-- 5. FUNCTION — should appear as AUDIT: FUNCTION in the log
--    Covers: V-206542, V-206543
-- ============================================================
\echo '--- FUNCTION tests ---'

CREATE OR REPLACE FUNCTION stig_audit_testfunc()
RETURNS TEXT AS $$
BEGIN
    RETURN 'pgaudit function test';
END;
$$ LANGUAGE plpgsql;

SELECT stig_audit_testfunc();

-- ============================================================
-- 6. MISC — session logging and error events
--    Covers: V-206537 (timestamps), V-206620-V-206638 (logging)
-- ============================================================
\echo '--- MISC tests ---'

-- Trigger a logged error (division by zero)
DO $$
BEGIN
    PERFORM 1/0;
EXCEPTION WHEN division_by_zero THEN
    RAISE NOTICE 'Caught expected error: division_by_zero (audit log test)';
END $$;

-- Verify log_line_prefix contains required fields (%m %u %d %p)
SHOW log_line_prefix;

-- ============================================================
-- 7. Cleanup test objects
-- ============================================================
\echo '--- Cleanup ---'

DROP FUNCTION IF EXISTS stig_audit_testfunc();
DROP TABLE IF EXISTS stig_audit_test;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stig_audit_testrole') THEN
        DROP ROLE stig_audit_testrole;
    END IF;
END $$;

-- ============================================================
-- 8. Verification queries — confirm audit infrastructure
-- ============================================================
\echo '--- Audit infrastructure verification ---'

-- Confirm pgaudit extension is installed
SELECT extname, extversion FROM pg_extension WHERE extname = 'pgaudit';

-- Confirm shared_preload_libraries includes pgaudit
SELECT setting FROM pg_settings WHERE name = 'shared_preload_libraries';

-- Confirm pgaudit.log covers required categories
SELECT name, setting FROM pg_settings WHERE name LIKE 'pgaudit%';

-- Confirm logging parameters
SELECT name, setting FROM pg_settings
WHERE name IN (
    'log_connections',
    'log_disconnections',
    'log_line_prefix',
    'log_destination',
    'logging_collector',
    'log_directory',
    'log_filename',
    'log_min_error_statement',
    'log_min_duration_statement'
)
ORDER BY name;

\echo '--- pgaudit test complete ---'
\echo 'Check audit log:  sudo tail -100 /var/lib/pgsql/16/data/log/postgresql-*.log | grep AUDIT'
