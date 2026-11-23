## Descripción del Cambio
<!-- Proporciona un resumen claro y conciso de los cambios introducidos en este PR. -->

Closes / Ref: `[ID-Ticket, ej: TI4-100 o UCT-122]`

---

## Tipo de Cambio
- [ ] `feat`: Nueva funcionalidad
- [ ] `fix`: Corrección de un error (bug fix)
- [ ] `refactor`: Refactorización de código sin cambios funcionales
- [ ] `test`: Adición o actualización de pruebas
- [ ] `ci`: Cambios en la configuración o workflows de CI/CD
- [ ] `docs`: Actualización de documentación
- [ ] `chore`: Tareas de mantenimiento o configuración

---

## Lista de Verificación de Apruebo (Condiciones Obligatorias)
Para que este PR pueda ser aprobado e integrado a `taller-4`, `taller-2` o `main`, **todos los puntos aplicables deben ser validados**:

### Validación General y Gatekeeper
- [ ] **Título del PR**: Cumple con el estándar de *Conventional Commits* (ej. `ci(TI4-100): descripción` o `feat(UCT-XX): descripción`).
- [ ] **Seguridad**: No se comitean secretos, API keys, credenciales ni archivos `.env`.
- [ ] **Sincronización**: La rama está al día con la rama base (`taller-4` o `taller-2`) y no presenta conflictos de merge.
- [ ] **Revisión por Pares**: Se ha solicitado revisión a al menos 1 integrante del equipo.

### Equipo Móvil (Flutter / Taller 4)
- [ ] **Análisis Estático**: `flutter analyze` pasa exitosamente con **0 errores y 0 warnings**.
- [ ] **Pruebas Unitarias y de Widgets**: Todas las pruebas (`flutter test`) pasan al 100% sin fallos.
- [ ] **Cobertura JaCoCo**: Reporte generado (`coverage/jacoco.xml`) apuntando al umbral objetivo del 90%.
- [ ] **Compilación**: Aplicación compila sin errores en Web (`flutter build web`) y Android (`flutter build apk --debug`).
- [ ] **Pruebas de Integración**: Pruebas headless aprobadas (`app_integration_test.dart`).

### Equipo Backend & Web Frontend (Taller 2)
- [ ] **Formato y Compilación .NET**: `dotnet format` y `dotnet build` sin advertencias ni cambios pendientes.
- [ ] **Pruebas de Backend y Cobertura**: Pruebas unitarias/integración aprobadas con cobertura Cobertura (`>= 75%`).
- [ ] **Pruebas E2E API Gateway**: Pruebas de integración Newman / Docker Compose ejecutadas y aprobadas (`make test-e2e`).
- [ ] **Frontend Web (React)**: `npm run lint`, pruebas unitarias con cobertura y `npm run build` sin errores.

---

## Criterios de Rechazo (Blockers)
Este Pull Request será **rechazado o devuelto para corrección** si presenta cualquiera de los siguientes problemas:
- Falla en cualquiera de los checks automáticos del CI (`flutter-ci.yml`, `backend-ci.yml`, `frontend-ci.yml`, `pr-merge-gate.yml`).
- Hay observaciones o solicitudes de cambio pendientes (`Changes Requested`) sin resolver.
- El nuevo código de negocio o UI carece de pruebas automatizadas que respalden su funcionamiento.
- Inclusión de variables de entorno con credenciales reales o llaves privadas expuestas.
- Conflictos de integración no resueltos con la rama destino.

---

## Evidencia / Pruebas
<!-- Adjunta capturas de pantalla, logs de pruebas locales exitosas o reporte de cobertura. -->
```bash
# Ejemplo: flutter test / dotnet test / npm test
```
