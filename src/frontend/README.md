# UCT Map Frontend

## Componentes

| Componente | Descripción | Parámetros principales (Props) |
|---|---|---|
| `AppLayout` | Layout principal persistente (barra lateral y área de contenido). | N/A |
| `Avatar` | Muestra una imagen de perfil circular. | `src`, `alt`, `className` |
| `Button` | Botón interactivo principal (Soporta estado `disabled`). | `variant` (solid/outline/ghost), `color`, `size`, `width`, `disabled` |
| `CheckboxItem` | Elemento de selección (checkbox) con título y descripción. | `label`, `desc`, `icon` |
| `ExitButton` | Botón estándar de cierre (X). | `variant` (solid/ghost), `size` |
| `FileUpload` | Área interactiva para arrastrar y soltar archivos. | `label`, `maxFiles`, `onFilesChange` |
| `GlobalModals` | Contenedor maestro de modales flotantes globales gestionado por Zustand. | N/A |
| `IconText` | Bloque pequeño de texto acompañado de un ícono. | `icon`, `text`, `className` |
| `ImageControls` | Botones de navegación (anterior/siguiente) para galería. | `onPrev`, `onNext` |
| `ImageGallery` | Carrusel automático de imágenes. | `images`, `autoPlayInterval`, `width`, `height` |
| `ImagePagination` | Indicadores de posición (puntos) para la galería. | `total`, `currentIndex`, `onSelect` |
| `Input` | Campo estándar para ingreso de texto con etiqueta opcional superior. | `label`, `labelColor` (opcional), `error`, `multiline`, `icon`, *Props HTML* |
| `LoadingSpinner` | Componente visual animado para indicar carga. | `size` (sm/md/lg/xl), `color`, `text`, `className` |
| `ModalOverlay` | Envoltorio con animaciones y fondo oscuro para pop-ups. | `isOpen`, `onClose`, `children` |
| `NavButton` | Enlace de navegación para rutas del React Router. | `to`, `icon`, `label`, `size`, `width` |
| `NumberSelect` | Selector numérico con botones de incremento/decremento. | `initialValue`, `multiplier`, `isFloat`, `min`, `max`, `variant` |
| `Panel` | Contenedor reutilizable con estilos estandarizados de tarjeta. | `children`, `color`, `withUctBorder`, `onClose` |
| `PhotoFrame` | Contenedor con borde para mostrar imágenes o miniaturas. | `src`, `alt`, `className` |
| `SearchInput` | Campo de texto avanzado con menú desplegable de sugerencias. | `label`, `placeholder`, `value`, `onChange`, `icon`, `options` |
| `SectionButton` | Botón especializado para el menú de navegación lateral. | `to`, `icon`, `label`, `isExpanded`, `expandedWidth` |
| `Select` | Menú desplegable de selección de opciones con bordes UCT. | `label`, `labelColor`, `options`, `icon`, `error` |
| `SquareButton` | Botón interactivo cuadrado. | `children` |
| `Tag` | Etiqueta pequeña (pill) para categorías o estados. | `label`, `icon`, `color` |
| `TimedActionCard` | Tarjeta para acciones críticas con barra de progreso regresiva y bordes activos UCT. | `title`, `description`, `initialDurationMs`, `options` |
| `UserActionInfo` | Muestra detalles rápidos de un usuario o acción. | `title`, `subtitle`, `avatarSrc` |

## Módulos

Para mantener la arquitectura escalable, las piezas de interfaz más complejas (que agrupan múltiples componentes genéricos) se organizan en **módulos** dentro de la carpeta `src/modules`.

