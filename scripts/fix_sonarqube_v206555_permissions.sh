#!/bin/bash
# =============================================================================
# fix_sonarqube_v206555_permissions.sh
#
# PURPOSE
#   Fixes "permission denied" crashes on SonarQube caused by STIG control
#   V-206555 scanning /opt for "password=" strings and incorrectly setting
#   owner=postgres  group=postgres  mode=0600 on ALL matching files —
#   including sonar.properties, Elasticsearch index segments, and web assets.
#
# WHAT IT DOES
#   1. Detects SonarQube install dir(s) under /opt
#   2. Finds every file owned by postgres inside those dirs
#   3. Restores ownership to sonar:sonar
#   4. Restores sensible permissions by file category:
#        sonar.properties   → 640  (has credentials, no world-read)
#        data/ files        → 640  (Elasticsearch segments etc.)
#        data/ dirs         → 750
#        web/ assets        → 644  (JS/CSS/HTML/fonts — world-readable)
#        bin/ scripts       → 755
#        everything else    → 750 (dirs) / 640 (files)
#   5. Restarts SonarQube and polls until UP (or times out)
#
# USAGE
#   sudo bash fix_sonarqube_v206555_permissions.sh
#
# OVERRIDES (env vars)
#   SONAR_USER     default: sonar
#   SONAR_GROUP    default: sonar
#   SONAR_SERVICE  default: sonarqube
#   NO_RESTART     set to 1 to skip systemctl stop/start
# =============================================================================

set -uo pipefail

SONAR_USER="${SONAR_USER:-sonar}"
SONAR_GROUP="${SONAR_GROUP:-sonar}"
SONAR_SERVICE="${SONAR_SERVICE:-sonarqube}"
NO_RESTART="${NO_RESTART:-0}"

