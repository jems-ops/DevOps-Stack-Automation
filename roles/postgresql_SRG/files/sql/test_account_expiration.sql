-- ============================================================
-- PostgreSQL SRG — Account Expiration Test Script
-- Tests VALID UNTIL enforcement, expired account denial,
-- orphaned account detection, and account lifecycle controls.
--
-- Usage:
--   psql -d postgres -f test_account_expiration.sql
--
-- Must be run as a superuser (postgres).
--
-- References: V-203602, V-203603, V-263602, V-263603
-- ============================================================

-- ============================================================
-- 0. Baseline — show current role expiration state
-- ============================================================
\echo '=== Current role expiration status ==='
SELECT rolname,
       rolcanlogin AS can_login,
       rolvaliduntil,
       CASE
           WHEN rolvaliduntil IS NULL THEN 'NO EXPIRATION'
           WHEN rolvaliduntil = 'infinity' THEN 'INFINITY (non-compliant)'
           WHEN rolvaliduntil < now() THEN 'EXPIRED'
           ELSE 'VALID (expires ' || rolvaliduntil::date || ')'
       END AS status
FROM pg_roles
WHERE rolcanlogin = true
ORDER BY rolname;

-- ============================================================
-- 1. Create test roles for expiration scenarios
-- ============================================================
\echo ''
\echo '=== Creating test roles ==='

-- Role with valid expiration (90 days out)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stig_test_valid') THEN
        EXECUTE format(
            'CREATE ROLE stig_test_valid LOGIN PASSWORD %L VALID UNTIL %L',
            'Test1234!', (now() + interval '90 days')::text
        );
        RAISE NOTICE 'Created: stig_test_valid (expires in 90 days)';
    END IF;
END $$;

-- Role with already-expired date
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stig_test_expired') THEN
        EXECUTE format(
            'CREATE ROLE stig_test_expired LOGIN PASSWORD %L VALID UNTIL %L',
            'Test1234!', (now() - interval '1 day')::text
        );
        RAISE NOTICE 'Created: stig_test_expired (expired yesterday)';
    END IF;
END $$;

-- Role with NO expiration (non-compliant)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stig_test_noexpiry') THEN
        CREATE ROLE stig_test_noexpiry LOGIN PASSWORD 'Test1234!';
        RAISE NOTICE 'Created: stig_test_noexpiry (no VALID UNTIL — non-compliant)';
    END IF;
END $$;

-- Role with infinity expiration (non-compliant)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stig_test_infinity') THEN
        CREATE ROLE stig_test_infinity LOGIN PASSWORD 'Test1234!'
            VALID UNTIL 'infinity';
        RAISE NOTICE 'Created: stig_test_infinity (VALID UNTIL infinity — non-compliant)';
    END IF;
END $$;

-- Orphaned role (not in any approved user list)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stig_test_orphan') THEN
        EXECUTE format(
            'CREATE ROLE stig_test_orphan LOGIN PASSWORD %L VALID UNTIL %L',
            'Test1234!', (now() + interval '30 days')::text
        );
        RAISE NOTICE 'Created: stig_test_orphan (simulates orphaned account)';
    END IF;
END $$;

-- ============================================================
-- 2. Display test roles and their expiration status
-- ============================================================
\echo ''
\echo '=== Test role expiration status ==='
SELECT rolname,
       rolcanlogin AS can_login,
       rolvaliduntil,
       CASE
           WHEN rolvaliduntil IS NULL THEN 'NO EXPIRATION (V-263602 non-compliant)'
           WHEN rolvaliduntil = 'infinity' THEN 'INFINITY (V-263602 non-compliant)'
           WHEN rolvaliduntil < now() THEN 'EXPIRED — login should be denied'
           ELSE 'VALID (expires ' || rolvaliduntil::date || ')'
       END AS compliance_status
FROM pg_roles
WHERE rolname LIKE 'stig_test_%'
ORDER BY rolname;

-- ============================================================
-- 3. Identify non-compliant accounts (V-263602)
--    Roles without expiration or with infinity
-- ============================================================
\echo ''
\echo '=== V-263602: Roles WITHOUT valid expiration (non-compliant) ==='
SELECT rolname, rolvaliduntil
FROM pg_roles
WHERE rolcanlogin = true
  AND (rolvaliduntil IS NULL OR rolvaliduntil = 'infinity')
ORDER BY rolname;

-- ============================================================
-- 4. Identify expired accounts (V-263602)
--    These should be denied login automatically by PostgreSQL
-- ============================================================
\echo ''
\echo '=== V-263602: Expired accounts (login auto-denied) ==='
SELECT rolname,
       rolvaliduntil,
       now() - rolvaliduntil AS expired_since