| Módulo | Componente | Descripción del componente | Parámetros |
|---|---|---|---|
| `admin` | `UserManagementCard` | Tarjeta para la gestión administrativa de usuarios, roles y suspensiones. | `role`, `isSuspended`, `onRoleChange`, `onToggleSuspension` |
| `admin` | `MapEditorPanel` | Panel animado con herramientas para la edición interactiva del mapa. | N/A |
| `global` | `UserProfilePanel` | Panel lateral con información del usuario logueado y reportes activos. | `name`, `admissionYear`, `career`, `email`, `photoUrl`, `objectReports`, `incidentReports`, `onClose` |
| `map` | `BuildingDetailCard` | Tarjeta/Modal detallado de edificio con carrusel, horarios y salas. | `title`, `subtitle`, `images`, `schedule`, `floors`, `services`, `rooms`, `onClose`, `onNavigate`, `onView360`, `onReportProblem` |
| `map` | `HeatmapSpot` | Elemento visual superpuesto en el mapa que representa zonas térmicas. | `intensity` (low/medium/high), `size`, `className` |
| `map` | `MapFiltersPanel` | Panel interactivo para filtrar categorías y ubicaciones dentro del mapa. | `title`, `sections`, `onToggleItem`, `className` |
| `map` | `MapMarker` | Botón interactivo usado como pin en el mapa. | `icon`, `color` |
| `map` | `RoomInfoCard` | Tarjeta/Banner informativo de sala con título, tipo y capacidad. | `title`, `type`, `capacity`, `icon`, `className` |
| `map` | `ScheduleCard` | Banner/Tarjeta informativa de horario de atención. | `title`, `schedule`, `icon`, `color`, `className` |
| `contacts` | `ContactProfilePanel`, `ContactCard` | Perfiles de profesores, personal e información de contacto. | `title`, `contact`, `onClose`, `className` |
| `objects` | `PublishReportCard`, `ObjectReportCard`, `ReportLostObjectCard` | Modales/Cards para la gestión de objetos perdidos y encontrados. | Múltítulos props según tarjeta. |
| `incidents` | `IncidentCard` | Tarjeta para visualizar un reporte de incidente. | `location`, `status`, `photoUrl`, `title`, `reporterName`, `reportTime`, `reporterAvatar`, `description` |

## Vistas

Las vistas principales de la aplicación corresponden a las páginas renderizadas por cada ruta (`src/views`).

| Vista | Ruta | Descripción |
|---|---|---|
| `MapView` | `/map` | Vista interactiva del mapa del campus y filtros. |
| `IncidentsView` | `/reports` | Vista de reportes de incidentes con filtro por antigüedad y creación. |
| `ObjectsView` | `/objects` | Vista de gestión de objetos perdidos con filtros. |
| `ContactsView` | `/contacts` | Vista de contactos institucionales filtrables por rol. |
| `AdministrationView` | `/administration` | Panel protegido de administración general del sistema (solo Admin/Teacher). |
| `LoginView` | `/login` | Inicio de sesión |
| `ShowcaseView` | `/showcase` | Galería interactiva para pruebas y prototipado de componentes. |

## Enrutamiento y Control de Acceso (AppRouter, ProtectedRoute, RoleGuard)

El frontend implementa una arquitectura de navegación desacoplada y fuertemente tipada con **React Router v7** y **Zustand**, organizada en el directorio `src/router/`:

```
src/router/
├── AppRouter.tsx        # Árbol jerárquico de rutas y vistas de la aplicación
├── ProtectedRoute.tsx   # Guardián de navegación a nivel de ruta (Route Guard)
├── RoleGuard.tsx        # Guardián granular de interfaz a nivel de componente (UI Guard)
└── ProtectedRoute.test.tsx
```

---

### 1. `AppRouter` (`src/router/AppRouter.tsx`)
* **¿Qué es?**: Componente central que define la jerarquía completa de rutas de la aplicación Single Page Application (SPA).
* **¿Para qué sirve y cómo funciona?**:
  * **Separación de layouts**: Define rutas autónomas sin barra de navegación (como `/login`) y rutas envueltas en el diseño principal (`<AppLayout />`), el cual proporciona la barra lateral persistente y los paneles modales globales.
  * **Estructura jerárquica de permisos**:
    1. **Rutas Públicas Generales**: Accesibles sin autenticación previa (`/map`, `/showcase`).
    2. **Rutas Protegidas Autenticadas**: Requieren iniciar sesión obligatoriamente (`/contacts`, `/reports`, `/objects`). Si el usuario es anónimo o visitante no autenticado, se le redirige automáticamente a `/login` mediante `unauthorizedTo="/login"`.
    3. **Rutas Restringidas por Rol**:
       * `Role.Admin`: Protege el panel `/administration` y las subrutas anidadas del editor del mapa `/edition` (`/edition/map`, `/edition/campus`, `/edition/buildings`, `/edition/filters`).
       * `Role.Teacher`: Protege la gestión de horarios y bloques de atención docente en `/schedule`.
  * **Ruta de fallback (Catch-all)**: Cualquier URL desconocida o no registrada es interceptada por `<Route path="*" element={<Navigate to="/map" />} />`, asegurando que el usuario regrese a la vista principal del mapa.

