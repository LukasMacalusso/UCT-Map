# Campus API Documentation

**Base URL**: `/api/campus`

Handles the university's geographic and physical infrastructure, including campuses, buildings, structures (outdoor/standalone amenities), rooms, and categories.

---

## Global Authentication
- **Mechanism**: JWT (JSON Web Token), validated by the API Gateway.
- **Header Format**: `Authorization: Bearer <token>`
- **Note**: Unless explicitly marked as `[Public]`, all endpoints require a valid JWT.

## Conventions
- Geographic coordinates use the Value Object `Coordinate` composed of `latitude` and `longitude` (`double precision`).
- Empty GUID queries return `400 Bad Request`.
- Handled errors return `{ "message": "..." }` or RFC 7807 Problem Details.

---

## Table of Contents
1. [Campuses](#1-campuses)
2. [Buildings](#2-buildings)
3. [Structures](#3-structures)
4. [Rooms](#4-rooms)
5. [Categories](#5-categories)

---

## 1. Campuses
*Represents an entire university campus campus/venue.*

### 1.1 Get All Campuses
- **Route**: `GET /api/campus/campuses`
- **Access**: Any authenticated user
- **Description**: Returns a list of all registered campuses.

**Success Response (200 OK)**
```json
[
  {
    "id": "uuid",
    "name": "Campus San Juan Pablo II",
    "address": "Rudecindo Ortega 02950",
    "latitude": -38.7065,
    "longitude": -72.5855
  }
]
```

---

### 1.2 Get Campus By Id
- **Route**: `GET /api/campus/campuses/{id}`
- **Access**: Any authenticated user
- **Description**: Returns details of a specific campus.

**Success Response (200 OK)**: same object as in 1.1.

**Error Responses**
- **`404 Not Found`**: Campus not found.

---

### 1.3 Create Campus
- **Route**: `POST /api/campus/campuses`
- **Access**: `ADMIN`
- **Description**: Creates a new campus.

**Request Payload (`application/json`)**
```json
{
  "name": "Campus Norte",
  "address": "Av. Ejemplo 123",
  "latitude": -38.7000,
  "longitude": -72.5800
}
```

**Success Response (201 Created)**: same object as in 1.1.

**Error Responses**
- **`400 Bad Request`**: If name is missing or empty.

---

### 1.4 Update Campus
- **Route**: `PUT /api/campus/campuses/{id}`
- **Access**: `ADMIN`
- **Description**: Updates campus information.

**Request Payload (`application/json`)**: same payload as in 1.3.

**Success Response (204 No Content)**

---

### 1.5 Update Campus Location (Move Marker)
- **Route**: `PATCH /api/campus/campuses/{id}/location`
- **Access**: `ADMIN`
- **Description**: Updates only the latitude and longitude coordinates of the campus marker.

**Request Payload (`application/json`)**
```json
{
  "latitude": -38.7050,
  "longitude": -72.5840
}
```

**Success Response (204 No Content)**

**Error Responses**
- **`404 Not Found`**: Campus not found.

---

### 1.6 Delete Campus
- **Route**: `DELETE /api/campus/campuses/{id}`
- **Access**: `ADMIN`
- **Description**: Removes a campus.

**Success Response (204 No Content)**

---

## 2. Buildings
*Represents buildings inside a university campus, including their floor count, schedules, and services.*

### 2.1 Get All Buildings
- **Route**: `GET /api/campus/buildings`
- **Access**: Any authenticated user
- **Description**: Returns all buildings, optionally filtered by `campusId`.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `campusId` | `uuid` | No | — | Filter buildings belonging to this campus. |

**Success Response (200 OK)**
```json
[
  {
    "id": "uuid",
    "campusId": "uuid",
    "name": "Edificio C",
    "floorsCount": 4,
    "latitude": -38.7061,
    "longitude": -72.5852,
    "schedule": "08:00 - 18:00",
    "services": ["WIFI", "BAÑOS", "ELEVADOR"]
  }
]
```

---

### 2.2 Get Building Map Locations
- **Route**: `GET /api/campus/buildings/locations`
- **Access**: Any authenticated user
- **Description**: Lightweight endpoint designed specifically for the interactive map UI.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `campusId` | `uuid` | No | — | Filter buildings belonging to this campus. |

**Success Response (200 OK)**
```json
[
  {
    "id": "uuid",
    "name": "Edificio C",
    "location": {
      "latitude": -38.7061,
      "longitude": -72.5852
    },
    "metadata": {
      "campusId": "uuid",
      "floorsCount": 4,
      "schedule": "08:00 - 18:00",
      "services": ["WIFI", "BAÑOS"]
    }
  }
]
```

---

### 2.3 Get Building By Id
- **Route**: `GET /api/campus/buildings/{id}`
- **Access**: Any authenticated user
- **Description**: Returns building details.

**Success Response (200 OK)**: same object as in 2.1.

---

### 2.4 Create Building
- **Route**: `POST /api/campus/buildings`
- **Access**: `ADMIN`
- **Description**: Creates a new building in a campus.

**Request Payload (`application/json`)**
```json
{
  "campusId": "uuid",
  "name": "Edificio C",
  "floorsCount": 4,
  "latitude": -38.7061,
  "longitude": -72.5852,
  "schedule": "08:00 - 18:00",
  "services": ["WIFI", "BAÑOS"]
}
```

**Success Response (201 Created)**: same object as in 2.1.

---

### 2.5 Update Building
- **Route**: `PUT /api/campus/buildings/{id}`
- **Access**: `ADMIN`
- **Description**: Updates all building information.

**Request Payload (`application/json`)**: same payload as in 2.4.

**Success Response (204 No Content)**

---

### 2.6 Update Building Location (Move Marker)
- **Route**: `PATCH /api/campus/buildings/{id}/location`
- **Access**: `ADMIN`
- **Description**: Updates only the latitude and longitude coordinates of the building marker on the map.

**Request Payload (`application/json`)**
```json
{
  "latitude": -38.7063,
  "longitude": -72.5850
}
```

**Success Response (204 No Content)**

**Error Responses**
- **`404 Not Found`**: Building not found.

---

### 2.7 Delete Building
- **Route**: `DELETE /api/campus/buildings/{id}`
- **Access**: `ADMIN`
- **Description**: Deletes a building.

**Success Response (204 No Content)**

---

## 3. Structures
*Represents outdoor or standalone university structures (e.g., parking lots, sports fields, ruka, gazebos).*

### 3.1 Get All Structures
- **Route**: `GET /api/campus/structures`
- **Access**: Any authenticated user
- **Description**: Returns structures, optionally filtered by `campusId` or `categoryId`.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `campusId` | `uuid` | No | — | Filter structures by campus. |
| `categoryId`| `uuid` | No | — | Filter structures by category. |

**Success Response (200 OK)**
```json
[
  {
    "id": "uuid",
    "campusId": "uuid",
    "categoryId": "uuid",
    "name": "Estacionamiento Poniente",
    "latitude": -38.7070,
    "longitude": -72.5860
  }
]
```

---

### 3.2 Get Structure Map Locations
- **Route**: `GET /api/campus/structures/locations`
- **Access**: Any authenticated user
- **Description**: Returns structure coordinates and metadata formatted for the map.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `campusId` | `uuid` | No | — | Filter structures by campus. |

**Success Response (200 OK)**
```json
[
  {
    "id": "uuid",
    "name": "Estacionamiento Poniente",
    "location": {
      "latitude": -38.7070,
      "longitude": -72.5860
    },
    "metadata": {
      "campusId": "uuid",
      "categoryId": "uuid",
      "categoryName": "Estacionamiento"
    }
  }
]
```

---

### 3.3 Get Structure By Id
- **Route**: `GET /api/campus/structures/{id}`
- **Access**: Any authenticated user

**Success Response (200 OK)**: same object as in 3.1.

---

### 3.4 Create Structure
- **Route**: `POST /api/campus/structures`
- **Access**: `ADMIN`
- **Description**: Creates a new structure.

**Request Payload (`application/json`)**
```json
{
  "campusId": "uuid",
  "categoryId": "uuid",
  "name": "Ruka Intercultural",
  "latitude": -38.7072,
  "longitude": -72.5865
}
```

**Success Response (201 Created)**: same object as in 3.1.

---

### 3.5 Update Structure
- **Route**: `PUT /api/campus/structures/{id}`
- **Access**: `ADMIN`

**Request Payload (`application/json`)**: same payload as in 3.4.

**Success Response (204 No Content)**

---

### 3.6 Update Structure Location (Move Marker)
- **Route**: `PATCH /api/campus/structures/{id}/location`
- **Access**: `ADMIN`
- **Description**: Updates only the latitude and longitude coordinates of the structure marker on the map.

**Request Payload (`application/json`)**
```json
{
  "latitude": -38.7075,
  "longitude": -72.5862
}
```

**Success Response (204 No Content)**

**Error Responses**
- **`404 Not Found`**: Structure not found.

---

### 3.7 Delete Structure
- **Route**: `DELETE /api/campus/structures/{id}`
- **Access**: `ADMIN`

**Success Response (204 No Content)**

---

## 4. Rooms
*Represents rooms and interior spaces located within buildings.*

### 4.1 Get All Rooms
- **Route**: `GET /api/campus/rooms`
- **Access**: Any authenticated user
- **Description**: Returns rooms, optionally filtered by `buildingId` or `categoryId`.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `buildingId` | `uuid` | No | — | Filter by parent building. |
| `categoryId` | `uuid` | No | — | Filter by room category. |

**Success Response (200 OK)**
```json
[
  {
    "id": "uuid",
    "buildingId": "uuid",
    "categoryId": "uuid",
    "name": "Laboratorio 301",
    "code": "LAB-301",
    "floorNumber": 3,
    "capacity": 35
  }
]
```

---

### 4.2 Search Rooms
- **Route**: `GET /api/campus/rooms/search`
- **Access**: Any authenticated user
- **Description**: Searches rooms matching the given search term (by name or code).

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `term` | `string` | Yes | — | Search keyword. |

**Success Response (200 OK)**: array of rooms as in 4.1.

---

### 4.3 Get Rooms By Building
- **Route**: `GET /api/campus/buildings/{buildingId}/rooms`
- **Access**: Any authenticated user
- **Description**: Returns all rooms belonging to a specific building.

**Success Response (200 OK)**: array of rooms as in 4.1.

---

### 4.4 Get Room By Id
- **Route**: `GET /api/campus/rooms/{id}`
- **Access**: Any authenticated user

**Success Response (200 OK)**: single room object as in 4.1.

---

### 4.5 Create Room
- **Route**: `POST /api/campus/rooms`
- **Access**: `ADMIN`

**Request Payload (`application/json`)**
```json
{
  "buildingId": "uuid",
  "categoryId": "uuid",
  "name": "Sala 204",
  "code": "A-204",
  "floorNumber": 2,
  "capacity": 40
}
```

**Success Response (201 Created)**

---

### 4.6 Update Room
- **Route**: `PUT /api/campus/rooms/{id}`
- **Access**: `ADMIN`

**Success Response (204 No Content)**

---

### 4.7 Delete Room
- **Route**: `DELETE /api/campus/rooms/{id}`
- **Access**: `ADMIN`

**Success Response (204 No Content)**

---

## 5. Categories
*Categories for classifying structures and rooms (e.g. Laboratory, Classroom, Restroom, Parking).*

### 5.1 Get All Categories
- **Route**: `GET /api/campus/categories`
- **Access**: Any authenticated user

**Success Response (200 OK)**
```json
[
  {
    "id": "uuid",
    "name": "Laboratorio",
    "icon": "flask",
    "description": "Espacios destinados a la investigación y prácticas"
  }
]
```

---

### 5.2 Get Category By Id
- **Route**: `GET /api/campus/categories/{id}`
- **Access**: Any authenticated user

**Success Response (200 OK)**: single category object as in 5.1.

---

### 5.3 Create Category
- **Route**: `POST /api/campus/categories`
- **Access**: `ADMIN`

**Request Payload (`application/json`)**
```json
{
  "name": "Área Verde",
  "icon": "tree",
  "description": "Espacios al aire libre y jardines"
}
```

**Success Response (201 Created)**

---

### 5.4 Update Category
- **Route**: `PUT /api/campus/categories/{id}`
- **Access**: `ADMIN`

**Success Response (204 No Content)**

---

### 5.5 Delete Category
- **Route**: `DELETE /api/campus/categories/{id}`
- **Access**: `ADMIN`

**Success Response (204 No Content)**
