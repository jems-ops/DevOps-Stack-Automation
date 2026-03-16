#!/bin/bash
# fix_v206555_permissions.sh
#
# Fixes files incorrectly set to postgres:postgres 0600 by STIG V-206555
# Works for SonarQube, Bitbucket, or any application under /opt.
#
# Usage:
#   sudo bash fix_v206555_permissions.sh <app_dir> <app_user> <service_name>
#
# Examples:
#   sudo bash fix_v206555_permissions.sh /opt/sonarqube-10.3.0.82913  sonar      sonarqube
#   sudo bash fix_v206555_permissions.sh /opt/atlassian/bitbucket      bitbucket  bitbucket
#   sudo bash fix_v206555_permissions.sh /opt/atlassian/confluence      confluence confluence

set -uo pipefail

APP_DIR="${1:-}"
APP_USER="${2:-}"
APP_SERVICE="${3:-}"

# ── validate args ─────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: run as root — sudo bash $0 <dir> <user> <service>"
    exit 1
fi

if [[ -z "$APP_DIR" || -z "$APP_USER" || -z "$APP_SERVICE" ]]; then
    echo "Usage: sudo bash $0 <app_dir> <app_user> <service_name>"
    echo
    echo "  SonarQube : sudo bash $0 /opt/sonarqube-10.3.0.82913  sonar      sonarqube"
    echo "  Bitbucket : sudo bash $0 /opt/atlassian/bitbucket      bitbucket  bitbucket"
    exit 1
fi

if [[ ! -d "$APP_DIR" ]]; then
    echo "ERROR: directory not found: $APP_DIR"
    exit 1
fi

echo "=== V-206555 permission fix ==="
echo "  dir     : $APP_DIR"
echo "  user    : $APP_USER"
echo "  service : $APP_SERVICE"
echo

# ── stop service ──────────────────────────────────────────────────────────────
systemctl stop "$APP_SERVICE" 2>/dev/null || true
echo "[1/4] Stopped $APP_SERVICE"

# ── restore ownership ─────────────────────────────────────────────────────────
COUNT=$(find "$APP_DIR" -user postgres 2>/dev/null | wc -l)
echo "[2/4] Found $COUNT file(s) owned by postgres — restoring to $APP_USER"
find "$APP_DIR" -user postgres 2>/dev/null | head -20 | sed 's/^/       /'
[[ "$COUNT" -gt 20 ]] && echo "       ... ($COUNT total)"
find "$APP_DIR" -user postgres -exec chown "${APP_USER}:${APP_USER}" {} + 2>/dev/null || true

# ── restore permissions ───────────────────────────────────────────────────────
echo "[3/4] Restoring permissions"
find "$APP_DIR" -type d  -exec chmod 750 {} +  2>/dev/null || true   # dirs
find "$APP_DIR" -type f  -exec chmod 640 {} +  2>/dev/null || true   # files
find "$APP_DIR" -name "*.sh"     -exec chmod 755 {} + 2>/dev/null || true  # scripts
find "$APP_DIR" -name "*.py"     -exec chmod 755 {} + 2>/dev/null || true
find "$APP_DIR" -name "*.jar"    -exec chmod 644 {} + 2>/dev/null || true
# Web assets need world-read so nginx/browser can serve them
find "$APP_DIR" -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \
     -o -name "*.svg" -o -name "*.png" -o -name "*.woff2" \
     -o -name "*.ttf" -o -name "*.json" \) \
     -exec chmod 644 {} + 2>/dev/null || true

# ── start and wait ────────────────────────────────────────────────────────────
echo "[4/4] Starting $APP_SERVICE..."
systemctl start "$APP_SERVICE"

echo "Waiting for service to come up (up to 3 min)..."
for i in $(seq 1 18); do
    sleep 10
    if systemctl is-active --quiet "$APP_SERVICE"; then
        echo "  [OK] $APP_SERVICE is running"
        break
    fi
    echo "  ... $((i * 10))s"
done

systemctl is-active --quiet "$APP_SERVICE" \
    && echo "=== Done ===" \
    || { echo "WARN: service did not come up — check: journalctl -u $APP_SERVICE -n 50"; exit 2; }