---

### 2. `ProtectedRoute` (`src/router/ProtectedRoute.tsx`)
* **¿Qué es?**: Componente envoltorio (*Route Layout Guard*) que aprovecha el patrón `<Outlet />` de React Router para proteger rutas completas o grupos de rutas anidadas.
* **Propiedades (Props)**:
  | Propiedad | Tipo | Obligatorio | Descripción |
  |---|---|---|---|
  | `allowedRoles` | `Role[]` | No | Lista de roles autorizados para acceder (ej. `[Role.Admin]`). Si no se proporciona, solo valida que el usuario esté autenticado. |
  | `unauthorizedTo` | `string` | No (default: `"/map"`) | Ruta a la que se redirige al usuario si no cumple con la autenticación o con los roles permitidos. |

* **Lógica de evaluación**:
  1. Consulta reactivamente el estado de autenticación en Zustand (`useAuthState`).
  2. Si `!isAuthenticated` o no existe `user`, redirige a `unauthorizedTo` reemplazando el historial (`replace`).
  3. Si se definieron `allowedRoles` y el rol actual del usuario (`user.role`) no forma parte de dicha lista, deniega el acceso y redirige a `unauthorizedTo`.
  4. Si se superan todas las validaciones, renderiza el `<Outlet />`, desplegando la vista hija correspondiente.

* **Ejemplo de uso en el Router**:
  ```tsx
  // Solo usuarios con rol Administrador
  <Route element={<ProtectedRoute allowedRoles={[Role.Admin]} unauthorizedTo="/map" />}>
    <Route path="/administration" element={<AdministrationView />} />
  </Route>

  // Cualquier usuario con sesión activa (redirige a /login si no ha iniciado sesión)
  <Route element={<ProtectedRoute unauthorizedTo="/login" />}>
    <Route path="/reports" element={<IncidentsView />} />
  </Route>
  ```

---

### 3. `RoleGuard` (`src/router/RoleGuard.tsx`)
* **¿Qué es?**: Componente guardián condicional para elementos visuales dentro del DOM.
* **¿Para qué sirve?**: Permite ocultar o mostrar partes específicas de la interfaz (botones de acción, pestañas administrativas, controles de edición o eliminación) según el rol del usuario logueado, sin necesidad de alterar la lógica de rutas.
* **Propiedades (Props)**:
  | Propiedad | Tipo | Obligatorio | Descripción |
  |---|---|---|---|
  | `allowedRoles` | `Role[]` | Sí | Array con los roles que tienen permiso para visualizar los componentes hijos (`children`). |
  | `children` | `React.ReactNode` | Sí | Elementos JSX que se renderizarán si el usuario cuenta con el rol requerido. |

* **Comportamiento**:
  * Si el usuario no ha iniciado sesión (`!user`) o su rol no está incluido en `allowedRoles`, el componente retorna `null`, evitando que el elemento exista en el DOM.
  * Si el rol es válido, renderiza los elementos hijos envueltos en un fragmento `<>{children}</>`.

* **Ejemplo de uso en vistas o componentes**:
  ```tsx
  import { RoleGuard } from '../router/RoleGuard';
  import { Role } from '../constants/role';

  <RoleGuard allowedRoles={[Role.Admin, Role.ObjectsOfficer]}>
    <button onClick={handleOpenCreateReportModal}>
      Publicar Objeto Encontrado
    </button>
  </RoleGuard>
  ```

