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
- [x] **Identity Migrations & Seeding**: Identity runs migrations and seeding through `IdentityDatabaseInitializer`, protected by a PostgreSQL advisory lock so concurrent replicas cannot race. The process is idempotent, fails fast with clear logs, and supports a dedicated release step (`dotnet Identity.API.dll --migrate`) with a separate owner connection string. See [Identity Migration & Seeding Procedure](#identity-migration--seeding-procedure).
- [x] **Identity Admin Seed Credentials**: The hardcoded initial administrator password was removed from the code. It is injected through `IDENTITY_ADMIN_PASSWORD` (`IdentitySeed__AdminPassword`) and only used when no active administrator exists.
- [ ] **Kubero Identity Release Step**: Configure the Identity release job in Kubero and set `Database__ApplyMigrationsOnStartup=false` on the API (see the procedure below).

### API Gateway, Codebase & Architecture
- [ ] **CORS Security**: Update `Program.cs` in API Gateway to remove `AllowAnyOrigin()` and restrict the CORS policy to the exact production frontend domain.
- [ ] **Allowed Hosts**: Update `appsettings.json` / Kubero environment variables to lock down `AllowedHosts` to the production domain (remove `*`).
- [ ] **Code Cleanup**: Thoroughly clean up unused files, unreferenced routes, dead code, and caches before the final production build.
- [ ] **MongoDB Domain Coupling**: Check remaining persistence coupling in the Incident microservice and ensure strict Clean Architecture boundaries via `BsonClassMap` in Infrastructure.

---

## Identity Migration & Seeding Procedure

### What happens during initialization
`IdentityDatabaseInitializer` runs these steps in order:

1. Creates `uct_identity_db` only if it does not exist. If two instances try at the same time, the duplicate is ignored.
2. Takes a PostgreSQL session advisory lock (`pg_try_advisory_lock`). Other instances wait, polling every 2 seconds, up to `Database__MigrationLockTimeoutSeconds` (default `120`), and then fail with a `TimeoutException`.
3. Applies only the pending EF Core migrations and logs their names.
4. Seeds the default roles. A role created by another instance at the same time is not treated as an error.
5. Seeds the initial administrator **only if no active administrator exists**:
   - If an active admin already exists, nothing is created or changed, so a demoted seed account is never promoted again.
   - An existing account keeps its password. The configured password is used only when the account is created.
   - A suspended account is never reactivated automatically.
   - If `IdentitySeed__AdminEmail` or `IdentitySeed__AdminPassword` is missing, the admin is not created and a warning is logged.
6. Releases the lock.

Any failure is logged as `Critical` and stops the process: the API does not start with a half-initialized database, and `--migrate` exits with code `1`. Error messages include Identity error codes, never passwords.

### Configuration

| Variable | Default | Description |
| :--- | :--- | :--- |
| `Database__ApplyMigrationsOnStartup` | `true` | Runs initialization when the API starts. Set it to `false` in Production once the release step is configured. |
| `Database__MigrationLockTimeoutSeconds` | `120` | Maximum time an instance waits for the migration lock. |
| `ConnectionStrings__IdentityDbMigrations` | _(empty)_ | Optional connection string with DDL privileges, used only by `--migrate`. If empty, `ConnectionStrings__IdentityDb` is used. |
| `IdentitySeed__AdminEmail` / `IDENTITY_ADMIN_EMAIL` | `admin@uct.cl` (compose) | Email of the initial administrator. |
| `IdentitySeed__AdminPassword` / `IDENTITY_ADMIN_PASSWORD` | _required in compose_ | Password of the initial administrator. Inject it as a secret and change it after the first login. |

### Local and CI (`docker compose`)
Startup migrations stay enabled (`Database__ApplyMigrationsOnStartup=true`), so `make up` keeps working. The advisory lock makes it safe even with several replicas. `IDENTITY_ADMIN_PASSWORD` must be defined in `.env` (see `.env.example`). CI defines it in `backend-ci.yml` for the Newman E2E tests.

### Production (Kubero)
1. **Database users** (least privilege):
   - `identity_owner`: owner of `uct_identity_db`, used only by the release step.
   - `identity_app`: `CONNECT`, `USAGE` on schema `public`, and `SELECT, INSERT, UPDATE, DELETE` on tables and `USAGE, SELECT` on sequences (via `ALTER DEFAULT PRIVILEGES FOR ROLE identity_owner`). It cannot change the schema.
2. **Release step**: run the same `uct-identity-api` image as a pre-deploy job or init container, with the command `dotnet Identity.API.dll --migrate` and the variables `ConnectionStrings__IdentityDbMigrations` (owner), `IdentitySeed__AdminEmail` and `IdentitySeed__AdminPassword`. `JwtConfig__*` is not required for this step. The deploy must continue only if the job exits with code `0`.
3. **API**: set `ConnectionStrings__IdentityDb` to `identity_app` and `Database__ApplyMigrationsOnStartup=false`.

Re-running the release step is safe: without pending migrations it only verifies the schema and seed data.
