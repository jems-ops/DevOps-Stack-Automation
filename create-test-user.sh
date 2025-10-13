#!/bin/bash

KEYCLOAK_SERVER="192.168.201.12:8080"
REALM="sonar"

# Get admin token
TOKEN=$(curl -s -X POST "http://${KEYCLOAK_SERVER}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin123" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

echo "✅ Got admin token: ${TOKEN:0:20}..."

# Create test user
echo "🔧 Creating test user 'testuser' in realm '$REALM'..."
curl -s -X POST "http://${KEYCLOAK_SERVER}/admin/realms/${REALM}/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "firstName": "Test",
    "lastName": "User",
    "email": "testuser@example.com",
    "enabled": true,
    "emailVerified": true,
    "credentials": [
      {
        "type": "password",
        "value": "testpass123",
        "temporary": false
      }
    ]
  }'

echo "✅ Test user created successfully!"

# List users to verify
echo "👥 Users in realm '$REALM':"
curl -s -H "Authorization: Bearer $TOKEN" "http://${KEYCLOAK_SERVER}/admin/realms/${REALM}/users?max=10" | python3 -c "
import sys, json
users = json.load(sys.stdin)
for u in users:
    print(f'- {u[\"username\"]} ({u.get(\"email\", \"no email\")})')
print(f'Total users: {len(users)}')
"

echo "🧪 Now try logging into SonarQube with:"
echo "   Username: testuser"
echo "   Password: testpass123"
