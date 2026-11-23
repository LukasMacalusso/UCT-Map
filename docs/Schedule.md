# Schedule API Documentation

**Base URL**: `/api/schedule`

Handles teachers' weekly office hours and the meetings between teachers and students, including the room (structure) where each one takes place.

---

## Global Authentication
- **Mechanism**: JWT (JSON Web Token) issued by Identity. It is validated by the API Gateway and again by this service (signature, issuer, audience and expiration), so calling the service directly also requires a valid token.
- **Header Format**: `Authorization: Bearer <token>`
- **User identification**: the user is the `sub` claim of the token, administrators are users with the `Admin` value in the `role` claim and teachers have the `Teacher` value. Creating, editing or deleting office hours requires the `Teacher` or `Admin` role.
- **Note**: Unless explicitly marked as `[Public]`, all endpoints require a valid JWT and return `401 Unauthorized` without it. Endpoints marked as owner-only compare the `sub` claim with the requested id to prevent Insecure Direct Object Reference (IDOR); other users receive `403 Forbidden`.

## Conventions
- References to other microservices are plain ids: `teacherRefId` and `studentRefId` (Identity), `structureRefId` (Campus).
- Dates use ISO 8601 and are UTC instants: `2026-10-12T15:30:00` is read as UTC. A `Z` suffix or an offset (`-03:00`) is also accepted and converted to UTC. Responses return UTC dates without suffix.
- Office hour times (`HH:mm:ss`) are wall-clock times on campus, in the `America/Santiago` time zone (setting `Schedule__TimeZone`). To compare them with a meeting, the meeting is converted to campus time first, which also decides its weekday.
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
- **Access**: A user with the `Teacher` role who is the teacher of the block (`teacherRefId` must match the user), or an administrator
- **Description**: Registers a weekly office hour block for a teacher. The block is rejected if, on the same weekday, it overlaps another block of the same teacher or, when `structureRefId` is sent, another block in the same room. A block may start exactly when another one ends. The check and the insert run in a single serializable transaction.

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
- **`403 Forbidden`**: If the user does not have the `Teacher` or `Admin` role, or is not the teacher of the block and is not an administrator.
- **`409 Conflict`**: If the teacher or the room already has an overlapping block that day, or if another request took the slot at the same moment (e.g., `"The teacher already has an office hour at that time."`).

---

### 1.4 Update Office Hour
- **Route**: `PUT /api/schedule/office-hours/{id}`
- **Access**: A user with the `Teacher` role who is the teacher of the block, or an administrator
- **Description**: Changes the room, weekday and hours of a block. The teacher of a block cannot be changed. The same overlap rules as 1.3 apply, ignoring the block itself. Upcoming `Pending` or `Confirmed` meetings that were inside the block and no longer fit any office hour of the teacher are cancelled in the same transaction. Past meetings are not changed.

**Request Payload (`application/json`)**
```json
{
  "structureRefId": "uuid",    // Optional, room where the block takes place
  "dayOfWeek": 1,              // Required, 0 = Sunday ... 6 = Saturday
  "startTime": "09:00:00",     // Required
  "endTime": "12:00:00"        // Required, must be later than startTime
}
```

**Success Response (200 OK)**: the updated block (same object as in 1.1).

**Error Responses**
- **`400 Bad Request`**: If `endTime` is not later than `startTime`.
- **`403 Forbidden`**: If the user does not have the `Teacher` or `Admin` role, or is not the teacher of the block and is not an administrator.
- **`404 Not Found`**: If the block does not exist.
- **`409 Conflict`**: If the new hours overlap another block of the teacher or the room that day, or if another request changed it at the same moment.

---

### 1.5 Delete Office Hour
- **Route**: `DELETE /api/schedule/office-hours/{id}`
- **Access**: A user with the `Teacher` role who is the teacher of the block, or an administrator
- **Description**: Deletes a block. Its upcoming `Pending` or `Confirmed` meetings are cancelled in cascade (they are kept with `Cancelled` status, not deleted). Past meetings are not changed. To move a meeting, cancel it and book a new one.

**Success Response (204 No Content)**: empty body.

**Error Responses**
- **`403 Forbidden`**: If the user does not have the `Teacher` or `Admin` role, or is not the teacher of the block and is not an administrator.
- **`404 Not Found`**: If the block does not exist.
- **`409 Conflict`**: If another request changed the block at the same moment.

---

## 2. Meetings
*An appointment between a teacher and a student at a given date and time, optionally in a room.*

