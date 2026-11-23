# Pre-Deployment Checklist

Before deploying this project to a production environment, ensure the following technical debt and security configurations are resolved:

### Security & Identity
- [x] **Microservice Authorization (IDOR)**: The Schedule, Incident, Campus, and Identity APIs validate JWT claims (`sub` and `role`), enforcing ownership and role-based access control (`403 Forbidden`).
- [x] **Database Credentials**: Default `rootpassword` credentials removed from `docker-compose.yml`. PostgreSQL and MongoDB require injected secrets (`${POSTGRES_PASSWORD:?...}`, `${MONGO_PASSWORD:?...}`) via `.env` locally, GitHub Actions environment variables in CI, and Kubero secrets in production (see `.env.example`).
- [x] **JWT Secrets**: `JwtConfig__Key` externalized across Identity, Campus, Schedule, and API Gateway via `${UCT_JWT_KEY:?...}` in `docker-compose.yml` and Kubero environment variables in production.

### Docker & Containers
- [x] **Environment Variables**: `ASPNETCORE_ENVIRONMENT` defaults to `Production` in `docker-compose.yml` (and Kubero), with `docker-compose.dev.yml` (`make up-dev`) enabling `Development` for local Swagger debugging, plus `DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false` in all backend Dockerfiles.
- [x] **Prebuilt Images**: Images are built via CI/CD (`.github/workflows/create-packages.yml`) and published to GitHub Container Registry (`ghcr.io`) for Kubero production deployments.
- [x] **Multi-stage Builds**: All API `Dockerfile`s use multi-stage layered builds to keep production image sizes small and secure.
- [x] **Non-Root Execution**: All backend `Dockerfile`s run under `USER $APP_UID` (non-root) to prevent privilege escalation attacks.

### Networking & Ports
- [x] **Port Redirection**: All .NET 10 APIs listen on internal port `8080` (`ASPNETCORE_HTTP_PORTS=8080`) and are mapped cleanly in `docker-compose.yml`.
- [x] **Port Assignments**: `docker-compose.yml` isolates all microservices (`identity-api`, `campus-api`, `incident-api`, `schedule-api`) inside `uct_network` without host port bindings, exposing only the API Gateway (`5000`) and Frontend (`3000`). Local Swagger/debug ports (`127.0.0.1:5001`–`5004`) are opt-in via `docker-compose.dev.yml` (`make up-dev`).
- [x] **Database Exposure**: Internal databases (`postgres` and `mongodb`) do not publish ports to the host in `docker-compose.yml`, remaining isolated inside `uct_network`.
- [ ] **Network Architecture**: Review container networking topologies and Kubernetes NetworkPolicies in Kubero if stricter service-to-service isolation is required.

### Databases & Migrations
- [ ] **EF Core Auto-Migrations**: Remove `await context.Database.MigrateAsync()` from the `Program.cs` of microservices (`Identity`, `Campus`, `Schedule`). Implement a dedicated CI/CD migration step (such as an Init Container or EF Core migration bundle) to prevent multi-replica concurrency races and limit production DB privileges.

### API Gateway, Codebase & Architecture
- [ ] **CORS Security**: Update `Program.cs` in API Gateway to remove `AllowAnyOrigin()` and restrict the CORS policy to the exact production frontend domain.
- [ ] **Allowed Hosts**: Update `appsettings.json` / Kubero environment variables to lock down `AllowedHosts` to the production domain (remove `*`).
- [ ] **Code Cleanup**: Thoroughly clean up unused files, unreferenced routes, dead code, and caches before the final production build.
- [ ] **MongoDB Domain Coupling**: Check remaining persistence coupling in the Incident microservice and ensure strict Clean Architecture boundaries via `BsonClassMap` in Infrastructure.