FROM pg_roles
WHERE rolcanlogin = true
  AND rolvaliduntil IS NOT NULL
  AND rolvaliduntil != 'infinity'
  AND rolvaliduntil < now()
ORDER BY rolvaliduntil;

-- ============================================================
-- 5. Simulate enforcement — set VALID UNTIL on non-compliant
--    (V-263602 remediation)
-- ============================================================
\echo ''
\echo '=== V-263602: Enforcing 90-day expiration on non-compliant test roles ==='

DO $$
DECLARE
    r RECORD;
    new_expiry TIMESTAMP;
BEGIN
    new_expiry := now() + interval '90 days';
    FOR r IN
        SELECT rolname FROM pg_roles
        WHERE rolname LIKE 'stig_test_%'
          AND rolcanlogin = true
          AND (rolvaliduntil IS NULL OR rolvaliduntil = 'infinity')
    LOOP
        EXECUTE format('ALTER ROLE %I VALID UNTIL %L', r.rolname, new_expiry);
        RAISE NOTICE 'Enforced expiration on %: VALID UNTIL %',
            r.rolname, new_expiry;
    END LOOP;
END $$;

-- ============================================================
-- 6. Simulate disable expired — set NOLOGIN (V-263602 defense-in-depth)
-- ============================================================
\echo ''
\echo '=== V-263602: Disabling expired test accounts (NOLOGIN) ==='

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT rolname FROM pg_roles
        WHERE rolname LIKE 'stig_test_%'
          AND rolcanlogin = true
          AND rolvaliduntil IS NOT NULL
          AND rolvaliduntil != 'infinity'
          AND rolvaliduntil < now()
    LOOP
        EXECUTE format('ALTER ROLE %I NOLOGIN', r.rolname);
        RAISE NOTICE 'Disabled expired account: %', r.rolname;
    END LOOP;
END $$;

-- ============================================================
-- 7. Orphaned account detection (V-203603 / V-263603)
--    Compare login roles against an approved list
-- ============================================================
\echo ''
\echo '=== V-263603: Orphaned account detection ==='
\echo '  (roles with LOGIN not in approved list)'

-- Simulated approved user list — adjust to match your environment
WITH approved_users(username) AS (
    VALUES ('postgres'), ('sonar'), ('bitbucketuser'),
           ('stig_test_valid')
)
SELECT r.rolname AS orphaned_account,
       r.rolvaliduntil,
       r.rolcanlogin
FROM pg_roles r
LEFT JOIN approved_users a ON r.rolname = a.username
WHERE r.rolcanlogin = true
  AND a.username IS NULL
  AND r.rolname NOT LIKE 'pg_%'
ORDER BY r.rolname;

-- ============================================================
-- 8. Post-enforcement verification
-- ============================================================
\echo ''
\echo '=== Post-enforcement: all test role states ==='
SELECT rolname,
       rolcanlogin AS can_login,
       rolvaliduntil,
       CASE
           WHEN NOT rolcanlogin THEN 'DISABLED (NOLOGIN)'
           WHEN rolvaliduntil IS NULL THEN 'NO EXPIRATION'
           WHEN rolvaliduntil = 'infinity' THEN 'INFINITY'
           WHEN rolvaliduntil < now() THEN 'EXPIRED'
           ELSE 'VALID (expires ' || rolvaliduntil::date || ')'
       END AS final_status
FROM pg_roles
WHERE rolname LIKE 'stig_test_%'
ORDER BY rolname;

-- ============================================================
-- 9. Full environment audit — all login-capable roles
-- ============================================================
\echo ''
\echo '=== Full audit: all login-capable roles ==='
SELECT rolname,
       rolsuper AS superuser,
       rolcanlogin AS can_login,
       rolvaliduntil,
       CASE
           WHEN rolvaliduntil IS NULL THEN 'REVIEW — no expiration set'
           WHEN rolvaliduntil = 'infinity' THEN 'REVIEW — infinite expiration'
           WHEN rolvaliduntil < now() THEN 'ACTION — expired, should be NOLOGIN'
           WHEN rolvaliduntil < now() + interval '30 days' THEN 'WARNING — expires within 30 days'
           ELSE 'OK'
       END AS recommendation
FROM pg_roles
WHERE rolcanlogin = true
ORDER BY rolvaliduntil NULLS FIRST;

-- ============================================================
-- 10. Cleanup test roles
-- ============================================================
\echo ''
\echo '=== Cleanup ==='

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT rolname FROM pg_roles WHERE rolname LIKE 'stig_test_%'
    LOOP
        EXECUTE format('DROP ROLE IF EXISTS %I', r.rolname);
        RAISE NOTICE 'Dropped: %', r.rolname;
    END LOOP;
END $$;

\echo ''
\echo '=== Account expiration test complete ==='
\echo 'Controls tested: V-203602, V-203603, V-263602, V-263603'
