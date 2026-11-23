# UCT Map - Interactive Campus Platform

Welcome to the **UCT Map** project repository. This platform serves as a centralized, digital ecosystem designed to solve everyday orientation and management challenges within the Universidad Católica de Temuco (UCT) campus.

## Main Functionalities

The UCT Map project addresses the fragmentation of university information by integrating four core pillars into a single platform:

1. **Intelligent Interactive Map** 🗺️
   - A highly detailed, multi-layered interactive map of the campus with 2D/3D views, indoor floor plans, and step-by-step pedestrian navigation.
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

The system is built as a highly scalable distributed application divided into three main areas inside `src/`:
- **Backend (`src/backend`)**: A robust Microservices architecture built with C# and .NET 10, fronted by a YARP API Gateway.
- **Frontend Web (`src/frontend`)**: A modern, responsive Single Page Application (SPA) built with React 19, Vite, and TailwindCSS v4.
- **Mobile App (`src/mobile`)**: A cross-platform native mobile application for Android and iOS built with Flutter, following Clean Architecture principles.

### Documentation & Execution Guides
For deep technical dives and local execution guides for each stack, please refer to their specific documentations:
- ⚙️ **[Backend Documentation & Execution Guide](./src/backend/README.md)** (Microservices, Clean Architecture, Testing, CI/CD)
- 🎨 **[Frontend Web Documentation & Execution Guide](./src/frontend/README.md)** (React, Vite, Zustand, Nginx Proxy)
- 📱 **[Mobile App Documentation & Execution Guide](./src/mobile/README.md)** (Flutter, Mapbox SDK, JaCoCo Coverage, Integration Tests)

---

## Tech Stack

- **Infrastructure**: Docker & Docker Compose, GitHub Actions (CI/CD Pipelines), Kubero
- **Databases**: PostgreSQL (Relational data) & MongoDB (NoSQL for incident logs & tickets)
- **Backend**: C# 10, .NET 10, YARP API Gateway, Entity Framework Core, xUnit, Coverlet
- **Frontend Web**: React 19, TypeScript, Zustand, TanStack Query, Mapbox GL JS, TailwindCSS v4, Vitest
- **Mobile**: Flutter (Dart 3.x), Mapbox Maps SDK for Flutter, OAuth2 / JWT, JaCoCo Coverage

## Running the Ecosystem Locally

The easiest way to spin up the core infrastructure (Databases, API Gateway, Microservices, and Web Frontend) is via Docker Compose:

1. Ensure Docker & Docker Compose are running, and copy `.env.example` to `.env` with your local credentials:
   ```bash
   cp .env.example .env
   ```
2. From the root directory, run:
   ```bash
   docker compose up --build
   ```
3. The Web Frontend will be available at `http://localhost:3000`.
4. The API Gateway will route traffic seamlessly from `http://localhost:5000`.
5. To run the Flutter mobile application on Android, iOS, or Chrome against the local API Gateway, follow the **[Mobile Execution Guide](./src/mobile/README.md)**.
