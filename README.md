# UCT Map - Interactive Campus Platform

Welcome to the **UCT Map** project repository. This platform serves as a centralized, digital ecosystem designed to solve everyday orientation and management challenges within the Universidad Católica de Temuco (UCT) campus.

## Main Functionalities

The UCT Map project addresses the fragmentation of university information by integrating four core pillars into a single platform:

1. **Intelligent Interactive Map** 🗺️
   - A highly detailed, multi-layered interactive map of the campus.
   - Allows users to locate specific buildings, classrooms, laboratories, libraries, cafeterias, parking lots, and administrative offices (like DARA or CAEP) effortlessly.
   
2. **Incident Reporting & Heatmaps** 🚨
   - A centralized system for reporting infrastructure issues, complaints, or service outages.
   - Features an aggregated **Heat Map (Mapa de Calor)** that allows university administration to visually identify critical zones with recurring problems.

3. **Lost & Found Management** 🔑
   - Replaces isolated, paper-based tracking at individual building receptions with a unified, digital ticketing system.
   - Enables users to report found items and allows students to search for lost belongings across the entire campus with full traceability.

4. **Academic Scheduling & Directory** 📅
   - A structured digital channel to access teacher contact information and office hours.
   - Includes a synchronized system for students to seamlessly request and schedule meetings with academic staff.


---

## Architecture Overview

The system is built as a highly scalable distributed application divided into two main areas:
- **Backend**: A robust Microservices architecture built with C# and .NET 10.
- **Frontend**: A modern, responsive Single Page Application (SPA) built with React, Vite, and TailwindCSS.

### Documentation Directory
For deep technical dives into how each stack is built, configured, and tested, please refer to their specific documentations:
- ⚙️ **[Backend Documentation](./src/backend/README.md)** (Microservices, Clean Architecture, Testing, CI/CD)
- 🎨 **[Frontend Documentation](./src/frontend/README.md)** (React, Vite, Zustand, Nginx Proxy)

---

## Tech Stack

- **Infrastructure**: Docker & Docker Compose, GitHub Actions (CI Pipelines)
- **Databases**: PostgreSQL (Relational data) & MongoDB (NoSQL for incident logs & tickets)
- **Backend**: C# 10, .NET 10, Entity Framework Core, xUnit, Coverlet
- **Frontend**: React 19, TypeScript, Zustand, TanStack Query, TailwindCSS v4

## Running the Project Locally

The easiest way to spin up the entire ecosystem (Databases, API Gateway, Microservices, and Frontend) is via Docker Compose.

1. Ensure Docker Desktop is running.
2. From the root directory, run:
   ```bash
   docker compose up --build
   ```
3. The frontend will be available at `http://localhost:3000`
4. The API Gateway will route traffic seamlessly from `http://localhost:5000`
