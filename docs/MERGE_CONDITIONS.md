# Políticas de Aprobación y Rechazo de Merge (Merge Conditions)

Este documento define de manera estandarizada los criterios y condiciones obligatorias para la **aprobación** o **rechazo** de la integración (merge) de código hacia las ramas protegidas (`taller-4`, `ti4`, `taller-2`, `ti2` y `main`) en el repositorio **UCT-Map**.

---

## 1. Objetivos

1. **Garantizar la estabilidad**: Prevenir la introducción de regresiones, caídas del sistema o builds rotos en móvil, backend y frontend web.
2. **Asegurar la calidad del código**: Cumplir con los estándares de análisis estático, convenciones de nombres y arquitectura limpia (Clean Architecture).
3. **Fomentar la cultura de revisión**: Promover la colaboración y validación mutua a través de revisiones por pares (Peer Review).
4. **Mantener la trazabilidad**: Asociar cada cambio a un ticket de trabajo (Jira / Issue) y respetar las convenciones de commit para ambos equipos (TI4 y UCT/TI2).
5. **Integración unificada**: Disponer de un ecosistema de checks automatizados interoperable entre los desarrollos de ambos equipos.

---

## 2. Condiciones de Apruebo (Approval Conditions / Definition of Done)

Para que un Pull Request sea considerado apto para fusión (Merge) hacia `taller-4`, `taller-2` o `main`, **debe cumplir obligatoriamente con la totalidad** de los siguientes requisitos aplicables:

### 2.1 Verificación de Integración Continua (CI Pipelines de Ambos Equipos)
Todo PR debe tener el estado de **Checks Passing** (en verde) en los flujos de GitHub Actions correspondientes:

#### Gatekeeper Común (`pr-merge-gate.yml`)
- **Título Conventional Commits**: Formato obligatorio `<tipo>(<ticket>): <descripción>` o `<tipo>: <descripción>`.
- **Escaneo de Secretos**: 0 credenciales, archivos `.env`, `.pem`, `.key`, keystores o tokens expuestos.
- **Descripción del PR**: Formulario de plantilla `.github/pull_request_template.md` diligenciado con descripción clara.

#### Equipo Móvil - Flutter (`flutter-ci.yml`)
- **Code Analysis & Linter (`flutter analyze --no-fatal-infos`)**: 0 errores y 0 advertencias de linter conforme a `analysis_options.yaml`.
- **Unit & Widget Tests (`flutter test --coverage`)**: 100% de las pruebas unitarias y de widgets aprobadas. Cero fallos.
- **Reporte de Cobertura JaCoCo**: Generación exitosa de `coverage/jacoco.xml` y monitoreo del umbral objetivo del 90%.
- **Build Web (`flutter build web --release`)**: Compilación exitosa del bundle web.
- **Build Android APK (`flutter build apk --debug`)**: Compilación exitosa del APK debug.
- **Pruebas de Integración Móvil (`xvfb-run -a flutter test integration_test/app_integration_test.dart -d linux`)**: Flujos E2E móviles aprobados.

#### Equipo Backend - .NET 10 Microservicios (`backend-ci.yml`)
- **Formato de Código (`dotnet format --verify-no-changes`)**: Formato verificado sin cambios pendientes en todas las soluciones (`Campus.slnx`, `Identity.slnx`, `Incident.slnx`, `Schedule.slnx`).
- **Build de Microservicios (`dotnet build -c Release`)**: Compilación limpia de todos los microservicios sin errores.
- **Pruebas Unitarias y de Integración (`dotnet test`)**: 100% de las pruebas aprobadas con reporte de cobertura Cobertura (`threshold >= 75%`).
- **Pruebas E2E API Gateway (`e2e-gateway-tests`)**: Ejecución de contenedores en Docker Compose, validación de autenticación y superación de colección Newman (`make test-e2e`).

