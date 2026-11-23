# UCT Map - Backend Services

This directory contains the backend infrastructure for the UCT Map platform. The backend is structured using a **Microservices Architecture** and strictly adheres to **Clean Architecture** principles.

## Microservices

The backend is divided into 4 independent microservices and 1 API Gateway:

1. **Campus Service** (`/Services/Campus`)
   - Handles the core geographical and structural data of the university.
   - Manages Campuses, Buildings, Rooms, External Structures, Categories, and Coordinates.
   - Database: PostgreSQL (`uct_campus_db`)

2. **Identity Service** (`/Services/Identity`)
   - Handles User Authentication, Authorization, and JWT generation.
   - Manages Role-based access control (Admin, Teacher, ComplaintsOfficer, ObjectsOfficer, Student).
   - Database: PostgreSQL (`uct_identity_db`)

3. **Schedule Service** (`/Services/Schedule`)
   - Manages academic schedules, teacher office hours (`OfficeHours`), and student-teacher meeting appointments (`Meetings`).
   - Database: PostgreSQL (`uct_schedule_db`)

4. **Incident Service** (`/Services/Incident`)
   - Handles the reporting and tracking of campus incidents (`Reports`) and lost objects (`LostObjects`).
   - Features state transitions and synchronization for tickets.
   - Database: MongoDB (`uct_incident_db`)

5. **API Gateway** (`/ApiGateway`)
   - Acts as the single entry point for the Web and Mobile clients using YARP.
   - Validates JWT tokens and routes incoming HTTP requests to the appropriate microservice.

---

## Architecture Guidelines (Clean Architecture)

Every microservice is self-contained and divided into four distinct layers to ensure decoupling and maintainability:

- **Domain Layer (`.Domain`)**: The pure core. Contains Entities, Enums, Value Objects, and custom Exceptions. No external dependencies.
- **Application Layer (`.Application`)**: Contains Business Logic, Handlers, DTOs, Validators, and Repository Interfaces. Uses the `ErrorOr` library for standardized error handling.
- **Infrastructure Layer (`.Infrastructure`)**: Implements Repository interfaces, Database Contexts (EF Core / MongoDB Driver), Migrations, Seeders, and external integrations.
- **API Layer (`.API`)**: The presentation layer. Contains Controllers, JWT authorization policies, and Dependency Injection configurations.

## Development & Formatting Rules

We strictly enforce the following coding standards:
- **PascalCase** for all classes, methods, and public properties.
- **Single-Line Methods/Ifs**: Where applicable, single-line logic must be grouped onto one line (e.g., `if (condition) return Error;`).
- **Error Handling**: All Application Handlers must return `ErrorOr<T>`. Controllers must unpack the `ErrorOr` response and return the appropriate HTTP Status Code.

---

## Local Execution Guide

### Option 1: Run Everything via Docker Compose (Recommended)
From the repository root, ensure your `.env` file is created (`cp .env.example .env`) and start PostgreSQL, MongoDB, all 4 microservices, and the API Gateway:
```bash
docker compose up -d --build postgres mongodb identity-api campus-api incident-api schedule-api api-gateway
```
- **API Gateway**: `http://localhost:5000`
- **Identity API**: `http://localhost:5001`
- **Campus API**: `http://localhost:5002`
- **Incident API**: `http://localhost:5003`
- **Schedule API**: `http://localhost:5004`

To stop the containers:
```bash
docker compose down
```

### Option 2: Run an Individual Microservice Locally with .NET CLI
1. Start only the database containers from the root directory:
   ```bash
   docker compose up -d postgres mongodb
   ```
2. Navigate to the desired microservice API folder (e.g., `Campus.API`) and run it using the .NET 10 SDK:
   ```bash
   cd src/backend/Services/Campus/Campus.API
   dotnet run
   ```
3. When `ASPNETCORE_ENVIRONMENT=Development`, Swagger UI is available at `/swagger/index.html` on the service's port.

---

## Testing & CI/CD

Each microservice contains two test projects:
- `{Service}.UnitTests`
- `{Service}.IntegrationTests`

**Running Tests Locally:**
Tests are wired into each service's `.slnx` file. To test a service (e.g., Campus), navigate to `src/backend/Services/Campus` and run:
```bash
dotnet test Campus.slnx
```
Or run all backend tests and E2E Gateway tests from the root directory via `Makefile`:
```bash
make test
make test-e2e
```

**Continuous Integration (CI):**
Our GitHub Actions pipeline (`.github/workflows/backend-ci.yml`) automatically runs on pushes and PRs. It enforces:
1. `dotnet format --verify-no-changes` compliance.
2. Successful Release builds across all microservices.
3. 100% passing Unit & Integration tests.
4. **Code Coverage > 75%** (utilizing `coverlet.collector` and `CodeCoverageSummary`).
5. **E2E API Gateway tests** via Postman/Newman (`make test-e2e`).