### 2.1 Get All Meetings
- **Route**: `GET /api/schedule/meetings`
- **Access**: Any authenticated user
- **Description**: Without `teacherId`, administrators get every meeting and any other user gets only the meetings where they are the student or the teacher, ordered by date. When `teacherId` is provided, returns that teacher's meetings inside the `[from, to)` range for any authenticated user (students use it to see the busy slots before booking), and both dates become required.

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
- **Access**: The student or the teacher of the meeting, or an administrator
- **Description**: Returns a single meeting.

**Success Response (200 OK)**: same object as in 2.1.

**Error Responses**
- **`403 Forbidden`**: If the user is neither the student nor the teacher of the meeting and is not an administrator.
- **`404 Not Found`**: If no meeting exists with that id.

---

### 2.3 Create Meeting
- **Route**: `POST /api/schedule/meetings`
- **Access**: The student or the teacher of the meeting (`studentRefId` or `teacherRefId` must match the user), or an administrator
- **Description**: Schedules a meeting. It always starts in `Pending` status. The whole meeting must fit inside one of the teacher's office hours on that weekday, in campus time. The meeting is also rejected if, during its time range, the same teacher, the same student or the same room already has an active meeting. Cancelled meetings do not block a slot. A meeting may start exactly when another one ends. The check and the insert run in a single serializable transaction, so two simultaneous requests cannot book the same slot.

**Request Payload (`application/json`)**
```json
{
  "teacherRefId": "uuid",               // Required
  "studentRefId": "uuid",               // Required
  "structureRefId": "uuid",             // Optional, room where the meeting takes place. If omitted, room availability is not checked
  "scheduledAt": "2026-10-12T15:30:00", // Required, UTC
  "durationMinutes": 30                 // Required, must be greater than 0
}
```

**Success Response (201 Created)**: the created meeting (same object as in 2.1). The `Location` header points to 2.2.

**Error Responses**
- **`400 Bad Request`**: If `durationMinutes` is not greater than 0, or if the meeting is not inside an office hour of the teacher (`"The meeting must be inside one of the teacher's office hours."`).
- **`403 Forbidden`**: If the user is neither the student nor the teacher of the meeting and is not an administrator.
- **`409 Conflict`**: If the teacher, the student or the room already has a meeting in that time range, or if another request booked the slot at the same moment. The `message` states which one is busy (e.g., `"The teacher already has a meeting at that time."`).

---

### 2.4 Update Meeting Status
- **Route**: `PATCH /api/schedule/meetings/{id}/status`
- **Access**: Only the student or the teacher of the meeting, depending on the new status
- **Description**: Changes the status of a meeting. The user is identified by the `sub` claim of the JWT, which is compared with the meeting's `studentRefId` and `teacherRefId`. A cancelled meeting no longer blocks its time slot.

| New status | Who can set it | Current status required |
| :--- | :--- | :--- |
| `Confirmed` | Teacher | `Pending` |
| `Cancelled` | Student or teacher | `Pending` or `Confirmed` |
| `Completed` | Teacher | `Confirmed` |

**Request Payload (`application/json`)**
```json
{
  "status": "Confirmed"   // Required, Confirmed, Cancelled or Completed
}
```

**Success Response (200 OK)**: the updated meeting (same object as in 2.1).

**Error Responses**
- **`400 Bad Request`**: If `status` is missing or is not `Confirmed`, `Cancelled` or `Completed`.
- **`401 Unauthorized`**: If the token is missing or invalid, or has no valid user id.
- **`403 Forbidden`**: If the user is neither the student nor the teacher of the meeting (administrators included), or if the student tries to confirm or complete it.
- **`404 Not Found`**: If no meeting exists with that id.
- **`409 Conflict`**: If the meeting's current status does not allow the change.

---

### 2.5 Reschedule Meeting
- **Route**: `PUT /api/schedule/meetings/{id}`
- **Access**: Only the student or the teacher of the meeting (not administrators)
- **Description**: Moves a `Pending` or `Confirmed` meeting to another time, length or room. The teacher and the student cannot be changed, and the status is kept. The same rules as 2.3 apply to the new slot, ignoring the meeting itself: it must fit inside an office hour of the teacher and must not overlap an active meeting of the teacher, the student or the room. The old slot is freed.

**Request Payload (`application/json`)**
```json
{
  "structureRefId": "uuid",             // Optional, room where the meeting takes place
  "scheduledAt": "2026-10-12T16:00:00", // Required, UTC
  "durationMinutes": 45                 // Required, must be greater than 0
}
```

**Success Response (200 OK)**: the updated meeting (same object as in 2.1).

