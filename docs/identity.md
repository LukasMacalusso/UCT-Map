# 📘 Identity Microservice API Documentation

**Base URL**: `/api/identity`

The Identity microservice handles user registration, login, user lookup, and
service health checks.

---

## 🔒 Authentication

The login endpoint returns a JWT for the authenticated user. The current API
configuration does not register JWT authentication or authorization middleware,
so the endpoints documented below do not require an `Authorization` header.

---

## 📑 Table of Contents

1. [Identity](#1-identity)
2. [Health](#2-health)

---

## 1. Identity

These endpoints manage user registration, authentication, and user lookup.

### 📌 1.1 Login

- **Route**: `POST /api/identity/login`
- **Access**: Public
- **Description**: Authenticates a user and returns a JWT.

**📥 Request Payload (`application/json`)**

```json
{
  "email": "user@uct.cl",
  "password": "Password123!"
}
```

**📤 Success Response (200 OK)**

```json
{
  "userId": "string",
  "email": "user@uct.cl",
  "token": "jwt"
}
```

**❌ Error Responses**

- **`400 Bad Request`**: Email or password is missing.
- **`401 Unauthorized`**: The credentials are invalid.

---

### 📌 1.2 Register User

- **Route**: `POST /api/identity/register`
- **Access**: Public
- **Description**: Creates a new user. If no role is provided, the
  implementation assigns the `Student` role.

**📥 Request Payload (`application/json`)**

```json
{
  "name": "Ana Torres",
  "email": "ana@uct.cl",
  "password": "Password123!",
  "role": "Student"
}
```

**📤 Success Response (201 Created)**

```json
{
  "userId": "string",
  "name": "Ana Torres",
  "email": "ana@uct.cl",
  "role": "Student"
}
```

**❌ Error Responses**

- **`400 Bad Request`**: A required field is missing or registration fails.

---

### 📌 1.3 Get User by ID

- **Route**: `GET /api/identity/{userId}`
- **Access**: Public
- **Description**: Returns the user identified by `userId`.

**📥 Route Parameters**

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `userId` | `string` | Yes | The Identity user identifier. |

**📤 Success Response (200 OK)**

```json
{
  "userId": "string",
  "name": "Ana Torres",
  "email": "ana@uct.cl",
  "role": "Student"
}
```

**❌ Error Responses**

- **`400 Bad Request`**: The user ID is missing.
- **`404 Not Found`**: No user exists with the specified ID.

---

## 2. Health

These endpoints report the availability of the Identity service and its
database connection.

### 📌 2.1 Service Health

- **Route**: `GET /health`
- **Access**: Public
- **Description**: Returns the current service health status.

**📤 Success Response (200 OK)**

```json
{
  "service": "identity-service",
  "status": "healthy"
}
```

---

### 📌 2.2 Database Health

- **Route**: `GET /health/database`
- **Access**: Public
- **Description**: Checks whether the Identity database can be reached.

**📤 Success Response (200 OK)**

```json
{
  "database": "identity",
  "status": "connected"
}
```

**❌ Error Responses**

- **`503 Service Unavailable`**: The database is unavailable or the connection
  check fails.
