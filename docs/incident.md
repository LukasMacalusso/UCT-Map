# Incident API Documentation

**Base URL**: `/api/incident`

Handles the reporting and tracking of campus incidents and complaints, together with the registry of lost objects. Every report is persisted as a **Ticket**, which may optionally reference a previously reported lost object or embed complaint details.

---

## Global Authentication
- **Mechanism**: JWT (JSON Web Token), validated by the API Gateway.
- **Header Format**: `Authorization: Bearer <token>`
- **Note**: Unless explicitly marked as `[Public]`, all endpoints require a valid JWT. No endpoint is restricted to a specific role. When creating a report, the author is taken from the token's `sub` claim, so any `userRefId` sent in the body is ignored.

## Conventions
- References to other microservices are plain ids: `userRefId` (Identity) and `structureRefId` (Campus). Lost objects are referenced by their MongoDB `id` (`lostObjectId`).
- Dates use ISO 8601 with UTC designator: `2026-10-05T10:30:00Z`.
- Enums travel as integers in both requests and responses (no string converter is registered). See the tables below.
- Handled errors return RFC 7807 Problem Details, e.g. `{ "title": "Structure ID is required." }`.

**`ticketType` / report status (`Tickets`)**
| Value | Name |
| :--- | :--- |
| `0` | `Pending` |
| `1` | `In_Process` |
| `2` | `Resolved` |
| `3` | `Dismissed` |

**Lost object status (`Objectenum`)**
| Value | Name |
| :--- | :--- |
| `0` | `Pending` |
| `1` | `In_Process` |
| `2` | `Resolved` |
| `3` | `Canceled` |

**Complaint status (`Complainenum`)**
| Value | Name |
| :--- | :--- |
| `0` | `Claim` |
| `1` | `Found` |
| `2` | `Match` |
| `3` | `Pickup` |

---