---

### 4. Acceso al Estado de Usuario en Lógica Interna
Cuando se requiere condicionar flujos en funciones, hooks o efectos secundarios sin un componente visual, se consulta directamente el store de autenticación:
```tsx
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';

const user = useAuthState(state => state.user);

if (user?.role === Role.Admin) {
  // Lógica administrativa específica
}
```

## Gestión de Modales Globales

Gracias a la arquitectura basada en estado global (Zustand) y React Portals integrados, crear y lanzar ventanas flotantes (Modales) que se sobreponen a toda la aplicación es sumamente sencillo y no requiere "ensuciar" el estado local de tus vistas.

Sigue estos 3 pasos para crear un panel flotante nuevo:

1. **Registra el nombre del Panel:**
   Añade un identificador único en `src/states/uiState.ts`:
   ```tsx
   type Panel = 'none' | 'saveMapChanges' | 'discardMapChanges' | 'miNuevoPanel';
   ```

2. **Dibuja el Modal:**
   Agrega tu diseño envuelto en `<ModalOverlay>` dentro del componente central `src/components/layout/GlobalModals.tsx`. Esto garantiza que la ventana tenga el fondo oscuro, las animaciones de entrada/salida y que flote por encima de la barra de navegación:
   ```tsx
   <ModalOverlay 
     isOpen={activePanel === 'miNuevoPanel'} 
     onClose={closePanel}
   >
     <div className="bg-white p-8 rounded-xl shadow-lg">
       <h2 className="text-2xl font-bold">¡Hola!</h2>
       <p>Soy un panel flotante.</p>
     </div>
   </ModalOverlay>
   ```

3. **Ejecuta (Trigger):**
   Desde cualquier botón o componente de la aplicación, sin importar cuán profundo esté, invoca el estado global para abrirlo:
   ```tsx
   import { useUiState } from '../states/uiState';

   <button onClick={() => useUiState.getState().openPanel('miNuevoPanel')}>
     Abrir Panel
   </button>
   ```

## Configuración de Docker 

El Frontend se despliega Dockerizado. Para mantener la imagen Docker inmutable y evitar problemas, la comunicación con el API Gateway se realiza a través de un proxy inverso.

* **Nginx Reverse Proxy:** 
  El archivo `nginx.conf` en este directorio configura a Nginx (el servidor que sirve el frontend dentro de Docker) para interceptar cualquier petición HTTP que comience con `/api/` y redirigirla internamente al contenedor `api-gateway` (puerto `8080`) en la misma red de Docker.
* **Peticiones Relativas:**
  El cliente HTTP del frontend (`httpClient.ts`) realiza peticiones a rutas relativas (ej. `httpClient.post('/api/identity/login')`). Esto permite que el navegador haga la petición al mismo dominio y puerto del frontend, delegando en Nginx el enrutamiento.
* **Desarrollo Local (Sin Docker):** 
  Para el desarrollo puramente local (ejecutando `npm run dev` sin Docker), Nginx no está presente. Para evitar errores y simular el comportamiento exacto de producción, se ha configurado un proxy interno en `vite.config.ts`:

  ```typescript
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true
      }
    }
  }
  ```
  Con esta configuración, el servidor de desarrollo de Vite actúa como Nginx, interceptando cualquier petición de React que comience con `/api/` y la redirige al API Gateway local (`http://localhost:5000`). 

## Arquitectura de Peticiones y Ciclo de Vida

El ciclo de vida de una petición HTTP típica es el siguiente:

1. **Capa de Presentación (React + TanStack Query):**
   El componente de la interfaz de usuario invoca un hook que encapsula a TanStack Query. Esta herramienta asume la responsabilidad del manejo del estado de la petición, previniendo dependencias directas de red en la UI.
2. **Capa de Infraestructura (Servicios y Axios):**
   El servicio correspondiente (como `authService`) utiliza el cliente HTTP (configurado con `axios`) para serializar el payload y emitir una petición asíncrona hacia una ruta relativa.
