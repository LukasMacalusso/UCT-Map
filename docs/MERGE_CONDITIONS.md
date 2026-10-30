# Políticas de Aprobación y Rechazo de Merge (Merge Conditions)

Este documento define de manera estandarizada los criterios y condiciones obligatorias para la **aprobación** o **rechazo** de la integración (merge) de código hacia las ramas protegidas (`taller-4`, `ti4`, `taller-2`, `ti2` y `main`) en el repositorio **UCT-Map**.

---

## 1. Objetivos

1. **Garantizar la estabilidad**: Prevenir la introducción de regresiones, caídas del sistema o builds rotos.
2. **Asegurar la calidad del código**: Cumplir con los estándares de análisis estático, convenciones de nombres y arquitectura limpia (Clean Architecture).
3. **Fomentar la cultura de revisión**: Promover la colaboración y validación mutua a través de revisiones por pares (Peer Review).
4. **Mantener la trazabilidad**: Asociar cada cambio a un ticket de trabajo (Jira / Issue) y respetar las convenciones de commit.

---

## 2. Condiciones de Apruebo (Approval Conditions / Definition of Done)

Para que un Pull Request sea considerado apto para fusión (Merge) hacia `taller-4` o `main`, **debe cumplir obligatoriamente con la totalidad** de los siguientes requisitos:

### 2.1 Verificación de Integración Continua (CI Pipeline)
Todo PR debe tener el estado de **Checks Passing** (en verde) en el flujo de GitHub Actions (`flutter-ci.yml` y `pr-merge-gate.yml`):
- ✅ **Code Analysis & Linter (`flutter analyze --no-fatal-infos`)**: 0 errores y 0 advertencias de linter conforme a las reglas de `analysis_options.yaml`.
- ✅ **Unit & Widget Tests (`flutter test --coverage`)**: 100% de las pruebas unitarias y de widgets deben ejecutarse y aprobar exitosamente. Cero pruebas fallidas.
- ✅ **Reporte de Cobertura JaCoCo**: Generación y exportación exitosa de los reportes `coverage/jacoco.xml` y `coverage/lcov.info`. Todo nuevo desarrollo debe incluir pruebas asociadas apuntando al umbral objetivo del 90%.
- ✅ **Build de Aplicación Web (`flutter build web --release`)**: Compilación exitosa del bundle web sin dependencias conflictivas.
- ✅ **PR Merge Gatekeeper (`pr-merge-gate.yml`)**: Validación automática de formato de título, ausencia de secretos y descripción completa del PR.

### 2.2 Revisión de Código por Pares (Peer Review)
- ✅ **Aprobación de al menos un revisor**: Se requiere como mínimo **1 aprobación formal** (`Approved`) de un miembro del equipo o Code Owner.
- ✅ **Sin solicitudes de cambios pendientes**: No debe haber ningún estado de `CHANGES_REQUESTED` activo.
- ✅ **Resolución de conversaciones**: Todas las observaciones, preguntas o hilos de discusión iniciados en la pestaña de revisión deben estar explícitamente resueltos (`Resolved`).

### 2.3 Estándar de Commits y Pull Request
- ✅ **Conventional Commits**: El título del PR y los commits deben respetar el estándar:
  - Formato: `<tipo>(<ticket>): <descripción>` o `<tipo>: <descripción>`.
  - Ejemplos válidos:
    - `feat(TI4-98): definir condiciones de merge`
    - `fix(tickets): corregir validacion de formulario`
    - `test(navigation): agregar mock de mapbox`
    - `ci: actualizar pipeline de github actions`
- ✅ **Plantilla de Pull Request (`pull_request_template.md`)**: El autor debe completar la plantilla en su totalidad, indicando el tipo de cambio, el ticket correspondiente, el contexto y marcando afirmativamente la lista de verificación (checklist).

### 2.4 Integridad de la Rama y Conflictos
- ✅ **Rama actualizada**: La rama origen debe estar al día con la rama base (`taller-4`).
- ✅ **Sin conflictos de merge**: El PR no debe presentar conflictos de merge (`Mergeable state: clean`).
- ✅ **Estrategia de Merge recomendada**: `Squash and merge` o `Rebase and merge` para mantener un historial lineal y limpio en la rama base.

---

## 3. Condiciones de Rechazo (Rejection Criteria / Blockers)

Un Pull Request será **rechazado de forma automática o por parte de los revisores** (marcando `Request Changes` o cerrando el PR) si incurre en cualquiera de las siguientes faltas:

