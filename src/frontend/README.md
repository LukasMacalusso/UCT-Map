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
| `admin` | `UserManagementCard` | Tarjeta para la gestión administrativa de usuarios, roles y baneos. | `user`, `roles`, `onRoleChange`, `onToggleBan` |
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

## Interfaz Role-Based

Con la gestión de interfaces basadas en roles se permite añadir nuevas funcionalidades específicas de manera limpia:

1. **Para componentes de UI:**
   Se utiliza el componente `<RoleGuard>`. Si se desea que solo ciertos roles vean una funcionalidad, simplemente se envuelve el código:
   ```tsx
   <RoleGuard allowedRoles={['INCIDENTS_OFFICER', 'ADMIN']}>
     <IncidentManagerPanel />
   </RoleGuard>
   ```
   Si el usuario no tiene los permisos, React ignora el componente por completo.

2. **Para Vistas y Páginas Completas:**
   La navegación y enrutamiento se protegen con `<ProtectedRoute>` en el `AppRouter`:
   ```tsx
   <Route path="settings" element={
     <ProtectedRoute allowedRoles={['ADMIN', 'TEACHER']}>
       <SettingsView />
     </ProtectedRoute>
   } />
   ```
Si se desea llevar al usuario a una ruta específica si no cuenta con autorización, se puede modificar con `unauthorizedTo` (por default, lleva a `/map`):

```tsx
<Route element="{<ProtectedRoute" unauthorizedTo="/login"/>}>
  <Route element="{<ContactsView" path="/contacts"/>} />
</Route>
```
   El enrutador maneja la seguridad automáticamente e intercepta a los usuarios no autorizados.

3. **Para Lógica Interna:**
   Cualquier parte del código puede acceder instantáneamente a la sesión mediante el store global Zustand (`useAuthState`):
   ```tsx
   const user = useAuthState(state => state.user);
   if (user?.role === 'MEMBER') { /* lógica específica */ }
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
# Auditar calidad de código y buenas prácticas 
npm run lint

# Ejecutar la suite de pruebas unitarias
npm test

# Ejecutar pruebas y desplegar la tabla completa de cobertura en consola
npm run coverage

# Validar tests y compilación del frontend
npm run validate

# Desde la raíz del proyecto: validar tests, build y construcción de Docker
make validate-frontend
```

### Arquitectura y Convención de Tests

* **Ubicación (Co-location):** Los archivos de prueba tienen la extensión `.test.ts` o `.test.tsx` y se ubican en la misma carpeta del componente o hook correspondiente (ej. `Avatar.tsx` -> `Avatar.test.tsx`).
* **Entorno:** Utiliza **Vitest** junto con **JSDOM** (`jsdom`) para emular el navegador y `@testing-library/react` para validar comportamiento y accesibilidad.
* **Alcance:** Solo se testea código con lógica ejecutable (componentes, hooks, utilitarios, servicios). Las definiciones de tipos (`interfaces/`) no requieren archivos de test.
