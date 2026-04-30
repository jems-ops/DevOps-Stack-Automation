#!/bin/bash
#
# Get a Keycloak admin access token (master realm, admin-cli client).
#
# Usage:
#   ./scripts/get-keycloak-token.sh [-q] [-h]
#
# Options:
#   -q  quiet — print only the token to stdout (suitable for $(...) capture)
#   -h  show this help
#
# Environment variables (with defaults):
#   KEYCLOAK_URL        Base URL Keycloak listens on. When run on the Keycloak
#                       host itself the local backend is the right target;
#                       defaults to http://localhost:8080.
#                       Override to e.g. https://keycloak.local from elsewhere.
#   REALM               Realm to authenticate against (always 'master' for
#                       admin tokens; default: master).
#   KEYCLOAK_ADMIN_USER Admin username (default: admin).
#   KEYCLOAK_ADMIN_PW   Admin password. If unset, the script prompts.
#   CLIENT_ID           OIDC client (default: admin-cli).
#   CURL_OPTS           Extra options to pass through to curl (e.g. -k for
#                       self-signed TLS when KEYCLOAK_URL is HTTPS).
#
# Examples:
#   # Print token verbosely (with header/info)
#   KEYCLOAK_ADMIN_PW='s3cr3t' ./scripts/get-keycloak-token.sh
#
#   # Capture token in another script (recommended pattern)
#   TOKEN=$(KEYCLOAK_ADMIN_PW='s3cr3t' ./scripts/get-keycloak-token.sh -q)
#
#   # Run from a remote machine through the public HTTPS URL
#   KEYCLOAK_URL=https://keycloak.local CURL_OPTS='-k' \
#     KEYCLOAK_ADMIN_PW='s3cr3t' ./scripts/get-keycloak-token.sh -q

set -euo pipefail

QUIET=0
while getopts "qh" opt; do
  case "$opt" in
    q) QUIET=1 ;;
    h) sed -n '2,/^set -/p' "$0" | sed -E 's/^# ?//' | sed '$d'; exit 0 ;;
    *) echo "Unknown option: -$opt" >&2; exit 2 ;;
  esac
done

KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
REALM="${REALM:-master}"
KEYCLOAK_ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}"
CLIENT_ID="${CLIENT_ID:-admin-cli}"
CURL_OPTS="${CURL_OPTS:-}"

if [[ -z "${KEYCLOAK_ADMIN_PW:-}" ]]; then
  read -rsp "Keycloak admin password for ${KEYCLOAK_ADMIN_USER}: " KEYCLOAK_ADMIN_PW
  echo
fi

[[ "$QUIET" -eq 0 ]] && {
  echo "Requesting access token..."
  echo "  URL : ${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token"
  echo "  user: ${KEYCLOAK_ADMIN_USER}"
  echo
}

# shellcheck disable=SC2086
RESP=$(curl -sf $CURL_OPTS \
  --data-urlencode "client_id=${CLIENT_ID}" \
  --data-urlencode "username=${KEYCLOAK_ADMIN_USER}" \
  --data-urlencode "password=${KEYCLOAK_ADMIN_PW}" \
  --data-urlencode "grant_type=password" \
  "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token")

TOKEN=$(printf '%s' "$RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')

if [[ -z "$TOKEN" ]]; then
  echo "❌ Failed to obtain access token. Response:" >&2
  echo "$RESP" >&2
  exit 1
fi

if [[ "$QUIET" -eq 1 ]]; then
  printf '%s\n' "$TOKEN"
else
  echo "✅ Token acquired (${#TOKEN} chars)."
  echo
  echo "Export it for the next call:"
  echo "  export KEYCLOAK_TOKEN='$TOKEN'"
fi
