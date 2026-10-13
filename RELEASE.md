# Pre-Deployment Checklist

Before deploying this project to a production environment, ensure the following technical debt and security configurations are resolved:

### Security & Identity
- [ ] **Microservice Authorization (IDOR)**: The Schedule API currently relies entirely on the API Gateway for authentication but lacks its own fine-grained authorization. Add JWT Bearer authentication to the microservice and verify User.Identity against the requested resource IDs (e.g., studentId) to prevent Insecure Direct Object Reference (IDOR) vulnerabilities.
- [ ] **Database Credentials**: Change the default `rootpassword` for both **PostgreSQL** and **MongoDB** in `docker-compose.yml` to use secure, injected environment variables.
- [ ] **JWT Secrets**: The JWT Secret Key (`JwtConfig__Key`) is currently hardcoded. Move this to a secure environment variable or a Secret Manager (like Azure Key Vault).

### Docker & Containers
- [x] **Environment Variables**: Ensure `ASPNETCORE_ENVIRONMENT` is removed or explicitly set to `Production` in the production deployment configs. Configured via `docker-compose.prod.yml` while keeping `Development` in local `docker-compose.yml` for Swagger testing.
- [ ] **Prebuilt Images**: Do not build images on the fly in production (`build: .` in compose). Images should be pre-built via CI/CD and pulled from a registry like [Docker Hub](https://hub.docker.com/).
- [x] **Multi-stage Builds**: Ensure all API `Dockerfile`s use multi-stage layered builds to keep production image sizes small and secure.
- [x] **Non-Root Execution**: Do not run containers as root. Add `USER app` (or equivalent non-root user) to all Dockerfiles to prevent privilege escalation attacks.

### Networking & Ports
- [ ] **Port Redirection**: The APIs (Campus, Schedule, etc.) expose Port 80 internally by default (via `ENTRYPOINT ["dotnet", "API.dll"]`). Ensure these are correctly mapped and redirected in `docker-compose.yml`.
- [x] **Port Assignments**: For local debugging, strictly adhere to the `50xx` standard (e.g., 5001, 5002) in `docker-compose.yml`. For production, internal microservice ports are isolated behind the API Gateway without exposing them directly (configured in `docker-compose.prod.yml`).
- [x] **Database Exposure**: Audit exposed ports in `docker-compose.yml` to ensure internal databases (Postgres/Mongo) are not exposed publicly to the internet.
- [ ] **Network Architecture**: Review Docker networking topologies ([Overlay](https://docs.docker.com/engine/network/drivers/overlay/), [Host](https://docs.docker.com/engine/network/drivers/host/), [Bridge](https://docs.docker.com/engine/network/drivers/bridge/)) to choose the correct driver for your production scaling strategy.

### Databases & Migrations
- [ ] **EF Core Auto-Migrations**: Remove wait context.Database.MigrateAsync() from the Program.cs of all microservices (Identity, Campus, Schedule). Implement a secure CI/CD migration step (like an Init Container or EF Core deployment bundles) to prevent concurrency crashes and strictly limit production database privileges.

### API Gateway, Codebase & Architecture
- [ ] **CORS Security**: Update `Program.cs` to remove `AllowAnyOrigin()` and restrict the CORS policy to the exact production frontend domain.
- [ ] **Allowed Hosts**: Update `appsettings.json` to lock down `AllowedHosts` to the production domain (remove `*`).
- [ ] **Code Cleanup**: Thoroughly clean up unused files, unreferenced routes, dead code, and caches before the final production build.
- [ ] **MongoDB Domain Coupling**: The Incident microservice currently relies on MongoDB.Bson attributes ([BsonId]) directly inside the Domain layer. Remove these attributes and configure the mappings in the Infrastructure layer (using BsonClassMap) to restore strict Clean Architecture.