3. **Inverse Proxy (Nginx):**
   La petición es interceptada por el servidor Nginx que orquesta el frontend. Mediante las reglas de enrutamiento definidas en `nginx.conf`, cualquier tráfico con el prefijo `/api/` es delegado internamente a través de la red de Docker hacia el contenedor del API Gateway.
4. **Enrutamiento Central (API Gateway - YARP):**
   El API Gateway recibe la petición, resuelve la regla de ruteo configurada y balancea o redirige el tráfico hacia el microservicio correspondiente.
5. **Microservicios del Backend:**
   El controlador del microservicio objetivo valida la solicitud y delega la lógica de negocio a los Casos de Uso.
6. **Retorno y Actualización de Estado:**
   La respuesta transita la misma ruta en sentido inverso. El servicio resuelve la promesa, TanStack Query actualiza su estado reactivo de forma automática, y la vista del frontend refleja los cambios correspondientes.

## Capa de Servicios (Data Access Layer)

Los servicios ubicados en `src/services/` actúan como la capa de abstracción y acceso a datos (*Data Access Layer*) de la aplicación. Su responsabilidad exclusiva es comunicarse con los microservicios del backend a través de `httpClient` y transformar las respuestas en DTOs fuertemente tipados.

### Principios y Reglas de Diseño

1. **Aislamiento de la UI**: Los componentes de React **nunca** llaman a los servicios directamente ni realizan peticiones HTTP directas. Consumen los *custom hooks* de **TanStack Query** (`useCampuses`, `useSchedule`, `useLostObjects`, etc.), los cuales delegan la petición al servicio correspondiente y administran el estado reactivo (`data`, `isLoading`, `error`).
2. **Normalización uniforme de errores**: Cada método dentro de un servicio envuelve su llamada en un bloque `try/catch` y canaliza cualquier excepción hacia `toApiError(error, 'Mensaje amigable')`, asegurando que la UI siempre reciba instancias consistentes de `ApiError`.
3. **Mapeo directo con Microservicios del Backend**: Cada servicio del frontend encapsula las operaciones de un microservicio específico del ecosistema UCT Map.

### Catálogo de Servicios

| Servicio | Archivo | Microservicio Backend | Responsabilidad Principal |
|---|---|---|---|
| `authService` | [`src/services/authService.ts`](./src/services/authService.ts) | **Identity.API** | Autenticación institucional: inicio de sesión (`login`), registro de nuevos usuarios (`register`) y obtención de datos del usuario actual. |
| `userService` | [`src/services/userService.ts`](./src/services/userService.ts) | **Identity.API** | Administración de cuentas: listado general de usuarios, asignación/cambio de roles y suspensión preventiva de cuentas. |
| `campusService` | [`src/services/campusService.ts`](./src/services/campusService.ts) | **Campus.API** | Gestión geoespacial del campus: CRUD de edificios, pisos, salas, estructuras externas, categorías y ordenamiento interactivo de capas. |
| `incidentService` | [`src/services/incidentService.ts`](./src/services/incidentService.ts) | **Incidents.API** | Infraestructura y objetos perdidos: reporte de incidencias en campus, publicación y búsqueda de objetos extraviados, y transiciones de estado de reportes. |
| `scheduleService` | [`src/services/scheduleService.ts`](./src/services/scheduleService.ts) | **Schedule.API** | Directorio y agenda académica: consulta de docentes, creación de bloques de atención y agendamiento de reuniones estudiante-docente. |

## Archivos Relevantes del Core

Dentro del directorio `src/api/` se encuentran tres piezas fundamentales que articulan la infraestructura de comunicación de red, el manejo de errores y la sincronización de caché con los microservicios:

