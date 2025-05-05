#!/bin/bash

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to be ready..."
max_attempts=30
attempt=1
while ! curl -s http://localhost:8080/health/ready > /dev/null; do
    if [ $attempt -eq $max_attempts ]; then
        echo "Keycloak failed to start after $max_attempts attempts"
        exit 1
    fi
    echo "Attempt $attempt of $max_attempts: Waiting for Keycloak..."
    sleep 5
    attempt=$((attempt + 1))
done

echo "Keycloak is ready!"

# Get admin token
echo "Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" = "null" ]; then
    echo "Failed to get admin token"
    exit 1
fi

echo "Admin token obtained successfully"

# Create realm
echo "Creating demo-realm..."
REALM_RESPONSE=$(curl -s -X POST http://localhost:8080/admin/realms \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "demo-realm",
    "enabled": true,
    "registrationAllowed": false,
    "resetPasswordAllowed": true,
    "editUsernameAllowed": false,
    "bruteForceProtected": true
  }')

if [ ! -z "$REALM_RESPONSE" ]; then
    echo "Error creating realm: $REALM_RESPONSE"
    exit 1
fi

echo "Realm created successfully"

# Create client
echo "Creating spring-boot-client..."
CLIENT_RESPONSE=$(curl -s -X POST http://localhost:8080/admin/realms/demo-realm/clients \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "spring-boot-client",
    "enabled": true,
    "protocol": "openid-connect",
    "redirectUris": ["http://localhost:8081/*"],
    "clientAuthenticatorType": "client-secret",
    "secret": "8c7d6e5f-4a3b-2c1d-0e9f-8a7b6c5d4e3f",
    "bearerOnly": false,
    "publicClient": false,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "authorizationServicesEnabled": true
  }')

if [ ! -z "$CLIENT_RESPONSE" ]; then
    echo "Error creating client: $CLIENT_RESPONSE"
    exit 1
fi

echo "Client created successfully"

# Create role
echo "Creating user role..."
ROLE_RESPONSE=$(curl -s -X POST http://localhost:8080/admin/realms/demo-realm/roles \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "user",
    "description": "User role"
  }')

if [ ! -z "$ROLE_RESPONSE" ]; then
    echo "Error creating role: $ROLE_RESPONSE"
    exit 1
fi

echo "Role created successfully"

# Get role details
echo "Getting role details..."
ROLE_DETAILS=$(curl -s -X GET http://localhost:8080/admin/realms/demo-realm/roles/user \
  -H "Authorization: Bearer $ADMIN_TOKEN")

if [ -z "$ROLE_DETAILS" ] || [ "$ROLE_DETAILS" = "null" ]; then
    echo "Failed to get role details"
    exit 1
fi

# Create test user
echo "Creating test user..."
USER_RESPONSE=$(curl -s -X POST http://localhost:8080/admin/realms/demo-realm/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "enabled": true,
    "emailVerified": true,
    "firstName": "Test",
    "lastName": "User",
    "email": "testuser@example.com",
    "credentials": [{
        "type": "password",
        "value": "testpass",
        "temporary": false
    }],
    "requiredActions": [],
    "attributes": {}
  }')

if [ ! -z "$USER_RESPONSE" ]; then
    echo "Error creating user: $USER_RESPONSE"
    exit 1
fi

# Get user id
USER_ID=$(curl -s -X GET http://localhost:8080/admin/realms/demo-realm/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[] | select(.username=="testuser") | .id')

if [ -z "$USER_ID" ] || [ "$USER_ID" = "null" ]; then
    echo "Failed to get user ID"
    exit 1
fi

# Assign role to user
echo "Assigning role to user..."
ROLE_MAPPING_RESPONSE=$(curl -s -X POST http://localhost:8080/admin/realms/demo-realm/users/$USER_ID/role-mappings/realm \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "[$ROLE_DETAILS]")

if [ ! -z "$ROLE_MAPPING_RESPONSE" ]; then
    echo "Error assigning role: $ROLE_MAPPING_RESPONSE"
    exit 1
fi

echo "Role assigned successfully"
echo "Keycloak initialization completed!" 