# ── helpers ──────────────────────────────────────────────────────────────────
log()  { echo "[INFO]  $*"; }
ok()   { echo "[OK]    $*"; }
warn() { echo "[WARN]  $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ── pre-flight ───────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    err "Must be run as root:  sudo bash $0"
    exit 1
fi

echo "======================================================================"
echo " SonarQube Permission Fix — STIG V-206555 remediation"
echo "======================================================================"

# Detect SonarQube directory (handles symlinks and versioned dirs)
mapfile -t SONAR_DIRS < <(
    find /opt -maxdepth 1 \( -type d -o -type l \) -name 'sonarqube*' 2>/dev/null \
    | sort -V
)

if [[ ${#SONAR_DIRS[@]} -eq 0 ]]; then
    err "No sonarqube* directory found under /opt — check SONAR_USER or path"
    exit 1
fi

log "Detected SonarQube dir(s): ${SONAR_DIRS[*]}"
log "sonar user/group : ${SONAR_USER}:${SONAR_GROUP}"
log "systemd service  : ${SONAR_SERVICE}"
echo

# ── stop service ─────────────────────────────────────────────────────────────
RESTART_AFTER=0
if [[ "$NO_RESTART" -ne 1 ]]; then
    if systemctl is-active --quiet "$SONAR_SERVICE" 2>/dev/null; then
        log "Stopping ${SONAR_SERVICE}..."
        systemctl stop "$SONAR_SERVICE"
        RESTART_AFTER=1
    else
        warn "${SONAR_SERVICE} is not running (already crashed — will start after fix)"
        RESTART_AFTER=1
    fi
fi

# ── fix each detected dir ────────────────────────────────────────────────────
for SONAR_DIR in "${SONAR_DIRS[@]}"; do
    # Resolve symlink so we operate on the real path
    REAL_DIR=$(realpath "$SONAR_DIR" 2>/dev/null || echo "$SONAR_DIR")

    echo "----------------------------------------------------------------------"
    log "Processing: $REAL_DIR"

    # ── 1. Fix ownership (the core V-206555 damage) ──────────────────────────
    MISOWNED=$(find "$REAL_DIR" -user postgres 2>/dev/null | wc -l)

    if [[ "$MISOWNED" -gt 0 ]]; then
        warn "$MISOWNED file(s) owned by postgres — restoring to ${SONAR_USER}:${SONAR_GROUP}"
        # List first 10 affected files for auditability
        find "$REAL_DIR" -user postgres 2>/dev/null | head -10 | while read -r f; do
            echo "         → $f"
        done
        [[ "$MISOWNED" -gt 10 ]] && echo "         → ... (${MISOWNED} total)"

        find "$REAL_DIR" -user postgres -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} +
        ok "Ownership restored on $MISOWNED file(s)"
    else
        ok "No files owned by postgres under $REAL_DIR"
    fi

    # ── 2. Config file permissions ───────────────────────────────────────────
    # sonar.properties contains JDBC password → 640 (not world-readable)
    find "$REAL_DIR" -name "sonar.properties" \
        -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} + \
        -exec chmod 640 {} + 2>/dev/null || true
    log "sonar.properties → 640"

    # ── 3. Elasticsearch data files / dirs ───────────────────────────────────
    # sonar needs rw; group/world need nothing — 640/750 is correct
    if [[ -d "${REAL_DIR}/data" ]]; then
        find "${REAL_DIR}/data" -type f \
            -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} + \
            -exec chmod 640 {} + 2>/dev/null || true
        find "${REAL_DIR}/data" -type d \
            -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} + \
            -exec chmod 750 {} + 2>/dev/null || true
        log "data/  files → 640, dirs → 750"
    fi

    # ── 4. Web assets — must be world-readable for nginx/browser ─────────────
    if [[ -d "${REAL_DIR}/web" ]]; then
        find "${REAL_DIR}/web" -type f \
            \( -name "*.js"   -o -name "*.css"  -o -name "*.html" \
            -o -name "*.svg"  -o -name "*.png"  -o -name "*.jpg"  \
            -o -name "*.woff" -o -name "*.woff2" -o -name "*.ttf" \
            -o -name "*.json" \) \
            -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} + \
            -exec chmod 644 {} + 2>/dev/null || true
        find "${REAL_DIR}/web" -type d \
            -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} + \
            -exec chmod 755 {} + 2>/dev/null || true
        log "web/   assets  → 644, dirs → 755"
    fi

    # ── 5. Binaries / shell scripts ──────────────────────────────────────────
    if [[ -d "${REAL_DIR}/bin" ]]; then
        find "${REAL_DIR}/bin" -type f \
            -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} + \
            -exec chmod 755 {} + 2>/dev/null || true
        log "bin/   scripts → 755"
    fi
    if [[ -d "${REAL_DIR}/lib" ]]; then
        find "${REAL_DIR}/lib" -type f -name "*.sh" \
            -exec chmod 755 {} + 2>/dev/null || true
        find "${REAL_DIR}/lib" -type f ! -name "*.sh" \
            -exec chmod 644 {} + 2>/dev/null || true
        log "lib/   files   → 644 (scripts 755)"
    fi

    # ── 6. Log directory ─────────────────────────────────────────────────────
    if [[ -d "${REAL_DIR}/logs" ]]; then
        find "${REAL_DIR}/logs" -type f \
            -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} + \
            -exec chmod 640 {} + 2>/dev/null || true
        find "${REAL_DIR}/logs" -type d \
            -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} + \
            -exec chmod 750 {} + 2>/dev/null || true
        log "logs/  files   → 640"
    fi

    # ── 7. Temp directory ────────────────────────────────────────────────────
    if [[ -d "${REAL_DIR}/temp" ]]; then
        find "${REAL_DIR}/temp" \
            -exec chown "${SONAR_USER}:${SONAR_GROUP}" {} + 2>/dev/null || true
        find "${REAL_DIR}/temp" -type d -exec chmod 750 {} + 2>/dev/null || true
        find "${REAL_DIR}/temp" -type f -exec chmod 640 {} + 2>/dev/null || true
        log "temp/  files   → 640"
    fi

    # ── 8. Top-level directory itself ────────────────────────────────────────
    chown "${SONAR_USER}:${SONAR_GROUP}" "$REAL_DIR" 2>/dev/null || true
    chmod 750 "$REAL_DIR" 2>/dev/null || true

    ok "Done with $REAL_DIR"
done

# ── start service and poll for UP ────────────────────────────────────────────
echo "----------------------------------------------------------------------"
if [[ "$RESTART_AFTER" -eq 1 ]]; then
    log "Starting ${SONAR_SERVICE}..."
    systemctl start "$SONAR_SERVICE"

    log "Polling SonarQube status (max 5 min)..."
    STATUS=""
    for i in $(seq 1 30); do
        STATUS=$(curl -sk http://localhost:9000/api/system/status 2>/dev/null \
                 | grep -o '"status":"[^"]*"' \
                 | head -1 \
                 | cut -d'"' -f4 2>/dev/null || echo "")
        if [[ "$STATUS" == "UP" ]]; then
            echo
            ok "SonarQube is UP  ✓"
            break
        fi
        printf "\r[INFO]  %2d/30 — status: %-12s" "$i" "${STATUS:-starting...}"
        sleep 10
    done

    if [[ "$STATUS" != "UP" ]]; then
        echo
        warn "SonarQube did not reach UP within 5 minutes"
        warn "Check logs with:  journalctl -u ${SONAR_SERVICE} -n 100 --no-pager"
        warn "Or:               tail -100 $(find /opt/sonarqube* -name 'sonar.log' 2>/dev/null | head -1)"
        exit 2
    fi
else
    log "Skipped restart (NO_RESTART=1)"
fi

echo "======================================================================"
ok "All done"
echo "======================================================================"