### 1. `src/api/apiError.ts` (Manejo y Normalización de Errores)
* **¿Qué es?**: Proporciona la clase personalizada `ApiError` (que extiende del objeto estándar `Error` de JavaScript) y la función utilitaria `toApiError`.
* **¿Para qué sirve?**:
  * **Normalización de respuestas de error**: Cuando un microservicio responde con un error HTTP o falla la conexión, `toApiError` extrae de forma segura el mensaje más descriptivo retornado por el backend (inspeccionando campos estándar de RFC 7807 / ASP.NET como `detail`, `title`, `message` o cadenas de texto planas).
  * **Mapeo declarativo por código de estado**: Permite definir diccionarios de mensajes específicos por código HTTP (`statusMessages: Record<number, string>`) y un mensaje por defecto (`fallback`) para presentar información amigable al usuario en la UI.
  * **Trazabilidad**: Asigna de forma tipada el código HTTP recibido en la propiedad `.status` y conserva el error original en `.cause`.
  * **Tipado desacoplado**: La interfaz de opciones del constructor `ApiErrorOptions` se encuentra desacoplada en [`src/interfaces/ApiErrorOptions.ts`](./src/interfaces/ApiErrorOptions.ts).

### 2. `src/api/httpClient.ts` (Cliente HTTP Centralizado)
* **¿Qué es?**: Instancia configurada (*singleton*) de **Axios** utilizada por todos los servicios (`services/*`) de la aplicación para comunicarse con el API Gateway.
* **¿Para qué sirve?**:
  * **Configuración uniforme**: Establece encabezados base (`Content-Type: application/json`), rutas relativas (`/api/...`) compatibles con el proxy Nginx/Vite, y un timeout predeterminado de 10 segundos para prevenir bloqueos de red.
  * **Inyección automática de autenticación (Request Interceptor)**: En cada petición saliente, consulta de forma reactiva el store global de Zustand (`useAuthState`). Si existe un token JWT válido, inyecta automáticamente la cabecera `Authorization: Bearer <token>`.
  * **Gestión global de sesión y errores (Response Interceptor)**: Monitorea todas las respuestas del servidor. Si un microservicio responde con un código `401 Unauthorized` (sesión expirada o token inválido), automáticamente ejecuta el cierre de sesión (`useAuthState.getState().logout()`) para redirigir al usuario al login de forma transparente. También captura advertencias para códigos 403, 404 y errores 500+.

### 3. `src/api/queryKeys.ts` (Fábrica Centralizada de Claves de Caché)
* **¿Qué es?**: Objeto estructurado que define y genera las claves de consulta (*Query Keys*) tipadas para **TanStack Query** (`@tanstack/react-query`).
* **¿Para qué sirve?**:
  * **Única fuente de verdad para la caché**: TanStack Query identifica y almacena en caché las respuestas del servidor mediante arrays de claves. `queryKeys` centraliza todas estas definiciones jerárquicas (campus, categorías, estructuras, reportes, objetos perdidos, docentes, reuniones, etc.).
  * **Eliminación de "magic strings"**: Evita errores tipográficos al invocar hooks como `useQuery`, `useMutation` o `queryClient.invalidateQueries`.
  * **Parametrización fuertemente tipada**: Proporciona funciones tipadas que aceptan identificadores (`campusId`, `buildingId`, `teacherId`) o DTOs de búsqueda (`ReportSearchParams`, `LostObjectSearchParams`), garantizando que la caché se invalide y refresque de forma exacta y determinista cuando los datos cambian.

---

## Librerías y Dependencias Utilizadas

El ecosistema del frontend se compone de dependencias cuidadosamente seleccionadas para garantizar alto rendimiento, escalabilidad, tipado estricto y una experiencia de usuario interactiva:

### Dependencias de Producción (`dependencies`)

