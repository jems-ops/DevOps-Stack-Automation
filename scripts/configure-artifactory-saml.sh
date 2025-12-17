#!/bin/bash
#
# Configure Artifactory SAML SSO via API
# Usage: ./configure-artifactory-saml.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration Variables - EDIT THESE
ARTIFACTORY_URL="${ARTIFACTORY_URL:-https://artifactory.local}"
ARTIFACTORY_ADMIN_USER="${ARTIFACTORY_ADMIN_USER:-admin}"
# Admin password must be set via environment variable
if [ -z "$ARTIFACTORY_ADMIN_PASSWORD" ]; then
    ARTIFACTORY_ADMIN_PASSWORD=""
fi

# Keycloak SAML URLs
KEYCLOAK_SAML_URL="${KEYCLOAK_SAML_URL:-https://keycloak.local/realms/master/protocol/saml}"

# SAML Certificate (X.509) - Must be set via environment variable
if [ -z "$SAML_CERTIFICATE" ]; then
    SAML_CERTIFICATE=""
fi

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if password is provided
if [ -z "$ARTIFACTORY_ADMIN_PASSWORD" ]; then
    print_error "ARTIFACTORY_ADMIN_PASSWORD is not set"
    echo "Usage: ARTIFACTORY_ADMIN_PASSWORD=your_password $0"
    echo "   or: export ARTIFACTORY_ADMIN_PASSWORD=your_password"
    echo "       $0"
    exit 1
fi

# Check if certificate is provided
if [ -z "$SAML_CERTIFICATE" ]; then
    print_error "SAML_CERTIFICATE is not set"
    echo ""
    echo "To get the certificate from Keycloak:"
    echo "  curl -k -s ${KEYCLOAK_SAML_URL%/protocol/saml}/protocol/saml/descriptor | \\"
    echo "    grep -oP '(?<=<ds:X509Certificate>).*?(?=</ds:X509Certificate>)'"
    echo ""
    echo "Then set it: export SAML_CERTIFICATE='your_certificate_here'"
    exit 1
fi

print_info "Configuration:"
print_info "  Artifactory URL: $ARTIFACTORY_URL"
print_info "  Admin User: $ARTIFACTORY_ADMIN_USER"
print_info "  Keycloak SAML URL: $KEYCLOAK_SAML_URL"
print_info "  Certificate length: ${#SAML_CERTIFICATE} characters"
echo ""

# Create JSON payload
print_info "Creating SAML configuration payload..."

JSON_PAYLOAD=$(cat <<EOF
{
  "name": "default",
  "enable_integration": true,
  "login_url": "${KEYCLOAK_SAML_URL}",
  "logout_url": "${KEYCLOAK_SAML_URL}",
  "service_provider_name": "https://keycloak.local/realms/master",
  "certificate": "${SAML_CERTIFICATE}",
  "auto_user_creation": true,
  "allow_user_to_access_profile": true,
  "use_encrypted_assertion": false,
  "auto_redirect": false,
  "sync_groups": true,
  "group_attribute": "groups",
  "email_attribute": "email",
  "name_id_attribute": "username"
}
EOF
)

# Save payload to temp file for debugging
TEMP_FILE=$(mktemp)
echo "$JSON_PAYLOAD" > "$TEMP_FILE"
print_info "Payload saved to: $TEMP_FILE"

# Send PUT request to configure SAML
print_info "Sending SAML configuration to Artifactory..."
echo ""

RESPONSE=$(curl -k -w "\n%{http_code}" -X PUT \
  -u "${ARTIFACTORY_ADMIN_USER}:${ARTIFACTORY_ADMIN_PASSWORD}" \
  -H "Content-Type: application/json" \
  -d "@${TEMP_FILE}" \
  "${ARTIFACTORY_URL}/artifactory/api/saml/config" 2>&1)

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

echo ""
print_info "HTTP Status Code: $HTTP_CODE"

# Check response
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    print_info "✅ SAML SSO configuration successful!"
    echo ""
    print_info "Response:"
    echo "$RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"
    echo ""
    print_info "Next steps:"
    echo "  1. Go to ${ARTIFACTORY_URL}/ui/login"
    echo "  2. Click 'Login via SSO'"
    echo "  3. Login with Keycloak credentials"
else
    print_error "❌ SAML SSO configuration failed!"
    echo ""
    print_error "Response:"
    echo "$RESPONSE_BODY"
    echo ""

    if [ "$HTTP_CODE" = "405" ] || [ "$HTTP_CODE" = "403" ]; then
        print_warning "This might be Artifactory OSS (Community Edition)"
        print_warning "SAML SSO requires Artifactory Pro or Enterprise license"
    fi

    exit 1
fi

# Clean up
rm -f "$TEMP_FILE"

# Verify configuration
print_info "Verifying SAML configuration..."
VERIFY_RESPONSE=$(curl -k -s -u "${ARTIFACTORY_ADMIN_USER}:${ARTIFACTORY_ADMIN_PASSWORD}" \
  "${ARTIFACTORY_URL}/artifactory/api/saml/config")

echo ""
print_info "Current SAML Configuration:"
echo "$VERIFY_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$VERIFY_RESPONSE"

print_info "✅ Configuration complete!"
