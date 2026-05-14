#!/bin/bash
#
# Trigger a Keycloak full user sync from the FreeIPA LDAP UserStorageProvider
# and surface the response (success summary or 4xx errorMessage).
#
# Usage:
#   ./scripts/trigger-freeipa-ldap-sync.sh [-c|--changed] [-h]
#
# Options:
#   -c, --changed   trigger triggerChangedUsersSync instead of triggerFullSync
#   -h              show this help
#
# Environment variables (with defaults):
#   KEYCLOAK_URL          Base URL Keycloak listens on. Default
#                         http://localhost:8080 (correct on the Keycloak host).
#                         Override to https://keycloak.local from elsewhere.
#   REALM                 Realm hosting the LDAP federation (default: master).
#   PROVIDER_NAME         Name of the UserStorageProvider component to sync
#                         (default: freeipa-ldap).
#   KEYCLOAK_TOKEN        Pre-obtained admin access token. If unset, this
#                         script will call ./scripts/get-keycloak-token.sh to
#                         fetch one (which may prompt for KEYCLOAK_ADMIN_PW).
#   KEYCLOAK_ADMIN_USER   Admin username for the implicit token fetch
#                         (default: admin).
#   KEYCLOAK_ADMIN_PW     Admin password for the implicit token fetch.
#   CURL_OPTS             Extra options forwarded to curl (e.g. -k for
#                         self-signed HTTPS).
#
# Examples:
#   # Run on the Keycloak host (the typical case)
#   KEYCLOAK_ADMIN_PW='s3cr3t' ./scripts/trigger-freeipa-ldap-sync.sh
#
#   # Reuse an existing token (no prompt)
#   KEYCLOAK_TOKEN="$(KEYCLOAK_ADMIN_PW=s3cr3t scripts/get-keycloak-token.sh -q)"
#   scripts/trigger-freeipa-ldap-sync.sh
#
#   # Changed-users sync only (faster) instead of full sync
#   ./scripts/trigger-freeipa-ldap-sync.sh -c

set -euo pipefail

ACTION="triggerFullSync"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--changed) ACTION="triggerChangedUsersSync"; shift ;;
    -h|--help)    sed -n '2,/^set -/p' "$0" | sed -E 's/^# ?//' | sed '$d'; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
REALM="${REALM:-master}"
PROVIDER_NAME="${PROVIDER_NAME:-freeipa-ldap}"
CURL_OPTS="${CURL_OPTS:-}"

# Acquire token if caller didn't pre-supply one.
if [[ -z "${KEYCLOAK_TOKEN:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  echo "No KEYCLOAK_TOKEN set — fetching one via get-keycloak-token.sh ..."
  KEYCLOAK_TOKEN=$(KEYCLOAK_URL="$KEYCLOAK_URL" \
                   REALM="$REALM" \
                   KEYCLOAK_ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}" \
                   KEYCLOAK_ADMIN_PW="${KEYCLOAK_ADMIN_PW:-}" \
                   CURL_OPTS="$CURL_OPTS" \
                   "${SCRIPT_DIR}/get-keycloak-token.sh" -q)
fi

# Resolve UserStorageProvider id by name.
echo "Looking up UserStorageProvider '${PROVIDER_NAME}' in realm '${REALM}'..."
# shellcheck disable=SC2086
COMPONENTS=$(curl -sf $CURL_OPTS \
  -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" \
  "${KEYCLOAK_URL}/admin/realms/${REALM}/components?type=org.keycloak.storage.UserStorageProvider")

PROVIDER_ID=$(printf '%s' "$COMPONENTS" | python3 -c "
import sys, json
name = '${PROVIDER_NAME}'
for c in json.load(sys.stdin):
    if c.get('name') == name and c.get('providerId') == 'ldap':
        print(c['id']); break
")

if [[ -z "$PROVIDER_ID" ]]; then
  echo "❌ No LDAP UserStorageProvider named '${PROVIDER_NAME}' found in realm '${REALM}'." >&2
  echo "Available components:" >&2
  printf '%s' "$COMPONENTS" | python3 -c "
import sys, json
for c in json.load(sys.stdin):
    print(f\"  - {c.get('name')!r} (providerId={c.get('providerId')})\")" >&2
  exit 1
fi

URL="${KEYCLOAK_URL}/admin/realms/${REALM}/user-storage/${PROVIDER_ID}/sync?action=${ACTION}"
echo "Triggering ${ACTION} on provider ${PROVIDER_ID}..."
echo "  POST ${URL}"
echo

# Capture status + body separately so we can pretty-print and exit non-zero on 4xx/5xx.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
# shellcheck disable=SC2086
HTTP_STATUS=$(curl -s $CURL_OPTS \
  -o "$TMP" \
  -w '%{http_code}' \
  -X POST \
  -H "Authorization: Bearer ${KEYCLOAK_TOKEN}" \
  "$URL")

BODY=$(cat "$TMP")
echo "HTTP ${HTTP_STATUS}"
if [[ -n "$BODY" ]]; then
  echo "Response body:"
  if printf '%s' "$BODY" | python3 -m json.tool >/dev/null 2>&1; then
    printf '%s' "$BODY" | python3 -m json.tool
  else
    printf '%s\n' "$BODY"
  fi
fi

case "$HTTP_STATUS" in
  200|204)
    echo "✅ Sync completed."
    exit 0
    ;;
  400)
    echo
    echo "❌ Keycloak rejected the sync (HTTP 400). Common causes:"
    echo "   - errorMessage 'GroupsMultipleParents' → set keycloak_ldap_preserve_group_inheritance: \"false\""
    echo "                                            and re-run the federation playbook"
    echo "   - LDAP bind credentials drifted        → re-run --tags freeipa_prep to reset svc.ldap"
    echo "   - LDAP query failed (TLS / schema)     → re-import the IPA CA via --tags ldap"
    exit 1
    ;;
  *)
    echo "❌ Unexpected HTTP status ${HTTP_STATUS}." >&2
    exit 1
    ;;
esac
