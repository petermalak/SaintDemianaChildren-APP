# Saint Demiana Children API Documentation

## Base URL
- **Production**: `https://api.saintdemiana.com`
- **Development**: `http://localhost:3000`

## Authentication
All endpoints (except login) require a Bearer token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## Roles & Permissions
- **admin**: Full system access
- **khadem**: Church servant with management permissions
- **makhdoum**: Church member with basic permissions

---

## 🔐 Authentication Endpoints

### 1. Login
**POST** `/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "role": "khadem"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "user@example.com",
    "role": "khadem",
    "profileImage": null,
    "additionalData": null
  }
}
```

### 2. Logout
**POST** `/auth/logout`

**Response (200):**
```json
{
  "success": true
}
```

---

## 👤 User Endpoints

### 1. Get My Profile
**GET** `/users/me`

**Response (200):**
```json
{
  "id": "uuid",
  "name": "John Doe",
  "email": "user@example.com",
  "phone": "+1234567890",
  "role": "khadem",
  "profileImage": "/uploads/profile.jpg",
  "additionalData": {
    "address": "123 Main St",
    "familyMembers": 4,
    "baptismDate": "2020-01-15",
    "confessionDate": "2020-01-20"
  }
}
```

### 2. Update My Profile
**PATCH** `/users/me`
**Permission Required:** `profile.update`

**Request Body:**
```json
{
  "phone": "+1234567890",
  "additionalData": {
    "address": "456 New St",
    "familyMembers": 5
  }
}
```

### 3. Update Profile Image
**POST** `/users/me/profile-image`
**Permission Required:** `profile.update`

**Request Body:** `multipart/form-data`
- `image`: (file) Profile image

**Response (200):**
```json
{
  "imageUrl": "/uploads/1234567890-profile.jpg"
}
```

### 4. List Users
**GET** `/users`
**Permission Required:** `users.read`

**Query Parameters:**
- `role` (optional): Filter by role (`khadem`, `makhdoum`)

**Response (200):**
```json
[
  {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "khadem",
    "profileImage": "/uploads/profile.jpg"
  }
]
```

### 5. Create User
**POST** `/users`
**Permission Required:** `users.create`

**Request Body:**
```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "password123",
  "phone": "+1234567890",
  "role": "makhdoum",
  "additionalData": {
    "address": "789 Oak St",
    "familyMembers": 3
  }
}
```

### 6. Get User by ID
**GET** `/users/:id`
**Permission Required:** `users.read`

### 7. Update User
**PUT** `/users/:id`
**Permission Required:** `users.update`

### 8. Delete User
**DELETE** `/users/:id`
**Permission Required:** `users.delete`

---

## 📅 Attendance Endpoints

### 1. List Attendance
**GET** `/attendance`
**Permission Required:** `attendance.read`

**Query Parameters:**
- `type` (optional): Filter by type (`mass`, `specialMeeting`, `generalMeeting`, `praise`)
- `userId` (optional): Filter by user ID (admin/khadem only)
- `date` (optional): Filter by date (YYYY-MM-DD)

**Response (200):**
```json
[
  {
    "id": "uuid",
    "userId": "uuid",
    "userName": "John Doe",
    "type": "mass",
    "date": "2024-01-15",
    "notes": "Regular Sunday mass",
    "createdAt": "2024-01-15T10:00:00Z"
  }
]
```

### 2. Create Attendance
**POST** `/attendance`
**Permission Required:** `attendance.create`

**Request Body:**
```json
{
  "userId": "uuid",
  "userName": "John Doe",
  "type": "mass",
  "date": "2024-01-15",
  "notes": "Regular Sunday mass"
}
```

### 3. Get Attendance by ID
**GET** `/attendance/:id`
**Permission Required:** `attendance.read`

### 4. Update Attendance
**PUT** `/attendance/:id`
**Permission Required:** `attendance.update`

### 5. Delete Attendance
**DELETE** `/attendance/:id`
**Permission Required:** `attendance.delete`

---

## 🔒 Permission System

### Available Permissions:
- `users.create` - Create users
- `users.read` - View users
- `users.update` - Update users
- `users.delete` - Delete users
- `attendance.create` - Create attendance
- `attendance.read` - View attendance
- `attendance.update` - Update attendance
- `attendance.delete` - Delete attendance
- `profile.read` - View own profile
- `profile.update` - Update own profile

### Role-Permission Matrix:

| Permission | Admin | Khadem | Makhdoum |
|------------|-------|--------|----------|
| users.create | ✅ | ❌ | ❌ |
| users.read | ✅ | ✅ | ❌ |
| users.update | ✅ | ✅ | ❌ |
| users.delete | ✅ | ❌ | ❌ |
| attendance.create | ✅ | ✅ | ❌ |
| attendance.read | ✅ | ✅ | ✅ |
| attendance.update | ✅ | ✅ | ❌ |
| attendance.delete | ✅ | ✅ | ❌ |
| profile.read | ✅ | ✅ | ✅ |
| profile.update | ✅ | ✅ | ✅ |

---

## 📱 Mobile App Testing Guide

### 1. **Setup Test Users**

**Create Admin User:**
```bash
POST /users
{
  "name": "Admin User",
  "email": "admin@test.com",
  "password": "admin123",
  "role": "admin"
}
```

**Create Khadem User:**
```bash
POST /users
{
  "name": "Khadem User",
  "email": "khadem@test.com",
  "password": "khadem123",
  "role": "khadem"
}
```

**Create Makhdoum User:**
```bash
POST /users
{
  "name": "Makhdoum User",
  "email": "makhdoum@test.com",
  "password": "makhdoum123",
  "role": "makhdoum"
}
```

### 2. **Test Authentication Flow**

1. **Login with each user type**
2. **Verify token is returned**
3. **Test protected endpoints with token**
4. **Test logout**

### 3. **Test Permission System**

**Admin Tests:**
- ✅ Can create/read/update/delete users
- ✅ Can create/read/update/delete attendance
- ✅ Can update profile

**Khadem Tests:**
- ❌ Cannot create/delete users
- ✅ Can read/update users
- ✅ Can create/read/update/delete attendance
- ✅ Can update profile

**Makhdoum Tests:**
- ❌ Cannot access user management
- ❌ Cannot create/update/delete attendance
- ✅ Can read attendance (own records only)
- ✅ Can update own profile

### 4. **Test Attendance Filtering**

**As Makhdoum:**
- GET `/attendance` → Should only return own records
- GET `/attendance?userId=other-user-id` → Should still only return own records

**As Admin/Khadem:**
- GET `/attendance` → Should return all records
- GET `/attendance?userId=specific-id` → Should return specific user's records

---

## 🚨 Error Responses

### 401 Unauthorized
```json
{
  "message": "No token provided"
}
```

### 403 Forbidden
```json
{
  "message": "Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "message": "User not found"
}
```

### 400 Bad Request
```json
{
  "message": "Missing required fields"
}
```

---

## 🧪 Testing Checklist

- [ ] Server starts successfully
- [ ] Database connection works
- [ ] All migrations applied
- [ ] Default roles/permissions seeded
- [ ] Login endpoint works
- [ ] Token authentication works
- [ ] Permission system works correctly
- [ ] File upload works
- [ ] Error handling works
- [ ] All CRUD operations work
- [ ] Role-based filtering works

---

## 📞 Support

For any issues or questions, please contact the backend development team.