### 3.1 Fallo en Checks Automatizados (Bloqueo Automático)
- ❌ **Fallo en Pruebas Unitarias o de Widgets**: Si una o más pruebas fallan en el entorno de CI, el merge queda estrictamente bloqueado.
- ❌ **Violaciones de Linter o Análisis Estático**: Presencia de advertencias (`warnings`), errores de sintaxis o imports no utilizados reportados por `flutter analyze`.
- ❌ **Fallo de Compilación**: Incompatibilidades que impidan la generación del build web (`flutter build web`).

### 3.2 Seguridad y Archivos Sensibles
- ❌ **Inclusión de Secretos o Credenciales**: Queda terminantemente prohibido comitear:
  - Archivos `.env` con valores reales.
  - Llaves privadas (`.pem`, `.key`, `id_rsa`).
  - Tokens de autenticación, API Keys de producción o contraseñas en texto plano.
  *Cualquier PR que viole esta condición será rechazado inmediatamente y el autor deberá limpiar el historial de commits (`git filter-branch` / reescribir historial) y rotar los secretos comprometidos.*

### 3.3 Calidad de Código y Arquitectura
- ❌ **Falta de Pruebas en Nuevas Funcionalidades**: Modificaciones que incorporen lógica de negocio, endpoints o vistas sin añadir sus correspondientes pruebas unitarias o de widget.
- ❌ **Violación de Clean Architecture**: Importaciones cruzadas indebidas (por ejemplo, la capa de dominio dependiendo de infraestructura o paquetes de UI de Flutter).
- ❌ **Código Huérfano o Depuración Residual**: Presencia de `print()`, código comentado obsoleto, `debugger()` o imports huérfanos.

### 3.4 Proceso y Revisión
- ❌ **Solicitud de Cambios Activa (`CHANGES_REQUESTED`)**: Si un revisor identifica un defecto o una mala práctica y solicita cambios, está prohibido hacer merge hasta que los cambios sean corregidos y aprobados.
- ❌ **PR Vacío o Genérico**: PRs que no completen la descripción o dejen la plantilla predeterminada sin responder.
- ❌ **Commits Directos o Push Forzado a Ramas Protegidas**: Bloqueo técnico total de `git push origin taller-4 --force` o `git push origin main`. Todo cambio debe ingresar vía Pull Request.

---

## 4. Matriz Resumen de Estados

| Condición | Tipo | Aprobado (Permite Merge) | Rechazado (Bloquea Merge) |
|---|---|---|---|
| **Pipeline de CI** | Automático | Todos los jobs en verde (Passing) | 1 o más jobs en rojo (Failing) |
| **Pruebas (Tests)** | Automático | 100% pruebas aprobadas | >= 1 prueba fallida o con error |
| **Linter / Analyze** | Automático | 0 errores, 0 warnings | Errores o warnings de análisis |
| **Archivos Sensibles** | Automático | Sin secretos comiteados | Presencia de `.env`, `.key`, tokens |
| **Revisión por Pares** | Manual | >= 1 aprobación formal (`Approved`) | 0 aprobaciones o `Changes Requested` |
| **Hilos de Revisión** | Manual | 100% conversaciones resueltas | Conversaciones abiertas / sin resolver |
| **Conflictos de Merge** | Automático | Sin conflictos de integración | Presencia de conflictos con base |
| **Conventional Commits** | Automático | Título y formato estándar válido | Título no convencional o ambiguo |

---

## 5. Configuración Recomendada de Branch Protection en GitHub

Para que los administradores del repositorio apliquen estas condiciones a nivel de configuración en GitHub (`Settings -> Branches -> Branch protection rules` para `taller-4` y `main`):

1. **Require a pull request before merging**:
   - Marcar: `Require approvals` = **1**.
   - Marcar: `Dismiss stale pull request approvals when new commits are pushed`.
   - Marcar: `Require review from Code Owners`.
2. **Require status checks to pass before merging**:
   - Marcar: `Require branches to be up to date before merging`.
   - Status checks obligatorios requeridos:
     - `Code Analysis & Linter`
     - `Unit & Widget Tests`
     - `Build Web App`
     - `PR Merge Gatekeeper / Conditions Check`
3. **Require conversation resolution before merging**:
   - Marcar: Activo.
4. **Do not allow bypassing the above settings**:
   - Marcar: Aplicar las reglas también a administradores del repositorio.