#### Equipo Frontend Web - React (`frontend-ci.yml`)
- **Análisis de Calidad (`npm run lint`)**: Verificación de código TypeScript/React sin errores bloqueantes.
- **Pruebas Unitarias y Cobertura (`npm run coverage`)**: Ejecución de tests y reporte de cobertura Cobertura.
- **Compilación Web (`npm run build`)**: Verificación de tipos (`tsc`) y bundle Vite generado exitosamente.

> *Nota de interoperabilidad: En ramas donde un componente específico no esté presente o no haya sido modificado, el job correspondiente lo detecta y finaliza exitosamente de forma inmediata sin bloquear el merge.*

---

### 2.2 Revisión de Código por Pares (Peer Review)
- **Aprobación de al menos un revisor**: Se requiere como mínimo **1 aprobación formal** (`Approved`) de un miembro del equipo o Code Owner.
- **Sin solicitudes de cambios pendientes**: No debe haber ningún estado de `CHANGES_REQUESTED` activo.
- **Resolución de conversaciones**: Todas las observaciones, preguntas o hilos de discusión iniciados en la pestaña de revisión deben estar explícitamente resueltos (`Resolved`).

---

### 2.3 Estándar de Commits y Pull Request
- **Conventional Commits**: El título del PR y los commits deben respetar el estándar:
  - Formato: `<tipo>(<ticket>): <descripción>` o `<tipo>: <descripción>`.
  - Ejemplos válidos para ambos equipos:
    - `ci(TI4-100): integrar checks de ambos equipos en pull requests`
    - `feat(UCT-122): implementar panel de administración`
    - `feat(TI4-98): definir condiciones de merge`
    - `fix(tickets): corregir validacion de formulario`
    - `test(navigation): agregar mock de mapbox`
    - `ci: actualizar pipeline de github actions`
- **Plantilla de Pull Request (`pull_request_template.md`)**: El autor debe completar la plantilla en su totalidad, indicando el tipo de cambio, el ticket correspondiente, el contexto y marcando afirmativamente la lista de verificación (checklist).

---

### 2.4 Integridad de la Rama y Conflictos
- **Rama actualizada**: La rama origen debe estar al día con la rama base (`taller-4` o `taller-2`).
- **Sin conflictos de merge**: El PR no debe presentar conflictos de merge (`Mergeable state: clean`).
- **Estrategia de Merge recomendada**: `Squash and merge` o `Rebase and merge` para mantener un historial lineal y limpio en la rama base.

---

## 3. Condiciones de Rechazo (Rejection Criteria / Blockers)

Un Pull Request será **rechazado de forma automática o por parte de los revisores** (marcando `Request Changes` o cerrando el PR) si incurre en cualquiera de las siguientes faltas:

### 3.1 Fallo en Checks Automatizados (Bloqueo Automático)
- **Fallo en Pruebas Automatizadas**: Si una o más pruebas unitarias, de integración o E2E fallan en el entorno de CI (Flutter, .NET o React).
- **Violaciones de Linter o Análisis Estático**: Presencia de advertencias (`warnings`), errores de sintaxis, violaciones de formato o imports no utilizados.
- **Fallo de Compilación**: Incompatibilidades que impidan la generación de artefactos (Web, Android APK, Microservicios .NET o Bundle React).

### 3.2 Seguridad y Archivos Sensibles
- **Inclusión de Secretos o Credenciales**: Queda terminantemente prohibido comitear:
  - Archivos `.env` con valores reales.
  - Llaves privadas (`.pem`, `.key`, `id_rsa`).
  - Tokens de autenticación, API Keys de producción o contraseñas en texto plano.
  *Cualquier PR que viole esta condición será rechazado inmediatamente y el autor deberá limpiar el historial de commits y rotar los secretos comprometidos.*

### 3.3 Calidad de Código y Arquitectura
- **Falta de Pruebas en Nuevas Funcionalidades**: Modificaciones que incorporen lógica de negocio, endpoints o vistas sin añadir sus correspondientes pruebas unitarias o de widget.
- **Violación de Clean Architecture**: Importaciones cruzadas indebidas o acoplamiento entre capas.
- **Código Huérfano o Depuración Residual**: Presencia de llamadas a consola obsoletas, código comentado residual o `debugger()`.

