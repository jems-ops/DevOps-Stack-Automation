#!/bin/bash
# Test Script for Tenable Security Center SAML API
# Tests authentication and SAML configuration retrieval

set -e

# Configuration
SC_URL="${SC_URL:-https://tenable.local}"
SC_USERNAME="${SC_USERNAME:-admin}"
SC_PASSWORD="${SC_PASSWORD:-}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if password is provided
if [ -z "$SC_PASSWORD" ]; then
    print_error "SC_PASSWORD environment variable is required"
    echo "Usage: SC_PASSWORD='your_password' $0"
    echo "Optional: SC_URL='https://tenable.local' SC_USERNAME='admin' SC_PASSWORD='password' $0"
    exit 1
fi

print_info "Testing Security Center SAML API"
print_info "URL: $SC_URL"
print_info "Username: $SC_USERNAME"
echo

# Step 1: Authenticate and get session token
print_info "Step 1: Authenticating to Security Center..."
AUTH_RESPONSE=$(curl -k -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$SC_USERNAME\",\"password\":\"$SC_PASSWORD\"}" \
    "$SC_URL/rest/token")

# Check if authentication was successful
if echo "$AUTH_RESPONSE" | grep -q '"error_code"'; then
    print_error "Authentication failed"
    echo "$AUTH_RESPONSE" | jq .
    exit 1
fi

# Extract token
TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.response.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    print_error "Failed to extract session token"
    echo "$AUTH_RESPONSE" | jq .
    exit 1
fi

print_success "Authentication successful"
print_info "Session token: ${TOKEN:0:20}..."
echo

# Step 2: Get current SAML configuration
print_info "Step 2: Retrieving SAML configuration..."
SAML_CONFIG=$(curl -k -s -X GET \
    -H "X-SecurityCenter: $TOKEN" \
    "$SC_URL/rest/configSection/8/1")

# Check if request was successful
if echo "$SAML_CONFIG" | grep -q '"error_code"'; then
    print_error "Failed to retrieve SAML configuration"
    echo "$SAML_CONFIG" | jq .
else
    print_success "SAML configuration retrieved successfully"
    echo
    print_info "SAML Configuration:"
    echo "$SAML_CONFIG" | jq '.response | {
        name: .name,
        description: .description,
        samlEnabled: .samlEnabled,
        entityID: .entityID,
        idp: .idp,
        usernameAttribute: .usernameAttribute,
        singleSignOnService: .singleSignOnService,
        singleLogoutService: .singleLogoutService,
        hasCertificate: (.certData != null and .certData != "")
    }'
fi
echo

# Step 3: Logout
print_info "Step 3: Logging out..."
curl -k -s -X DELETE \
    -H "X-SecurityCenter: $TOKEN" \
    "$SC_URL/rest/token" > /dev/null

print_success "Session closed"
echo

# Summary
print_info "=== Test Summary ==="
if echo "$SAML_CONFIG" | jq -e '.response.samlEnabled == "true"' > /dev/null 2>&1; then
    print_success "SAML is ENABLED"
else
    print_error "SAML is DISABLED"
fi

# Display key SAML settings
if echo "$SAML_CONFIG" | jq -e '.response' > /dev/null 2>&1; then
    ENTITY_ID=$(echo "$SAML_CONFIG" | jq -r '.response.entityID // "Not configured"')
    IDP=$(echo "$SAML_CONFIG" | jq -r '.response.idp // "Not configured"')
    USERNAME_ATTR=$(echo "$SAML_CONFIG" | jq -r '.response.usernameAttribute // "Not configured"')
    SSO_URL=$(echo "$SAML_CONFIG" | jq -r '.response.singleSignOnService // "Not configured"')

    echo
    print_info "Entity ID: $ENTITY_ID"
    print_info "Identity Provider: $IDP"
    print_info "Username Attribute: $USERNAME_ATTR"
    print_info "SSO Service: $SSO_URL"
fi

print_success "Test completed successfully"