| Librería | Versión | Propósito y Justificación |
|---|---|---|
| **`react`** y **`react-dom`** | `^19.2.8` | Biblioteca base para la interfaz de usuario, empleando arquitectura declarativa basada en componentes y el motor React 19. |
| **`react-router-dom`** | `^7.18.3` | Enrutador del lado del cliente (SPA) para gestionar navegación, parámetros de URL, rutas protegidas y guardas de seguridad por rol (`RoleGuard`). |
| **`@tanstack/react-query`** | `^5.102.8` | Gestor asíncrono de estado del servidor. Administra caché en memoria, deduplicación de peticiones, revalidación en segundo plano y mutaciones optimistas. |
| **`zustand`** | `^5.0.15` | Gestor de estado global del cliente ligero, rápido y sin boilerplate de Redux. Gestiona la sesión (`authState`), navegación activa (`navState`) y modales/notificaciones (`uiState`). |
| **`axios`** | `^1.20.0` | Cliente HTTP basado en promesas para consumir los microservicios a través del API Gateway, soportando interceptores, timeouts y serialización automática. |
| **`tailwindcss`** y **`@tailwindcss/vite`** | `^4.3.3` | Framework CSS utilitario de última generación integrado con Vite, utilizado para el diseño responsivo, temas y la paleta de colores institucional de la UCT. |
| **`mapbox-gl`** | `^3.33.0` | Motor gráfico para renderizado de mapas vectoriales interactivos, edificios en 3D, controles de cámara, marcadores de salas y mapas de calor geoespaciales. |
| **`@photo-sphere-viewer/core`** | `^5.15.1` | Visor esférico interactivo para renderizar imágenes panorámicas en 360°, permitiendo recorridos virtuales dentro de salas y oficinas de los edificios. |
| **`react-zoom-pan-pinch`** | `^4.2.0` | Componente interactivo para realizar zoom, arrastre y gestos táctiles suaves sobre los planos esquemáticos de los pisos y estructuras. |
| **`react-hook-form`** | `^7.87.0` | Manejo de formularios reactivos con mínimo re-renderizado de componentes y alta velocidad de validación. |
| **`zod`** | `^4.5.4` | Biblioteca de validación de esquemas con inferencia estática de tipos TypeScript, garantizando integridad en los datos ingresados en formularios. |
| **`@hookform/resolvers`** | `^5.9.1` | Adaptador que conecta los esquemas de validación de `zod` directamente con los formularios de `react-hook-form`. |

### Dependencias de Desarrollo y Calidad (`devDependencies`)

| Herramienta | Versión | Propósito y Justificación |
|---|---|---|
| **`vite`** | `^8.2.2` | Entorno de desarrollo local de arranque instantáneo y empaquetador para producción mediante Rollup. |
| **`typescript`** | `~6.0.2` | Compilador de TypeScript que proporciona chequeo estático de tipos, autocompletado y prevención temprana de bugs. |
| **`vitest`** | `^5.0.3` | Framework de pruebas unitarias ultrarrápido y nativo para Vite, con soporte para mocks (`vi.fn`), snapshots y temporizadores falsos. |
| **`@testing-library/react`** y **`@testing-library/jest-dom`** | `^16.3.3` / `^7.0.1` | Utilidades para testing de componentes React basadas en el comportamiento real del usuario, accesibilidad (roles, etiquetas) y aserciones extendidas del DOM. |
| **`jsdom`** | `^30.1.2` | Emulación completa del entorno DOM/HTML de navegadores dentro de Node.js para ejecutar la suite de pruebas sin requerir un navegador gráfico. |
| **`@vitest/coverage-v8`** | `^5.0.3` | Motor de cobertura de código basado en el inspector V8 para medir el porcentaje de código testeado y generar reportes en consola y formato Cobertura XML para el CI. |
| **`eslint`** y **`typescript-eslint`** | `^10.9.0` / `^8.67.0` | Linter estático para asegurar código limpio, consistente y prevenir malas prácticas en React (`eslint-plugin-react-hooks`, `eslint-plugin-react-refresh`). |
| **`vite-plugin-svgr`** | `^5.2.0` | Plugin de Vite que transforma archivos vectoriales `.svg` en componentes React listos para usar (`?react`) con soporte completo de propiedades y Tailwind. |
| **`postcss`** y **`autoprefixer`** | `^8.5.28` / `^10.5.5` | Procesadores CSS que agregan automáticamente prefijos de compatibilidad para navegadores. |

---

## Construcción de la Imagen 

El proceso del archivo `Dockerfile` del frontend se divide en dos fases:

1. **Fase de Compilación:**
   Utiliza una imagen base de Node.js como entorno de construcción. En esta etapa se instalan todas las dependencias y se ejecuta el compilador de Vite. El resultado es una carpeta que contiene únicamente los recursos estáticos optimizados.