**Error Responses**
- **`400 Bad Request`**: If `durationMinutes` is not greater than 0, or if the new slot is not inside an office hour of the teacher.
- **`401 Unauthorized`**: If the token is missing or invalid, or has no valid user id.
- **`403 Forbidden`**: If the user is neither the student nor the teacher of the meeting.
- **`404 Not Found`**: If no meeting exists with that id.
- **`409 Conflict`**: If the meeting is cancelled or completed, if the teacher, the student or the room is busy at the new time, or if another request booked the slot at the same moment.

---

### 2.6 Cancel Meeting
- **Route**: `DELETE /api/schedule/meetings/{id}`
- **Access**: Only the student or the teacher of the meeting (not administrators)
- **Description**: Cancels a `Pending` or `Confirmed` meeting. The meeting is not deleted: it is kept with `Cancelled` status and its time slot is freed. Same as 2.4 with `Cancelled`.

**Success Response (204 No Content)**: empty body.

**Error Responses**
- **`401 Unauthorized`**: If the token is missing or invalid, or has no valid user id.
- **`403 Forbidden`**: If the user is neither the student nor the teacher of the meeting.
- **`404 Not Found`**: If no meeting exists with that id.
- **`409 Conflict`**: If the meeting is already cancelled or completed.

---

## 3. Teachers
*Read-only views that aggregate a teacher's office hours and meetings.*

### 3.1 Get Teacher Workload
- **Route**: `GET /api/schedule/teachers/{teacherId}/workload`
- **Access**: The teacher (`teacherId` must match the user) or an administrator
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
- **`403 Forbidden`**: If the user is not that teacher and is not an administrator.

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
- **Access**: The student (`studentId` must match the user) or an administrator
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
- **`403 Forbidden`**: If the user is not that student and is not an administrator.

---

## 5. Rooms
*Availability of rooms (structures), crossing meetings and office hours. The list of rooms belongs to the Campus service, so the caller sends the rooms it wants to check.*

### 5.1 Get Room Availability
- **Route**: `GET /api/schedule/rooms/availability`
- **Access**: Any authenticated user
- **Description**: Given a list of rooms and a time range within a single day, returns which rooms are free and why the others are occupied. A room is occupied if it has an active meeting, or an office hour on that weekday, overlapping the range. The weekday and the office hours are evaluated in campus time, and office hour occupations are returned in UTC like the rest of the dates. Cancelled meetings do not occupy a room, and a room is free if an occupation ends exactly when the range starts.

**Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `roomIds` | `uuid` (repeatable) | Yes | — | Rooms to check. Repeat the parameter for each room: `roomIds=A&roomIds=B`. |
| `from` | `datetime` | Yes | — | Range start (inclusive). |
| `to` | `datetime` | Yes | — | Range end (exclusive). Must be later than `from` and on the same campus day. |

**Example**: `GET /api/schedule/rooms/availability?from=2026-11-02T13:00:00&to=2026-11-02T14:00:00&roomIds=A&roomIds=B&roomIds=C`

**Success Response (200 OK)**
```json
{
  "from": "2026-11-02T13:00:00",
  "to": "2026-11-02T14:00:00",
  "freeRoomIds": [ "uuid" ],
  "occupancies": [
    {
      "structureRefId": "uuid",
      "reason": "OfficeHour",
      "occupiedFrom": "2026-11-02T12:00:00",
      "occupiedUntil": "2026-11-02T15:00:00"
    },
    {
      "structureRefId": "uuid",
      "reason": "Meeting",
      "occupiedFrom": "2026-11-02T13:15:00",
      "occupiedUntil": "2026-11-02T13:45:00"
    }
  ]
}
```
In this example the office hour is 09:00-12:00 on campus (UTC-3), returned as 12:00-15:00 UTC. `reason` is `Meeting` or `OfficeHour`. A room may appear more than once in `occupancies` if several things occupy it.

**Error Responses**
- **`400 Bad Request`**: If `from` or `to` are missing, `to` is not later than `from`, the range spans more than one campus day, no `roomIds` are sent, or a room id is empty or not a valid uuid.

---

## 6. Health
*Internal endpoints for container health checks. They are not exposed through the API Gateway.*

### 6.1 Service Health `[Public]`
- **Route**: `GET /health`
- **Description**: Returns `200 OK` with `{ "service": "schedule-service", "status": "healthy" }`.

### 6.2 Database Health `[Public]`
- **Route**: `GET /health/database`
- **Description**: Returns `200 OK` with `{ "database": "schedule", "status": "connected" }`, or `503 Service Unavailable` when the database cannot be reached.
