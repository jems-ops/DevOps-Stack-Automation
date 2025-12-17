#!/bin/bash
#
# Extract SAML X.509 Certificate from Keycloak
# Usage: ./get-keycloak-saml-cert.sh
#

KEYCLOAK_URL="${KEYCLOAK_URL:-https://keycloak.local}"
REALM="${REALM:-master}"

echo "Fetching SAML certificate from Keycloak..."
echo "URL: ${KEYCLOAK_URL}/realms/${REALM}/protocol/saml/descriptor"
echo ""

# Fetch and extract certificate
CERT=$(curl -k -s "${KEYCLOAK_URL}/realms/${REALM}/protocol/saml/descriptor" | \
  grep -oP '(?<=<ds:X509Certificate>).*?(?=</ds:X509Certificate>)')

if [ -z "$CERT" ]; then
    echo "❌ Failed to extract certificate"
    echo "Check if Keycloak is running at: ${KEYCLOAK_URL}"
    exit 1
fi

echo "✅ Certificate extracted successfully!"
echo ""
echo "Certificate (${#CERT} characters):"
echo "$CERT"
echo ""
echo "To use with configure-artifactory-saml.sh:"
echo "  export SAML_CERTIFICATE='$CERT'"
echo ""
echo "Or all in one command:"
echo "  SAML_CERTIFICATE='$CERT' ARTIFACTORY_ADMIN_PASSWORD='your_password' ./configure-artifactory-saml.sh"