2. **Fase de Producción:**
   Inicia un entorno completamente nuevo basado en Nginx (`nginx:alpine`). Se copia el archivo de configuración `nginx.conf` y se trasladan **únicamente los archivos compilados** de la fase anterior. El entorno de Node.js y el código fuente original son descartados, evitando problmeas de seguridad.

## CI Pipeline

El frontend cuenta con un pipeline automatizado en ([`.github/workflows/frontend-ci.yml`](../../.github/workflows/frontend-ci.yml)).

### Disparadores del Pipeline 
El workflow se ejecuta automáticamente ante:
* **Push** y **Pull Requests** hacia las ramas `main` y `taller-2`.
* **Filtro de rutas** solo se dispara si existen modificaciones en `src/frontend/**` o en el propio archivo del workflow.

### Fases del Pipeline

| Paso | Propósito |
|---|---|
| **1. Setup Node.js** | Configura el entorno con Node.js 20.x y habilita caché de dependencias con `npm`. |
| **2. Dependencias** | Instalación estricta y limpia de paquetes basada en `package-lock.json`. |
| **3. Calidad de Código** | Ejecuta **ESLint** para auditar sintaxis, buenas prácticas de React y TypeScript. |
| **4. Tests & Coverage** | Ejecuta la suite de pruebas unitarias con **Vitest** en un DOM simulado (`jsdom`) y genera el informe de cobertura en XML Cobertura. |
| **5. Typecheck & Build** | Valida los tipos con el compilador de TypeScript (`tsc -b`) y empaqueta el frontend con Vite para verificar que la build de producción sea válida. |
| **6. Resumen de Cobertura** | Lee el archivo `cobertura-coverage.xml` e inyecta la tabla resumen de cobertura con indicadores visuales en el Job Summary de GitHub. |

### Comandos 

Para ejecutar las verificaciones en el entorno de desarrollo local:

```bash
# Desde la raíz del proyecto: validar tests, build y construcción de Docker
make validate-frontend
# # Auditar calidad de código y buenas prácticas 
npm run lint
# Ejecutar la suite de pruebas unitarias
npm test
# Ejecutar pruebas y desplegar la tabla completa de cobertura en consola
npm run coverage
# Validar tests y compilación del frontend
npm run validate
```

### Arquitectura y Convención de Tests

* **Ubicación (Co-location):** Los archivos de prueba tienen la extensión `.test.ts` o `.test.tsx` y se ubican en la misma carpeta del componente o hook correspondiente (ej. `Avatar.tsx` -> `Avatar.test.tsx`).
* **Entorno:** Utiliza **Vitest** junto con **JSDOM** (`jsdom`) para emular el navegador y `@testing-library/react` para validar comportamiento y accesibilidad.
* **Alcance:** Solo se testea código con lógica ejecutable (componentes, hooks, utilitarios, servicios). Las definiciones de tipos (`interfaces/`) no requieren archivos de test.
* **Infraestructura de Testing (`src/test/`):**
  El directorio `src/test/` alberga la infraestructura base compartida por toda la suite de pruebas:
  * **`src/test/setup.ts`**: Archivo de arranque global referenciado en `vite.config.ts` (`setupFiles`). Registra las aserciones extendidas del DOM (`@testing-library/jest-dom/vitest`) y ejecuta `cleanup()` automáticamente tras cada prueba (`afterEach`) para desmontar componentes y resetear el DOM virtual, garantizando aislamiento estricto entre pruebas.
  * **`src/test/renderWithQueryClient.tsx`**: Función utilitaria de renderizado imprescindible para cualquier componente o vista que consuma datos del servidor mediante **TanStack Query** (`useQuery`, `useMutation`). Instancia un `QueryClient` de prueba configurado específicamente para tests (`retry: false` para fallar inmediatamente sin demoras y `gcTime: 0` para no retener caché entre ejecuciones) y envuelve el componente en un `<QueryClientProvider>`, previniendo el error `"No QueryClient set"`. Retorna la instancia de `queryClient` y todos los métodos de consulta de `@testing-library/react`.
