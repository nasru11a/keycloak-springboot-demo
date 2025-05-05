# Keycloak Spring Boot Demo

This project demonstrates how to secure a Spring Boot REST API using Keycloak for authentication and authorization. The setup uses Docker Compose to run both Keycloak and the Spring Boot application, making it easy to get started and test OAuth2/JWT-based security.

## Features
- Spring Boot REST API with public and private endpoints
- Keycloak integration for authentication and authorization
- Docker Compose setup for easy local development
- Example Keycloak realm, client, and user initialization script

## Prerequisites
- [Docker](https://www.docker.com/get-started) and Docker Compose installed
- [jq](https://stedolan.github.io/jq/) installed (for the initialization script)
- Java 17+ (for building the Spring Boot app)

## Project Structure
```
├── src/                   # Java source code
├── Dockerfile             # Dockerfile for Spring Boot app
├── docker-compose.yml     # Docker Compose for Keycloak and Spring Boot
├── keycloak-init.sh       # Script to auto-configure Keycloak
├── build.gradle.kts       # Gradle build file
├── README.md              # This file
```

## Quick Start

### 1. Clone the repository
```sh
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>
```

### 2. Start Keycloak (in one terminal)
```sh
docker-compose up keycloak
```

### 3. Initialize Keycloak (in another terminal)
Wait until Keycloak is ready, then run:
```sh
./keycloak-init.sh
```
This will create:
- Realm: `demo-realm`
- Client: `spring-boot-client` (with secret)
- User: `testuser` / `testpass` (with `user` role)

### 4. Build and run the Spring Boot app (in another terminal)
```sh
./gradlew build
./gradlew bootRun
```
Or, to run both services together:
```sh
docker-compose up --build
```

## Usage

### Get a Token
Request a token from Keycloak:
```sh
curl -X POST http://localhost:8080/realms/demo-realm/protocol/openid-connect/token \
  -d "client_id=spring-boot-client" \
  -d "client_secret=8c7d6e5f-4a3b-2c1d-0e9f-8a7b6c5d4e3f" \
  -d "grant_type=password" \
  -d "username=testuser" \
  -d "password=testpass"
```
Copy the `access_token` from the response.

### Test Endpoints
- **Public endpoint:**
  ```sh
  curl http://localhost:8081/api/public
  ```
- **Private endpoint:**
  ```sh
  curl -H "Authorization: Bearer <access_token>" http://localhost:8081/api/private
  ```

## Customization
- To add more users, roles, or clients, modify `keycloak-init.sh`.
- To change the Keycloak admin password, update the environment variables in `docker-compose.yml`.
- To use a different port, update `application.yml` and `docker-compose.yml`.

## Stopping the Services
```sh
docker-compose down
```
Or stop individual containers:
```sh
docker ps -q | xargs -r docker stop
```

## Troubleshooting
- If you get `invalid_grant` or `Account is not fully set up`, make sure the user is enabled and has a password.
- If you get `Bearer-only not allowed`, ensure the client is not set as bearer-only in Keycloak.
- If you change the client secret, update it in `application.yml` and `keycloak-init.sh`.

## License
MIT 