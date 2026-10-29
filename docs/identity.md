# 📘 Identity Microservice API Documentation

**Base URL**: `/api/identity`

The Identity microservice handles user registration, login, user lookup, and
service health checks.

---

## 🔒 Authentication

The login endpoint returns a JWT for the authenticated user. The current API
configuration validates JWT authentication and authorization middleware. Except
for login and registration, the endpoints below require an `Authorization`
header with a valid JWT.
The token includes the user's role in the explicit `role` claim. For example:

```json
{
  "role": "Student"
}
```

---

## 📑 Table of Contents

1. [Identity](#1-identity)
2. [Health](#2-health)

---

## 1. Identity

These endpoints manage user registration, authentication, and user lookup.

Role-management endpoints require the `Admin` role. A suspended user cannot
authenticate until an administrator reactivates the account.

### 📌 1.1 Get All Users

- **Route**: `GET /api/identity`
- **Access**: Authenticated users
- **Description**: Returns all registered users.

**📤 Success Response (200 OK)**

```json
[
  {
    "userId": "string",
    "name": "Ana Torres",
    "email": "ana@uct.cl",
    "role": "Student"
  }
]
```

---

### 📌 1.2 Login

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

The JWT returned in `token` includes the authenticated user's role in the
`role` claim.

**❌ Error Responses**

- **`400 Bad Request`**: Email or password is missing.
- **`401 Unauthorized`**: The credentials are invalid.

---

### 📌 1.3 Register User

- **Route**: `POST /api/identity/register`
- **Access**: Public
- **Description**: Creates a new user with the `Student` role. Privileged roles
  must be assigned by an administrator through the protected role endpoints.

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

### 📌 1.4 Get User by ID

- **Route**: `GET /api/identity/{userId}`
- **Access**: Authenticated users
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

### 📌 1.5 Get User Roles

- **Route**: `GET /api/identity/{userId}/roles`
- **Access**: Admin
- **Description**: Returns the roles and suspension state of a user.

### 📌 1.6 Add User Role

- **Route**: `POST /api/identity/{userId}/roles`
- **Access**: Admin

```json
{
  "role": "Teacher"
}
```

### 📌 1.7 Replace User Roles

- **Route**: `PUT /api/identity/{userId}/roles`
- **Access**: Admin

```json
{
  "roles": ["Teacher", "ObjectsOfficer"]
}
```

### 📌 1.8 Remove User Role

- **Route**: `DELETE /api/identity/{userId}/roles/{role}`
- **Access**: Admin

### 📌 1.9 Suspend User

- **Route**: `POST /api/identity/{userId}/suspension`
- **Access**: Admin

### 📌 1.10 Reactivate User

- **Route**: `DELETE /api/identity/{userId}/suspension`
- **Access**: Admin

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
