# UCT Map - Mobile Application (Flutter)

Aplicación móvil desarrollada en **Flutter** para la navegación interactiva de campus, localización de salas, directorio de profesores y gestión de reportes e incidencias / objetos perdidos en la Universidad Católica de Temuco (UCT).

---

## Tecnologías del Proyecto

- **Framework**: Flutter (Dart `^3.13.1`)
- **Mapas**: Mapbox Maps SDK para Flutter (`mapbox_maps_flutter`)
- **Arquitectura**: Clean Architecture (`core`, `domain`, `data`, `presentation`)
- **Métricas de Calidad**: Cobertura JaCoCo XML (umbral 90%), análisis estático con `flutter analyze`
- **CI/CD**: GitHub Actions ([`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml))

---

## Guía de Ejecución Local

### Requisitos Previos

- **Flutter SDK** con Dart `^3.13.1` (verificar con `flutter doctor` y `flutter devices`).
- **Chrome** (para versión web de prueba) o **Android Studio / Xcode** con un emulador o dispositivo físico configurado.
- **Docker y Docker Compose** para levantar el backend y el API Gateway localmente.
- Un **token público de Mapbox** (`pk.xxx`) con acceso al mapa y a Directions API.

### 1. Levantar el Backend y API Gateway

Desde la raíz del repositorio, levanta las bases de datos, microservicios y el API Gateway:

```bash
docker compose up -d --build postgres mongodb identity-api campus-api incident-api schedule-api api-gateway
docker compose ps
```

### 2. Configurar Variables de Entorno (`.env`) y Token de Mapbox

Crea un archivo `.env` dentro de `src/mobile/` (si aún no existe):

```dotenv
API_BASE_URL=http://localhost:5000
MAPBOX_TOKEN=PEGA_AQUI_TU_TOKEN_PUBLICO
```

- **En Chrome / Web local**: usa `API_BASE_URL=http://localhost:5000`.
- **En Emulador Oficial de Android**: usa `API_BASE_URL=http://10.0.2.2:5000`.
- **En Dispositivo Físico**: usa la IP local de tu computador en la misma red Wi-Fi (ej. `http://192.168.1.50:5000`).

> **Importante**: Mapbox se configura al compilar mediante `--dart-define=ACCESS_TOKEN=...`. El archivo `.env` está incluido en los assets de Flutter, por lo que no debe contener claves privadas ni secretos (`sk.`).

### 3. Ejecutar en Chrome

Desde la carpeta `src/mobile/`:

```bash
cd src/mobile
flutter pub get
flutter run -d chrome --dart-define="ACCESS_TOKEN=$(sed -n 's/^MAPBOX_TOKEN=//p' .env | tail -n 1)"
```

O pasando directamente tu token público:

```bash
flutter run -d chrome --dart-define=ACCESS_TOKEN=TU_TOKEN_PUBLICO
```

### 4. Ejecutar en Android o iOS

Con un emulador o dispositivo conectado:

```bash
cd src/mobile
flutter devices
flutter run -d ID_DEL_DISPOSITIVO --dart-define="ACCESS_TOKEN=$(sed -n 's/^MAPBOX_TOKEN=//p' .env | tail -n 1)"
```

---

## Pruebas y Cobertura de Código

Para ejecutar localmente el análisis estático, las pruebas unitarias/widgets y generar el reporte JaCoCo XML:

```bash
cd src/mobile
flutter analyze --no-fatal-infos
flutter test --coverage
dart run tool/generate_jacoco_report.dart
```

Para ejecutar las pruebas de integración E2E de la aplicación móvil:

```bash
cd src/mobile
flutter test integration_test/app_integration_test.dart
```