## Table of Contents
1. [Reports](#1-reports)
2. [Lost Objects](#2-lost-objects)
3. [Health](#3-health)
4. [End-to-End Test Walkthrough](#4-end-to-end-test-walkthrough)

---

## 1. Reports
*A report (or ticket) submitted by a user about a structure, optionally tied to a lost object or carrying complaint details.*

> **Filtering/search** is served by the search endpoint: `GET /api/incident/reports?{filters}` (see [1.4](#14-search-reports)). There is no dedicated status-filter route.

### 1.1 Create Report
- **Route**: `POST /api/incident/reports`
- **Access**: Any authenticated user
- **Description**: Creates a ticket. The author is resolved from the JWT `sub` claim; the `userRefId` field in the body is ignored and overwritten. If `lostObjectId` is provided, the referenced lost object must already exist.

**Request Payload (`application/json`)**
```json
{
  "userRefId": "uuid",                  // Ignored: replaced by the authenticated user from the JWT
  "structureRefId": "uuid",             // Required
  "ticketType": 1,                      // Required, 0 = Pending ... 3 = Dismissed
  "isActive": true,                     // Required
  "reportedAt": "2026-10-05T10:30:00Z", // Required
  "lostObjectId": "string",             // Optional, MongoDB id of an existing lost object
  "complaint": {                        // Optional embedded complaint
    "title": "string",
    "description": "string",
    "status": 0                         // 0 = Claim ... 3 = Pickup
  }
}
```

**Success Response (201 Created)**
```json
{ "id": "string" }
```
The `Location` header points to 1.2.

**Error Responses**
- **`401 Unauthorized`**: The `Authorization` header is missing, malformed, or its `sub` claim is not a valid user id.
- **`400 Bad Request`**: If `structureRefId` is an empty uuid, `ticketType` is not a defined value, or the referenced lost object does not exist.

---

### 1.2 Get Report By Id
- **Route**: `GET /api/incident/reports/{id}`
- **Access**: Any authenticated user
- **Description**: Returns a single ticket by its MongoDB id.

**Success Response (200 OK)**
```json
{
  "id": "string",
  "userRefId": "uuid",
  "structureRefId": "uuid | null",
  "ticketType": 1,
  "isActive": true,
  "reportedAt": "2026-10-05T10:30:00Z",
  "complaintDetails": {
    "title": "string",
    "description": "string",
    "status": 0
  },
  "lostObjectId": "string | null"
}
```

**Error Responses**
- **`404 Not Found`**: If no ticket exists with that id.
- **`400 Bad Request`**: For any other handled error.

---

### 1.3 Update Report Status
- **Route**: `PATCH /api/incident/reports/{id}/report/status`
- **Access**: Any authenticated user
- **Description**: Updates the ticket status and, when the ticket has complaint details, the complaint status as well.

**Request Payload (`application/json`)**
```json
{
  "status": 2,          // Required, 0 = Pending ... 3 = Dismissed
  "complainStatus": 1   // Optional, 0 = Claim ... 3 = Pickup
}
```

**Success Response (204 No Content)**

**Error Responses**
- **`400 Bad Request`**: If `status` (or `complainStatus`) is not a defined value, or if the update does not modify the stored document (e.g. sending the status it already has).
- **`404 Not Found`**: If no ticket exists with that id.

---

### 1.4 Search Reports
- **Route**: `GET /api/incident/reports`
- **Access**: Any authenticated user
- **Description**: Advanced, paged search over tickets. **All query parameters are optional** and, when several are sent, they are combined with `AND`; omitted parameters are simply ignored. The user taken from the JWT is **not** applied automatically — send `userRefId` explicitly to scope the results to a given user. Results are sorted and paginated server side.

**Query Parameters**

| Name | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `userRefId` | `uuid` | — | Exact match with the report author. |
| `structureRefId` | `uuid` | — | Exact match with the structure. |
| `type` | `int` | — | Ticket status: `0` Pending, `1` In_Process, `2` Resolved, `3` Dismissed. Out of range → `400`. |
| `isActive` | `bool` | — | `true` / `false`. |
| `lostObjectId` | `string` | — | Trimmed; blank values are ignored. |
| `location.coordinates` | `double` (×2) | — | Exact match of the `[longitude, latitude]` pair (no geospatial/radius search). Send the array as two repetitions of the key: `location.coordinates=-71.23&location.coordinates=-33.04`. |
| `complaintDetails.title` | `string` | — | Case-insensitive, partial (substring) match, regex characters are escaped. |
| `complaintDetails.description` | `string` | — | Case-insensitive, partial (substring) match. |
| `complaintDetails.status` | `int` | — | `0` Claim, `1` Found, `2` Match, `3` Pickup. Out of range → `400`. |
| `sortBy` | `enum` | `ReportedAt` | `ReportedAt` or `Status`. |
| `descending` | `bool` | `true` | Sort direction. |
| `page` | `int` | `1` | Values `< 1` are clamped to `1`. |
| `pageSize` | `int` | `10` | Clamped to the range `1..10`. |

> `location` matches on exact `[longitude, latitude]` equality — there is no radius/geo query. Tickets created through `POST /reports` do not store a location, so this filter only hits tickets that already have one.

**Example**
```
GET /api/incident/reports?userRefId=11111111-1111-1111-1111-111111111111&type=0&isActive=true&complaintDetails.title=fuga&sortBy=ReportedAt&descending=true&page=1&pageSize=5
```

**Success Response (200 OK)**
```json
{
  "items": [
    {
      "id": "68f1c2...",
      "userRefId": "11111111-1111-1111-1111-111111111111",
      "structureRefId": "11111111-1111-1111-1111-111111111111",
      "ticketType": 0,
      "isActive": true,
      "reportedAt": "2026-10-16T10:30:00Z",
      "complaintDetails": {
        "title": "Fuga de agua",
        "description": "Baño del 2do piso",
        "status": 0
      },
      "lostObjectId": "68f1c3..."
    }
  ],
  "totalCount": 1,
  "page": 1,
  "pageSize": 5,
  "totalPages": 1
}
```
A query without matches returns `200 OK` with `"items": []` and `"totalCount": 0` (it is **not** a `404`). `totalPages` is computed as `ceil(totalCount / pageSize)`.

**Error Responses**
- **`401 Unauthorized`**: The `Authorization` header is missing or invalid (enforced by the API Gateway).
- **`400 Bad Request`**: If `type` is not a defined ticket status (`Invalid type '99'.`), if `complaintDetails.status` is not a defined complaint status (`Invalid complaint status '99'.`), or if a parameter cannot be parsed (e.g. a non-numeric `page` or an unknown `sortBy` value).

---

## 2. Lost Objects
*Registry of items reported lost on campus, each associated with a structure.*

> **Filtering by status** is served by the search endpoint: `GET /api/incident/lost-objects?status={0..3}` (see [4.10](#410-additional-queries)).

### 2.1 Create Lost Object
- **Route**: `POST /api/incident/lost-objects`
- **Access**: Any authenticated user
- **Description**: Registers a lost object. The `status` is stored as received; no enum validation is applied on creation.

**Request Payload (`application/json`)**
```json
{
  "title": "Mochila negra",             // Required
  "description": "Con un notebook",     // Required
  "status": 0,                          // 0 = Pending ... 3 = Canceled
  "photoUrl": "https://example.com/f",  // Optional, must be an absolute http/https URL
  "structureId": "uuid"                 // Required
}
```

**Success Response (201 Created)**
```json
{ "id": "string" }
```
The `Location` header points to 2.2.

**Error Responses**
- **`400 Bad Request`**: If `photoUrl` is not an absolute `http`/`https` URL, or `structureId` is an empty uuid.

---

### 2.2 Get Lost Object By Id
- **Route**: `GET /api/incident/lost-objects/{id}`
- **Access**: Any authenticated user
- **Description**: Looks up a lost object by its MongoDB id.

**Success Response**: currently `204 No Content`.

**Error Responses**
- **`404 Not Found`**: If no lost object exists with that id.
- **`400 Bad Request`**: For any other handled error.

> The response payload returned by the lookup is not exposed yet; the endpoint currently answers with an empty body.

---

### 2.3 Update Lost Object Status
- **Route**: `PATCH /api/incident/lost-objects/{id}/lost/status`
- **Access**: Any authenticated user
- **Description**: Updates the status of a lost object.

**Request Payload (`application/json`)**
```json
{
  "status": 2 // Required, 0 = Pending ... 3 = Canceled
}
```

**Success Response (204 No Content)**

**Error Responses**
- **`400 Bad Request`**: If `status` is not a defined value.
- **`404 Not Found`**: If no lost object exists with that id.

---

## 3. Health
*Internal endpoints for container health checks. They are not exposed through the API Gateway.*

### 3.1 Service Health `[Public]`
- **Route**: `GET /health`
- **Description**: Returns `200 OK` with `{ "service": "incident-service", "status": "healthy" }`.

### 3.2 Readiness / Database Health `[Public]`
- **Route**: `GET /health/ready`
- **Description**: Pings MongoDB. Returns `200 OK` with `{ "service": "incident-service", "status": "ready", "database": "connected" }`, or `503 Service Unavailable` with `{ "service": "incident-service", "status": "unhealthy", "database": "disconnected" }` when the database cannot be reached.

----------------------------------------------------------------------------------------------------------------------------------------------------------------

## 4. End-to-End Test Walkthrough
*Full happy path to verify the Incident service: register a user, log in, create a lost object, create a report that references it, then read, update and search both. Every request goes through the API Gateway so the JWT is validated end to end.*

### 4.0 Prerequisites
Start the whole stack from the repository root:

```bash
docker compose up --build
# or
make up
```

All requests below target the **API Gateway** (`http://localhost:5000`):

| Service | Direct URL | Through the Gateway |
| :--- | :--- | :--- |
| Gateway | — | `http://localhost:5000` |
| Identity | `http://localhost:5001` | `http://localhost:5000/api/identity/...` |
| Campus | `http://localhost:5002` | `http://localhost:5000/api/campus/...` |
| **Incident** | `http://localhost:5003` | `http://localhost:5000/api/incident/...` |
| Schedule | `http://localhost:5004` | `http://localhost:5000/api/schedule/...` |

> Always use the Gateway (`:5000`). The `/api/incident/*` route is protected by the gateway's default authorization policy, so it **requires** the `Authorization: Bearer <token>` header even for endpoints that do not read the token themselves.

---

### 4.1 Register a user
- **Route**: `POST http://localhost:5000/api/identity/register`
- **Access**: Public

**Request Payload (`application/json`)**
```json
{
  "name": "Ana Torres",
  "email": "ana.prueba@uct.cl",
  "password": "Password123!",
  "role": "Student"
}
```

**Success Response (201 Created)**
```json
{
  "userId": "string",
  "name": "Ana Torres",
  "email": "ana.prueba@uct.cl",
  "role": "Student"
}
```

`role` is optional and defaults to `Student`. Keep the `userId` for later steps.

---

### 4.2 Log in and capture the JWT
- **Route**: `POST http://localhost:5000/api/identity/login`
- **Access**: Public

**Request Payload (`application/json`)**
```json
{
  "email": "ana.prueba@uct.cl",
  "password": "Password123!"
}
```

**Success Response (200 OK)**
```json
{
  "userId": "string",
  "email": "ana.prueba@uct.cl",
  "token": "eyJhbGciOi..."
}
```

Send the returned `token` as `Authorization: Bearer <token>` on every Incident request.

---

### 4.3 (Optional) Obtain a `structureId`
The Incident service only validates that the GUID is **not empty**; it does not query Campus. You can use any non-empty UUID (e.g. `11111111-1111-1111-1111-111111111111`) or fetch a real one:

- **Route**: `GET http://localhost:5000/api/campus/structures` with `Authorization: Bearer <token>`

---

### 4.4 Create a lost object
- **Route**: `POST http://localhost:5000/api/incident/lost-objects`
- **Access**: Any authenticated user

**Headers**: `Authorization: Bearer <token>`

**Request Payload (`application/json`)**
```json
{
  "title": "Mochila negra",
  "description": "Con un notebook dentro",
  "status": 0,
  "photoUrl": "https://example.com/foto.jpg",
  "structureId": "11111111-1111-1111-1111-111111111111"
}
```

**Success Response (201 Created)**
```json
{ "id": "68f1c2..." }
```

Save this `id` as `LOST_ID`; the `Location` header points to 2.2. `photoUrl` is optional but, when present, must be an absolute `http`/`https` URL. `status`: `0` Pending, `1` In_Process, `2` Resolved, `3` Canceled.

---

### 4.5 Create a report (ticket) referencing the lost object
- **Route**: `POST http://localhost:5000/api/incident/reports`
- **Access**: Any authenticated user

**Headers**: `Authorization: Bearer <token>`

**Request Payload (`application/json`)**
```json
{
  "structureRefId": "11111111-1111-1111-1111-111111111111",
  "ticketType": 0,
  "isActive": true,
  "reportedAt": "2026-10-16T10:30:00Z",
  "lostObjectId": "LOST_ID",
  "complaint": {
    "title": "Fuga de agua",
    "description": "Baño del 2do piso",
    "status": 0
  }
}
```

**Success Response (201 Created)**
```json
{ "id": "REPORT_ID" }
```

Notes:
- Do **not** send `userRefId`: it is taken from the JWT `sub` claim. A missing or invalid `sub` yields `401 Unauthorized`.
- `lostObjectId` must reference an existing lost object, otherwise the request returns `400 Bad Request`.
- `ticketType`: `0` Pending, `1` In_Process, `2` Resolved, `3` Dismissed. `complaint` is optional (`status`: `0` Claim, `1` Found, `2` Match, `3` Pickup).

---

### 4.6 Get the report by id
- **Route**: `GET http://localhost:5000/api/incident/reports/REPORT_ID`
- **Headers**: `Authorization: Bearer <token>`

**Success Response (200 OK)**
```json
{
  "id": "REPORT_ID",
  "userRefId": "string",
  "structureRefId": "11111111-1111-1111-1111-111111111111",
  "ticketType": 0,
  "isActive": true,
  "reportedAt": "2026-10-16T10:30:00Z",
  "complaintDetails": { "title": "Fuga de agua", "description": "Baño del 2do piso", "status": 0 },
  "lostObjectId": "LOST_ID"
}
```

---

### 4.7 Update the report status
- **Route**: `PATCH http://localhost:5000/api/incident/reports/REPORT_ID/report/status`
- **Headers**: `Authorization: Bearer <token>`

**Request Payload (`application/json`)**
```json
{ "status": 1, "complainStatus": 1 }
```

**Success Response (204 No Content)**

Sending the status the ticket already has returns `400 Bad Request`.

---

### 4.8 Update the lost object status
- **Route**: `PATCH http://localhost:5000/api/incident/lost-objects/LOST_ID/lost/status`
- **Headers**: `Authorization: Bearer <token>`

**Request Payload (`application/json`)**
```json
{ "status": 1 }
```

**Success Response (204 No Content)**

---

### 4.9 Search reports (advanced query)
- **Route**: `GET http://localhost:5000/api/incident/reports`
- **Access**: Any authenticated user

**Headers**: `Authorization: Bearer <token>`

Every parameter is optional and several filters can be combined (`AND`). Use the `USER_ID` captured in [4.1](#41-register-a-user) to scope the search to the user who registered the report.

**Example Request**
```
GET http://localhost:5000/api/incident/reports?userRefId=USER_ID&type=0&isActive=true&complaintDetails.title=fuga&sortBy=ReportedAt&descending=true&page=1&pageSize=5
```

**Success Response (200 OK)**
```json
{
  "items": [
    {
      "id": "REPORT_ID",
      "userRefId": "USER_ID",
      "structureRefId": "11111111-1111-1111-1111-111111111111",
      "ticketType": 0,
      "isActive": true,
      "reportedAt": "2026-10-16T10:30:00Z",
      "complaintDetails": { "title": "Fuga de agua", "description": "Baño del 2do piso", "status": 0 },
      "lostObjectId": "LOST_ID"
    }
  ],
  "totalCount": 1,
  "page": 1,
  "pageSize": 5,
  "totalPages": 1
}
```

Notes:
- Supported filters: `userRefId`, `structureRefId`, `type`, `isActive`, `lostObjectId`, `location.coordinates`, `complaintDetails.title`, `complaintDetails.description`, `complaintDetails.status`. Full table in [1.4](#14-search-reports).
- `complaintDetails.title` / `complaintDetails.description` match partially and case-insensitively (`fuga` matches `Fuga de agua`).
- Sorting: `sortBy=ReportedAt` (default) or `sortBy=Status`; direction with `descending=true` (default) / `false`.
- Paging: `page` starts at `1`, `pageSize` is clamped to `1..10`. No matches → `200 OK` with `"items": []` and `"totalCount": 0`.

**Error Responses**
- **`400 Bad Request`**: `type=99` → `Invalid type '99'.`; `complaintDetails.status=99` → `Invalid complaint status '99'.`; unparsable values (e.g. `page=abc`, `sortBy=Whatever`) are rejected by model binding.
- **`401 Unauthorized`**: Missing/invalid `Authorization` header (enforced by the Gateway).

---

### 4.10 Additional queries
- **Search reports**: `GET http://localhost:5000/api/incident/reports?type=0&page=1&pageSize=10` → `{ "items": [...], "totalCount": 1, "page": 1, "pageSize": 10, "totalPages": 1 }`.
- **Search lost objects**: `GET http://localhost:5000/api/incident/lost-objects?title=Mochila&status=0&page=1&pageSize=10` → `{ "items": [...], "totalCount": 0, "page": 1, "pageSize": 10, "totalPages": 0 }`.
- **Get lost object by id**: `GET http://localhost:5000/api/incident/lost-objects/{id}` → currently `204 No Content`.
- **Health (direct to the service, not exposed by the Gateway)**:
  - `GET http://localhost:5003/health` → `{ "service": "incident-service", "status": "healthy" }`
  - `GET http://localhost:5003/health/ready` → checks MongoDB connectivity.

---

### 4.11 Copy-paste script (bash + curl + jq)

```bash
BASE=http://localhost:5000

# 1) Register
curl -s -X POST $BASE/api/identity/register -H "Content-Type: application/json" \
  -d '{"name":"Ana Torres","email":"ana.prueba@uct.cl","password":"Password123!"}'

# 2) Login -> JWT
TOKEN=$(curl -s -X POST $BASE/api/identity/login -H "Content-Type: application/json" \
  -d '{"email":"ana.prueba@uct.cl","password":"Password123!"}' | jq -r .token)

# 3) Create lost object
LOST_ID=$(curl -s -X POST $BASE/api/incident/lost-objects \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Mochila negra","description":"Con un notebook","status":0,"photoUrl":"https://example.com/f.jpg","structureId":"11111111-1111-1111-1111-111111111111"}' | jq -r .id)
echo "LOST_ID=$LOST_ID"

# 4) Create report referencing the lost object
REPORT_ID=$(curl -s -X POST $BASE/api/incident/reports \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"structureRefId\":\"11111111-1111-1111-1111-111111111111\",\"ticketType\":0,\"isActive\":true,\"reportedAt\":\"2026-10-16T10:30:00Z\",\"lostObjectId\":\"$LOST_ID\"}" | jq -r .id)
echo "REPORT_ID=$REPORT_ID"

# 5) Read the report
curl -s $BASE/api/incident/reports/$REPORT_ID -H "Authorization: Bearer $TOKEN" | jq

# 6) Update report status
curl -s -o /dev/null -w "report status -> %{http_code}\n" -X PATCH $BASE/api/incident/reports/$REPORT_ID/report/status \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"status":1}'

# 7) Update lost object status
curl -s -o /dev/null -w "lost object status -> %{http_code}\n" -X PATCH $BASE/api/incident/lost-objects/$LOST_ID/lost/status \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"status":1}'

# 8) Search reports (advanced query) -> paged result
curl -s -G $BASE/api/incident/reports \
  -H "Authorization: Bearer $TOKEN" \
  --data-urlencode "type=0" \
  --data-urlencode "isActive=true" \
  --data-urlencode "complaintDetails.title=fuga" \
  --data-urlencode "sortBy=ReportedAt" \
  --data-urlencode "descending=true" \
  --data-urlencode "page=1" \
  --data-urlencode "pageSize=10" | jq

# 9) Search lost objects (same query style)
curl -s -G $BASE/api/incident/lost-objects \
  -H "Authorization: Bearer $TOKEN" \
  --data-urlencode "title=Mochila" \
  --data-urlencode "status=1" | jq
```

---

### 4.12 Common errors

| Status | Cause |
| :--- | :--- |
| `401 Unauthorized` | Missing/malformed `Authorization` header, or the JWT `sub` claim is not a valid user id. |
| `400 Bad Request` | Empty `structureRefId`/`structureId`, `ticketType`/`status` out of range, `photoUrl` that is not an absolute `http(s)` URL, or a `lostObjectId` that does not exist. |
| `400 Bad Request` (search) | `type` or `complaintDetails.status` outside its enum, or an unparsable search parameter (`page=abc`, unknown `sortBy`). |
| `404 Not Found` | The report or lost object id does not exist. |

> **Postman note**: the request `03. Incident Service > Create Lost Object Report (Validation)` in `tests/postman/uct-map.collection.json` sends `location`/`date`, which do not match the current DTO (`title`, `description`, `status`, `photoUrl`, `structureId`). Use the payload from [4.4](#44-create-a-lost-object) instead.
