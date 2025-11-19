#!/bin/bash

echo "Configuring Artifactory SAML SSO..."

# Fetch certificate from Keycloak
CERT=$(curl -sk https://keycloak.local/realms/devops/protocol/saml/descriptor | sed -n 's/.*<ds:X509Certificate>\(.*\)<\/ds:X509Certificate>.*/\1/p' | head -1)

if [ -z "$CERT" ]; then
  echo "❌ Failed to fetch certificate from Keycloak"
  exit 1
fi

echo "✅ Certificate fetched successfully"

# Configure SAML
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "https://trialz1kb4m.jfrog.io/artifactory/api/saml/config" \
  -H "Authorization: Bearer ${ARTIFACTORY_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
  \"enableIntegration\": true,
  \"loginUrl\": \"https://keycloak.local/realms/devops/protocol/saml\",
  \"logoutUrl\": \"https://keycloak.local/realms/devops/protocol/saml\",
  \"serviceProviderName\": \"artifactory\",
  \"certificate\": \"$CERT\",
  \"useEncryptedAssertion\": false,
  \"syncGroups\": true,
  \"groupAttribute\": \"groups\",
  \"emailAttribute\": \"email\",
  \"noAutoUserCreation\": false,
  \"allowUserToAccessProfile\": true,
  \"autoRedirect\": true,
  \"verifyAudienceRestriction\": false
}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ SAML configured successfully"
  echo "$BODY" | jq '.'
else
  echo "❌ Failed with HTTP $HTTP_CODE"
  echo "$BODY"
  exit 1
fi

# Verify configuration
echo ""
echo "=== Verification ==="
curl -s "https://trialz1kb4m.jfrog.io/artifactory/api/saml/config" \
  -H "Authorization: Bearer ${ARTIFACTORY_ACCESS_TOKEN}" | jq '{
  enableIntegration,
  serviceProviderName,
  loginUrl,
  autoRedirect,
  syncGroups,
  noAutoUserCreation
}'

echo ""
echo "✅ SAML configuration complete!"
echo "🔐 Login with auto-redirect: https://trialz1kb4m.jfrog.io/ui/login"
