# 📘 [Microservice Name] API Documentation

**Base URL**: `/api/[microservice-name]`

A brief description of what this microservice handles (e.g., *Handles all authentication, user creation, and role management.*)

---

## 🔒 Global Authentication
- **Mechanism**: JWT (JSON Web Token)
- **Header Format**: `Authorization: Bearer <token>`
- **Note**: Unless explicitly marked as `[Public]`, all endpoints require a valid JWT.

---

## 📑 Table of Contents
1. [Resource Name A (e.g., Users)](#1-resource-name-a)
2. [Resource Name B (e.g., Roles)](#2-resource-name-b)

---

## 1. [Resource Name A]
*Brief description of what this resource represents.*

### 📌 1.1 [Action Name] (e.g., Get All Users)
- **Route**: `GET /api/[microservice]/[resource]`
- **Access**: `ADMIN`, `TEACHER`
- **Description**: Returns a paginated list of all active users in the system.

**📥 Query Parameters**
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `page` | `int` | No | `1` | The page number to fetch. |
| `limit`| `int` | No | `10`| Number of records per page. |

**📤 Success Response (200 OK)**
```json
{
  "status": "success",
  "data": [
    { "id": "uuid", "name": "string" }
  ]
}
```

---

### 📌 1.2 [Action Name] (e.g., Create User)
- **Route**: `POST /api/[microservice]/[resource]`
- **Access**: `ADMIN`
- **Description**: Registers a new user into the system.

**📥 Request Payload (`application/json`)**
```json
{
  "email": "user@uct.cl",      // Required
  "password": "SecurePass123", // Required, min 8 chars
  "role": "STUDENT"            // Optional, defaults to STUDENT
}
```

**📤 Success Response (201 Created)**
```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "email": "user@uct.cl"
  }
}
```

**❌ Error Responses**
- **`400 Bad Request`**: If validation fails (e.g., email format invalid).
- **`403 Forbidden`**: If the requester does not have the `ADMIN` role.

---

## 2. [Resource Name B]
*Brief description of what this resource represents.*

### 📌 2.1 [Action Name]
- **Route**: `[METHOD] /api/[microservice]/[resource]`
- **Access**: `[ROLES]`
- **Description**: [Description]

*(Follow the same structure as above...)*