### 3.4 Proceso y Revisión
- **Solicitud de Cambios Activa (`CHANGES_REQUESTED`)**: Si un revisor identifica un defecto o una mala práctica y solicita cambios, está prohibido hacer merge hasta que los cambios sean corregidos y aprobados.
- **PR Vacío o Genérico**: PRs que no completen la descripción o dejen la plantilla predeterminada sin responder.
- **Commits Directos o Push Forzado a Ramas Protegidas**: Bloqueo técnico total de push forzado a `taller-4`, `taller-2` o `main`. Todo cambio debe ingresar vía Pull Request.

---

## 4. Matriz Resumen de Estados

| Condición | Equipo / Componente | Tipo | Aprobado (Permite Merge) | Rechazado (Bloquea Merge) |
|---|---|---|---|---|
| **PR Merge Gatekeeper** | General (Ambos) | Automático | Título Convencional y sin secretos | Título inválido o secretos detectados |
| **Code Analysis & Linter** | Móvil (Flutter) | Automático | 0 errores, 0 warnings | Errores o warnings de análisis |
| **Unit & Widget Tests** | Móvil (Flutter) | Automático | 100% pruebas aprobadas | >= 1 prueba fallida |
| **Build Web App (Flutter)** | Móvil (Flutter) | Automático | Bundle generado exitosamente | Error en compilación web |
| **Build Android APK** | Móvil (Flutter) | Automático | APK debug compilado | Error en compilación Android |
| **Mobile Integration Tests** | Móvil (Flutter) | Automático | Pruebas headless aprobadas | Fallo en pruebas de integración |
| **Backend Build & Test** | Backend (.NET) | Automático | Compilación y tests con cobertura | Fallo en build o cobertura < 75% |
| **Backend E2E Gateway** | Backend (.NET) | Automático | Newman E2E superado | Fallo en contenedores o Newman |
| **Frontend Build & Lint** | Frontend (React) | Automático | Lint, tests y build exitosos | Error en lint, pruebas o compilación |
| **Revisión por Pares** | General (Ambos) | Manual | >= 1 aprobación formal (`Approved`) | 0 aprobaciones o `Changes Requested` |
| **Hilos de Revisión** | General (Ambos) | Manual | 100% conversaciones resueltas | Conversaciones abiertas / sin resolver |
| **Conflictos de Merge** | General (Ambos) | Automático | Sin conflictos de integración | Presencia de conflictos con base |

---

## 5. Configuración Recomendada de Branch Protection en GitHub

Para que los administradores del repositorio apliquen estas condiciones a nivel de configuración en GitHub (`Settings -> Branches -> Branch protection rules` para `taller-4`, `taller-2` y `main`):

1. **Require a pull request before merging**:
   - Marcar: `Require approvals` = **1**.
   - Marcar: `Dismiss stale pull request approvals when new commits are pushed`.
   - Marcar: `Require review from Code Owners`.
2. **Require status checks to pass before merging**:
   - Marcar: `Require branches to be up to date before merging`.
   - Status checks obligatorios recomendados según rama:
     - **Comunes**:
       - `Validate Merge Conditions` (PR Merge Gatekeeper)
     - **Equipo Móvil (`taller-4`)**:
       - `Code Analysis & Linter`
       - `Unit & Widget Tests`
       - `Build Web App`
       - `Build Android APK (Debug)`
       - `Mobile Integration Tests`
     - **Equipo Backend & Frontend (`taller-2`)**:
       - `build-and-test` (Backend CI)
       - `e2e-gateway-tests` (Backend CI)
       - `build-and-lint` (Frontend CI)
3. **Require conversation resolution before merging**:
   - Marcar: Activo.
4. **Do not allow bypassing the above settings**:
   - Marcar: Aplicar las reglas también a administradores del repositorio.
