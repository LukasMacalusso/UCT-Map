# Pruebas de Integracion de la Aplicacion Movil (UCT-Map)

Este documento describe la arquitectura, diseno y ejecucion de las pruebas de integracion end-to-end (E2E) para la aplicacion movil UCT-Map, implementadas bajo el paquete oficial `integration_test` de Flutter.

---

## 1. Objetivos

1. Validar el ciclo de vida completo de la aplicacion movil en un entorno de ejecucion real.
2. Comprobar la navegacion interactiva y el cambio entre las pantallas principales del sistema.
3. Verificar la integracion del menu lateral institucional (CustomDrawer) y la interaccion del usuario.
4. Asegurar el funcionamiento correcto de las barreras de autenticacion y el desbloqueo de vistas protegidas mediante sesion activa.

---

## 2. Estructura de Archivos

- `uct_map/integration_test/app_integration_test.dart`: Suite principal de pruebas de integracion que interactua con los widgets de la aplicacion mediante `WidgetTester` y simula eventos de usuario.
- `uct_map/test_driver/integration_test.dart`: Script host de Flutter Driver (`integrationDriver()`) necesario para ejecuciones automatizadas y plataformas de pruebas (Firebase Test Lab).
- `uct_map/pubspec.yaml`: Dependencia de desarrollo `integration_test` provista directamente por el SDK de Flutter.

---

## 3. Escenarios Cubiertos

### Flujo 1: Inicio de app y navegacion completa entre tabs
- Carga de `UctMapApp` y verificacion del AppBar institucional.
- Comprobacion de presencia de los 5 destinos de navegacion en la barra inferior: Mapa, Buscar, Objetos, Reportes y Perfil.
- Transicion secuencial entre las pantallas:
  - Tab Buscar: Verificacion del titulo y vista de busqueda.
  - Tab Objetos: Verificacion de la vista protegida de objetos perdidos.
  - Tab Reportes: Verificacion de la vista protegida de reportes e incidencias.
  - Tab Perfil: Verificacion de la pantalla de perfil del estudiante.
  - Retorno al Tab Mapa: Verificacion de la pantalla del mapa interactivo.

### Flujo 2: Menu lateral CustomDrawer e interaccion institucional
- Despliegue del Drawer lateral a traves del boton de logotipo de la UCT.
- Verificacion de los encabezados institucionales: 'UCT Map' y 'Universidad Catolica de Temuco'.
- Comprobacion de elementos del menu institucional ('Inicio y Accesos Rapidos').
- Cierre exitoso del menu lateral retornando al flujo principal.

### Flujo 3: Proteccion de sesion, navegacion a Login y autenticacion
- Intento de acceso a secciones protegidas (Reportes / Objetos) sin sesion activa.
- Validacion de la presencia de `SessionRequiredView` y el boton de 'Iniciar Sesion'.
- Transicion a `LoginPage` comprobando los campos de acceso institucional.
- Retorno y posterior autenticacion exitosa mediante `signInReal` con token JWT valido.
- Verificacion de que las vistas protegidas se desbloquean al contar con sesion autenticada.
- Cierre de sesion (`signOut`) y restauracion del estado inicial.

---

## 4. Ejecucion Local

Para ejecutar las pruebas de integracion de forma local en el proyecto:

```bash
cd uct_map
flutter test integration_test/app_integration_test.dart
```

O utilizando Flutter Driver:

```bash
cd uct_map
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_integration_test.dart
```

---

## 5. Integracion Continua (CI Pipeline)

En el pipeline de GitHub Actions (`.github/workflows/flutter-ci.yml`), el job `integration-tests` ejecuta automaticamente las pruebas de integracion en un servidor virtual headless mediante `xvfb-run`, garantizando que ningun cambio introduzca regresiones en la navegacion ni en la logica central de la aplicacion movil.
