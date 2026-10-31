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

---

## Inicio del proyecto con Mapbox

### Requisitos

- Flutter con Dart compatible con la versión indicada en `uct_map/pubspec.yaml` (actualmente Dart 3.13.1 o superior compatible).
- Chrome para ejecutar la versión web; para Android o iOS, un emulador o dispositivo configurado con Flutter.
- Docker y Docker Compose para ejecutar el backend local.
- Un **token público de Mapbox** con acceso al mapa y a Directions API. No uses un token secreto (`sk.`) en la aplicación.

Comprueba la instalación de Flutter con `flutter doctor` y los dispositivos disponibles con `flutter devices`.

### 1. Levantar los servicios

Consigue el código de los microservicios y colócalo en `src/backend/`; no está incluido en este repositorio. Luego, desde la raíz, crea la configuración local:

```bash
cp .env.example .env
# Edita .env con contraseñas propias y una clave JWT larga.
docker compose up -d --build
docker compose ps
```

El archivo `.env` de la raíz define `POSTGRES_PASSWORD`, `MONGO_PASSWORD` y `UCT_JWT_KEY`. Usa contraseñas alfanuméricas para evitar problemas al incluirlas en las conexiones y una clave JWT larga y aleatoria. El gateway queda en `http://localhost:8080`.

PostgreSQL crea las bases al inicializar un volumen nuevo; las migraciones de los servicios crean sus tablas. Los volúmenes existentes conservan sus datos y contraseñas. El archivo `.env` es local y no se sube al repositorio.

### 2. Configurar la app y el token de Mapbox

Crea `uct_map/.env` si aún no existe. Para Chrome y el backend local, el contenido mínimo es:

```dotenv
API_BASE_URL=http://localhost:8080
MAPBOX_TOKEN=PEGA_AQUI_TU_TOKEN_PUBLICO
```

Reemplaza el valor de `MAPBOX_TOKEN` con tu propio token. Para Android en el emulador oficial, usa `API_BASE_URL=http://10.0.2.2:8080`; en un teléfono físico, usa la IP local del computador accesible desde el teléfono en lugar de `localhost`.

**Mapbox se configura al compilar mediante `ACCESS_TOKEN`**. Guardar `MAPBOX_TOKEN` en `.env` no lo entrega automáticamente al SDK: debes pasarlo con `--dart-define` al ejecutar la app. El archivo `.env` está incluido como recurso de Flutter, por lo que no debe contener contraseñas, tokens secretos ni claves privadas.

### 3. Ejecutar en Chrome

Desde la raíz del repositorio:

```bash
cd uct_map
flutter pub get
flutter run -d chrome --dart-define="ACCESS_TOKEN=$(sed -n 's/^MAPBOX_TOKEN=//p' .env | tail -n 1)"
```

El comando toma el último valor de `MAPBOX_TOKEN` del archivo `.env`; déjalo sin comillas y sin espacios alrededor de `=`. La app debe abrirse en `localhost` para que Chrome pueda solicitar la ubicación. Al usar «Mi ubicación» o «Cómo llegar», acepta el permiso del navegador.

También puedes pasar directamente el token público sin guardarlo en el archivo:

```bash
flutter run -d chrome --dart-define=ACCESS_TOKEN=TU_TOKEN_PUBLICO
```

### 4. Ejecutar en Android o iOS

Con un emulador o dispositivo conectado, configura primero `API_BASE_URL` para ese dispositivo y ejecuta desde `uct_map/`:

```bash
flutter devices
flutter run -d ID_DEL_DISPOSITIVO --dart-define="ACCESS_TOKEN=$(sed -n 's/^MAPBOX_TOKEN=//p' .env | tail -n 1)"
```

Reemplaza `ID_DEL_DISPOSITIVO` por uno de los identificadores que muestra `flutter devices`. En iOS se necesita macOS y las herramientas de desarrollo de Apple. Acepta el permiso de ubicación cuando la app lo solicite.

### Problemas frecuentes

- **Mapa vacío o error de token:** verifica que el token sea público, esté habilitado para los servicios de Mapbox y se haya pasado como `ACCESS_TOKEN`. Reinicia la app tras modificarlo.
- **No carga campus o edificios:** comprueba `docker compose ps`, la dirección `API_BASE_URL` y la sesión de usuario. Algunos endpoints requieren iniciar sesión.
- **No aparece la ubicación:** revisa que esté activada en el dispositivo y que el navegador o la app tengan permiso. En Chrome usa `localhost` o HTTPS.
- **No se encuentra una ruta:** comprueba la conexión, el token y que Mapbox pueda calcular un recorrido a pie entre los puntos. Los datos simulados del desarrollo no representan ubicaciones reales.

Para detener los contenedores sin eliminar sus volúmenes:

```bash
docker compose stop
```
