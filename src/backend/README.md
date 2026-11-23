# UCT Map - Backend Services

This directory contains the backend infrastructure for the UCT Map platform. The backend is structured using a **Microservices Architecture** and strictly adheres to **Clean Architecture** principles.

## Microservices

The backend is divided into 4 independent microservices and 1 API Gateway:

1. **Campus Service** (`/Services/Campus`)
   - Handles the core geographical and structural data of the university.
   - Manages Buildings, Rooms, and Coordinates.
   - Database: PostgreSQL

2. **Identity Service** (`/Services/Identity`)
   - Handles User Authentication, Authorization, and JWT generation.
   - Manages Role-based access control (Admin, Teacher, Official, Student, etc.).
   - Database: PostgreSQL

3. **Schedule Service** (`/Services/Schedule`)
   - Manages academic schedules, teacher availability, and meeting appointments.
   - Database: PostgreSQL

4. **Incident Service** (`/Services/Incident`)
   - Handles the reporting and tracking of campus incidents and lost objects.
   - Features complex state transitions for tickets.
   - Database: MongoDB

5. **API Gateway** (`/ApiGateway`)
   - Acts as the single entry point for the Frontend.
   - Routes incoming HTTP requests to the appropriate microservice.

## Architecture Guidelines (Clean Architecture)

Every microservice is self-contained and divided into four distinct layers to ensure decoupling and maintainability:

- **Domain Layer (`.Domain`)**: The pure core. Contains Entities, Enums, and custom Exceptions. No external dependencies.
- **Application Layer (`.Application`)**: Contains Business Logic, Handlers, DTOs, and Repository Interfaces. Uses the `ErrorOr` library for standardized error handling.
- **Infrastructure Layer (`.Infrastructure`)**: Implements Repository interfaces, Database Contexts (EF Core / MongoDB Driver), Migrations, and external integrations.
- **API Layer (`.API`)**: The presentation layer. Contains Controllers and Dependency Injection configurations.

## Development & Formatting Rules

We strictly enforce the following coding standards:
- **PascalCase** for all classes, methods, and public properties.
- **Single-Line Methods/Ifs**: Where applicable, single-line logic must be grouped onto one line (e.g., `if (condition) return Error;`).
- **Error Handling**: All Application Handlers must return `ErrorOr<T>`. Controllers must unpack the `ErrorOr` response and return the appropriate HTTP Status Code.

## Testing & CI/CD

Each microservice contains two test projects:
- `{Service}.UnitTests`
- `{Service}.IntegrationTests`

**Running Tests Locally:**
Tests are wired into each service's `.slnx` file. To test a service (e.g., Campus), navigate to the `src/backend/Services/Campus` directory and run:
```bash
dotnet test Campus.slnx
```

**Continuous Integration (CI):**
Our GitHub Actions pipeline automatically runs on every push/PR to `main` and `taller-2`. It enforces:
1. `dotnet format` compliance.
2. Successful builds.
3. 100% passing Unit & Integration tests.
4. **Code Coverage > 75%** (utilizing `coverlet.collector` and `CodeCoverageSummary`).
