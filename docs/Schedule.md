# Schedule API Documentation

**Base URL**: `/api/schedule`

Handles teachers' weekly office hours and the meetings between teachers and students, including the room (structure) where each one takes place.

---

## Global Authentication
- **Mechanism**: JWT (JSON Web Token), validated by the API Gateway.
- **Header Format**: `Authorization: Bearer <token>`
- **Note**: Unless explicitly marked as `[Public]`, all endpoints require a valid JWT. No endpoint is restricted to a specific role.

## Conventions
- References to other microservices are plain ids: `teacherRefId` and `studentRefId` (Identity), `structureRefId` (Campus).
- Dates use ISO 8601 without time zone: `2026-10-12T15:30:00`. Times use `HH:mm:ss`.
- In requests, `dayOfWeek` is an integer (`0` = Sunday … `6` = Saturday). In responses it is returned as text (`"Monday"`).
- Handled errors return `{ "message": "..." }`.

---

## Table of Contents
1. [Office Hours](#1-office-hours)
2. [Meetings](#2-meetings)
3. [Teachers](#3-teachers)
4. [Students](#4-students)
5. [Rooms](#5-rooms)
6. [Health](#6-health)

---

## 1. Office Hours
*A weekly block in which a teacher attends students, optionally linked to a room.*

### 1.1 Get All Office Hours
- **Route**: `GET /api/schedule/office-hours`
- **Access**: Any authenticated user
- **Description**: Returns every office hour block, or only one teacher's blocks when `teacherId` is provided. Blocks are ordered by weekday starting on Monday, then by start time.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `teacherId` | `uuid` | No | — | Returns only this teacher's blocks. |

**Success Response (200 OK)**
```json
[
  {
    "id": "uuid",
    "teacherRefId": "uuid",
    "structureRefId": "uuid | null",
    "dayOfWeek": "Monday",
    "startTime": "09:00:00",
    "endTime": "11:00:00"
  }
]
```

**Error Responses**
- **`400 Bad Request`**: If `teacherId` is an empty uuid.

---

### 1.2 Get Office Hour By Id
- **Route**: `GET /api/schedule/office-hours/{id}`
- **Access**: Any authenticated user
- **Description**: Returns a single office hour block.

**Success Response (200 OK)**: same object as in 1.1.

**Error Responses**
- **`404 Not Found`**: If no block exists with that id.

---

### 1.3 Create Office Hour
- **Route**: `POST /api/schedule/office-hours`
- **Access**: Any authenticated user
- **Description**: Registers a weekly office hour block for a teacher.

**Request Payload (`application/json`)**
```json
{
  "teacherRefId": "uuid",      // Required
  "structureRefId": "uuid",    // Optional, room where the block takes place
  "dayOfWeek": 1,              // Required, 0 = Sunday ... 6 = Saturday
  "startTime": "09:00:00",     // Required
  "endTime": "11:00:00"        // Required, must be later than startTime
}
```

**Success Response (201 Created)**: the created block (same object as in 1.1). The `Location` header points to 1.2.

**Error Responses**
- **`400 Bad Request`**: If `endTime` is not later than `startTime`.

---

## 2. Meetings
*An appointment between a teacher and a student at a given date and time, optionally in a room.*

### 2.1 Get All Meetings
- **Route**: `GET /api/schedule/meetings`
- **Access**: Any authenticated user
- **Description**: Returns every meeting ordered by date. When `teacherId` is provided, returns only that teacher's meetings inside the `[from, to)` range, and both dates become required.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `teacherId` | `uuid` | No | — | Returns only this teacher's meetings. |
| `from` | `datetime` | Only with `teacherId` | — | Range start (inclusive). |
| `to` | `datetime` | Only with `teacherId` | — | Range end (exclusive). Must be later than `from`. |

**Success Response (200 OK)**
```json
[
  {
    "id": "uuid",
    "teacherRefId": "uuid",
    "studentRefId": "uuid",
    "structureRefId": "uuid | null",
    "scheduledAt": "2026-10-12T15:30:00",
    "durationMinutes": 30,
    "status": "Pending"
  }
]
```

**Error Responses**
- **`400 Bad Request`**: If `teacherId` is an empty uuid, if `teacherId` is sent without `from` and `to`, or if `to` is not later than `from`.

---

### 2.2 Get Meeting By Id
- **Route**: `GET /api/schedule/meetings/{id}`
- **Access**: Any authenticated user
- **Description**: Returns a single meeting.

**Success Response (200 OK)**: same object as in 2.1.

**Error Responses**
- **`404 Not Found`**: If no meeting exists with that id.

---

### 2.3 Create Meeting
- **Route**: `POST /api/schedule/meetings`
- **Access**: Any authenticated user
- **Description**: Schedules a meeting. It always starts in `Pending` status. The meeting is rejected if, during its time range, the same teacher, the same student or the same room already has an active meeting. Cancelled meetings do not block a slot. A meeting may start exactly when another one ends. The check and the insert run in a single serializable transaction, so two simultaneous requests cannot book the same slot.

**Request Payload (`application/json`)**
```json
{
  "teacherRefId": "uuid",               // Required
  "studentRefId": "uuid",               // Required
  "structureRefId": "uuid",             // Optional, room where the meeting takes place. If omitted, room availability is not checked
  "scheduledAt": "2026-10-12T15:30:00", // Required
  "durationMinutes": 30                 // Required, must be greater than 0
}
```

**Success Response (201 Created)**: the created meeting (same object as in 2.1). The `Location` header points to 2.2.

**Error Responses**
- **`400 Bad Request`**: If `durationMinutes` is not greater than 0.
- **`409 Conflict`**: If the teacher, the student or the room already has a meeting in that time range, or if another request booked the slot at the same moment. The `message` states which one is busy (e.g., `"The teacher already has a meeting at that time."`).

---

## 3. Teachers
*Read-only views that aggregate a teacher's office hours and meetings.*

### 3.1 Get Teacher Workload
- **Route**: `GET /api/schedule/teachers/{teacherId}/workload`
- **Access**: Any authenticated user
- **Description**: Returns the teacher's office hours, the total weekly office hour minutes, and the meetings inside the `[from, to)` range.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `from` | `datetime` | Yes | — | Range start (inclusive). |
| `to` | `datetime` | Yes | — | Range end (exclusive). Must be later than `from`. |

**Success Response (200 OK)**
```json
{
  "teacherRefId": "uuid",
  "from": "2026-10-12T00:00:00",
  "to": "2026-10-19T00:00:00",
  "weeklyOfficeHourMinutes": 240,
  "meetingCount": 2,
  "officeHours": [ /* objects as in 1.1 */ ],
  "meetings": [ /* objects as in 2.1 */ ]
}
```

**Error Responses**
- **`400 Bad Request`**: If `teacherId` is an empty uuid or `to` is not later than `from`.

---

### 3.2 Get Teacher Availability
- **Route**: `GET /api/schedule/teachers/{teacherId}/availability`
- **Access**: Any authenticated user
- **Description**: Returns the teacher's office hour blocks, ordered by weekday starting on Monday. Meetings inside those blocks are not subtracted.

**Success Response (200 OK)**
```json
{
  "teacherRefId": "uuid",
  "availableBlocks": [ /* objects as in 1.1 */ ]
}
```

**Error Responses**
- **`400 Bad Request`**: If `teacherId` is an empty uuid.

---

## 4. Students

### 4.1 Get Student Meetings
- **Route**: `GET /api/schedule/students/{studentId}/meetings`
- **Access**: Any authenticated user
- **Description**: Returns the student's meetings inside the `[from, to)` range, ordered by date.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `from` | `datetime` | Yes | — | Range start (inclusive). |
| `to` | `datetime` | Yes | — | Range end (exclusive). Must be later than `from`. |

**Success Response (200 OK)**
```json
{
  "studentRefId": "uuid",
  "from": "2026-10-12T00:00:00",
  "to": "2026-10-19T00:00:00",
  "meetingCount": 1,
  "meetings": [ /* objects as in 2.1 */ ]
}
```

**Error Responses**
- **`400 Bad Request`**: If `studentId` is an empty uuid or `to` is not later than `from`.

---

## 5. Rooms
*Availability of rooms (structures), crossing meetings and office hours. The list of rooms belongs to the Campus service, so the caller sends the rooms it wants to check.*

### 5.1 Get Room Availability
- **Route**: `GET /api/schedule/rooms/availability`
- **Access**: Any authenticated user
- **Description**: Given a list of rooms and a time range within a single day, returns which rooms are free and why the others are occupied. A room is occupied if it has an active meeting, or an office hour on that weekday, overlapping the range. Cancelled meetings do not occupy a room, and a room is free if an occupation ends exactly when the range starts.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `roomIds` | `uuid` (repeatable) | Yes | — | Rooms to check. Repeat the parameter for each room: `roomIds=A&roomIds=B`. |
| `from` | `datetime` | Yes | — | Range start (inclusive). |
| `to` | `datetime` | Yes | — | Range end (exclusive). Must be later than `from` and on the same day. |

**Example**: `GET /api/schedule/rooms/availability?from=2026-11-02T10:00:00&to=2026-11-02T11:00:00&roomIds=A&roomIds=B&roomIds=C`

**Success Response (200 OK)**
```json
{
  "from": "2026-11-02T10:00:00",
  "to": "2026-11-02T11:00:00",
  "freeRoomIds": [ "uuid" ],
  "occupancies": [
    {
      "structureRefId": "uuid",
      "reason": "OfficeHour",
      "occupiedFrom": "2026-11-02T09:00:00",
      "occupiedUntil": "2026-11-02T12:00:00"
    },
    {
      "structureRefId": "uuid",
      "reason": "Meeting",
      "occupiedFrom": "2026-11-02T10:15:00",
      "occupiedUntil": "2026-11-02T10:45:00"
    }
  ]
}
```
`reason` is `Meeting` or `OfficeHour`. A room may appear more than once in `occupancies` if several things occupy it.

**Error Responses**
- **`400 Bad Request`**: If `from` or `to` are missing, `to` is not later than `from`, the range spans more than one day, no `roomIds` are sent, or a room id is empty or not a valid uuid.

---

## 6. Health
*Internal endpoints for container health checks. They are not exposed through the API Gateway.*

### 6.1 Service Health `[Public]`
- **Route**: `GET /health`
- **Description**: Returns `200 OK` with `{ "service": "schedule-service", "status": "healthy" }`.

### 6.2 Database Health `[Public]`
- **Route**: `GET /health/database`
- **Description**: Returns `200 OK` with `{ "database": "schedule", "status": "connected" }`, or `503 Service Unavailable` when the database cannot be reached.
