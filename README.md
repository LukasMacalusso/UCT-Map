# UCT-Map (Integra 4 - Mobile)

Aplicación móvil desarrollada en Flutter para la navegación interactiva de campus, localización de salas, oficinas de profesores y gestión de reportes / objetos perdidos en la Universidad Católica de Temuco (UCT).

---

## 🚀 Flujo de Trabajo y Políticas de Integración

- **Condiciones de Apruebo y Rechazo de Merge**: Consulta la normativa completa y obligatoria en [docs/MERGE_CONDITIONS.md](docs/MERGE_CONDITIONS.md).
- **Plantilla de Pull Request**: Configurada con checklist de criterios de aceptación en [.github/pull_request_template.md](.github/pull_request_template.md).
- **Propietarios de Código (Code Owners)**: Definidos en [.github/CODEOWNERS](.github/CODEOWNERS).
- **Pipeline de CI/CD**: Automatizado con GitHub Actions en [.github/workflows/flutter-ci.yml](.github/workflows/flutter-ci.yml) y [.github/workflows/pr-merge-gate.yml](.github/workflows/pr-merge-gate.yml).

---

## 🧪 Pruebas y Cobertura de Código

Para ejecutar localmente la suite de pruebas unitarias y de widgets con generación de reporte JaCoCo XML:

```bash
cd uct_map
flutter test --coverage
dart run tool/generate_jacoco_report.dart
```

---

## 🛠️ Tecnologías del Proyecto

- **Framework**: Flutter (Dart 3.x)
- **Mapas**: Mapbox Maps SDK para Flutter
- **Arquitectura**: Clean Architecture
- **Métricas de Calidad**: JaCoCo XML (umbral 90%), `flutter analyze`
- **CI/CD**: GitHub Actions
