## 📌 Descripción del Cambio
<!-- Proporciona un resumen claro y conciso de los cambios introducidos en este PR. -->

Closes / Ref: `[ID-Ticket, ej: TI4-98]`

---

## 🏷️ Tipo de Cambio
- [ ] ✨ `feat`: Nueva funcionalidad
- [ ] 🐛 `fix`: Corrección de un error (bug fix)
- [ ] ♻️ `refactor`: Refactorización de código sin cambios funcionales
- [ ] 🧪 `test`: Adición o actualización de pruebas
- [ ] 🚀 `ci`: Cambios en la configuración o workflows de CI/CD
- [ ] 📝 `docs`: Actualización de documentación
- [ ] 🔧 `chore`: Tareas de mantenimiento o configuración

---

## ✅ Lista de Verificación de Apruebo (Condiciones Obligatorias)
Para que este PR pueda ser aprobado e integrado a `taller-4` o `main`, **todos los puntos siguientes deben ser validados**:

- [ ] **Título del PR**: Cumple con el estándar de *Conventional Commits* (ej. `feat(TI4-XX): descripción`).
- [ ] **Análisis Estático**: `flutter analyze` pasa exitosamente con **0 errores y 0 warnings**.
- [ ] **Pruebas Unitarias y de Widgets**: Todas las pruebas (`flutter test`) pasan al 100% sin fallos.
- [ ] **Cobertura de Código**: Se han incluido pruebas para el nuevo código y se generó el reporte JaCoCo (`coverage/jacoco.xml`).
- [ ] **Compilación**: La aplicación compila correctamente sin errores (`flutter build web`).
- [ ] **Seguridad**: No se comitean secretos, API keys, credenciales ni archivos `.env`.
- [ ] **Sincronización**: La rama está al día con la rama base (`taller-4`) y no presenta conflictos de merge.
- [ ] **Revisión por Pares**: Se ha solicitado revisión a al menos 1 integrante del equipo.

---

## ⛔ Criterios de Rechazo (Blockers)
Este Pull Request será **rechazado o devuelto para corrección** si presenta cualquiera de los siguientes problemas:
- ❌ Falla en cualquiera de los checks automáticos del CI (`flutter-ci.yml` / `pr-merge-gate.yml`).
- ❌ Hay observaciones o solicitudes de cambio pendientes (`Changes Requested`) sin resolver.
- ❌ El nuevo código de negocio o UI carece de pruebas automatizadas que respalden su funcionamiento.
- ❌ Inclusión de variables de entorno con credenciales reales o llaves privadas expuestas.
- ❌ Conflictos de integración no resueltos con la rama destino.

---

## 📸 Evidencia / Pruebas
<!-- Adjunta capturas de pantalla, logs de pruebas locales exitosas o reporte de cobertura. -->
```bash
# Ejemplo: flutter test
```
