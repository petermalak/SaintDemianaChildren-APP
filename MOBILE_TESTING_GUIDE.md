# Mobile App Testing Guide - Saint Demiana Children API

## 🚀 Quick Start

### 1. Start the Backend Server
```bash
cd SaintDemianaChildren-BE
npm run dev
```
Server will run on `http://localhost:3000`

### 2. Test Database Connection
Make sure your MySQL database is running and the `.env` file has correct credentials.

---

## 📱 Mobile App Integration

### Base Configuration
```javascript
const API_BASE_URL = 'http://localhost:3000'; // Development
// const API_BASE_URL = 'https://api.saintdemiana.com'; // Production

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add token to requests
apiClient.interceptors.request.use((config) => {
  const token = AsyncStorage.getItem('auth_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

---

## 🔐 Authentication Testing

### 1. Login Test
```javascript
const login = async (email, password, role) => {
  try {
    const response = await apiClient.post('/auth/login', {
      email,
      password,
      role
    });
    
    const { token, user } = response.data;
    await AsyncStorage.setItem('auth_token', token);
    await AsyncStorage.setItem('user_data', JSON.stringify(user));
    
    return { success: true, user };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};

// Test with different roles
await login('admin@test.com', 'admin123', 'admin');
await login('khadem@test.com', 'khadem123', 'khadem');
await login('makhdoum@test.com', 'makhdoum123', 'makhdoum');
```

### 2. Logout Test
```javascript
const logout = async () => {
  try {
    await apiClient.post('/auth/logout');
    await AsyncStorage.removeItem('auth_token');
    await AsyncStorage.removeItem('user_data');
    return { success: true };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};
```

---

## 👤 User Management Testing

### 1. Get My Profile
```javascript
const getMyProfile = async () => {
  try {
    const response = await apiClient.get('/users/me');
    return { success: true, user: response.data };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};
```

### 2. Update Profile
```javascript
const updateProfile = async (profileData) => {
  try {
    const response = await apiClient.patch('/users/me', profileData);
    return { success: true, user: response.data };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};

// Test update
await updateProfile({
  phone: '+1234567890',
  additionalData: {
    address: '123 Main St',
    familyMembers: 4
  }
});
```

### 3. Upload Profile Image
```javascript
const uploadProfileImage = async (imageUri) => {
  try {
    const formData = new FormData();
    formData.append('image', {
      uri: imageUri,
      type: 'image/jpeg',
      name: 'profile.jpg',
    });

    const response = await apiClient.post('/users/me/profile-image', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });

    return { success: true, imageUrl: response.data.imageUrl };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};
```

### 4. List Users (Admin/Khadem only)
```javascript
const listUsers = async (role = null) => {
  try {
    const params = role ? { role } : {};
    const response = await apiClient.get('/users', { params });
    return { success: true, users: response.data };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};

// Test with different roles
await listUsers(); // All users
await listUsers('khadem'); // Only khadem users
await listUsers('makhdoum'); // Only makhdoum users
```

### 5. Create User (Admin only)
```javascript
const createUser = async (userData) => {
  try {
    const response = await apiClient.post('/users', userData);
    return { success: true, user: response.data };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};

// Test create user
await createUser({
  name: 'Test User',
  email: 'test@example.com',
  password: 'password123',
  phone: '+1234567890',
  role: 'makhdoum',
  additionalData: {
    address: 'Test Address',
    familyMembers: 2
  }
});
```

---

## 📅 Attendance Testing

### 1. List Attendance
```javascript
const listAttendance = async (filters = {}) => {
  try {
    const response = await apiClient.get('/attendance', { params: filters });
    return { success: true, attendance: response.data };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};

// Test different filters
await listAttendance(); // All attendance
await listAttendance({ type: 'mass' }); // Only mass attendance
await listAttendance({ date: '2024-01-15' }); // Specific date
await listAttendance({ userId: 'user-id' }); // Specific user (admin/khadem only)
```

### 2. Create Attendance
```javascript
const createAttendance = async (attendanceData) => {
  try {
    const response = await apiClient.post('/attendance', attendanceData);
    return { success: true, attendance: response.data };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};

// Test create attendance
await createAttendance({
  userId: 'user-id',
  userName: 'John Doe',
  type: 'mass',
  date: '2024-01-15',
  notes: 'Regular Sunday mass'
});
```

### 3. Update Attendance
```javascript
const updateAttendance = async (id, attendanceData) => {
  try {
    const response = await apiClient.put(`/attendance/${id}`, attendanceData);
    return { success: true, attendance: response.data };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};
```

### 4. Delete Attendance
```javascript
const deleteAttendance = async (id) => {
  try {
    const response = await apiClient.delete(`/attendance/${id}`);
    return { success: true };
  } catch (error) {
    return { success: false, error: error.response?.data?.message };
  }
};
```

---

## 🧪 Test Scenarios

### Scenario 1: Admin User Flow
```javascript
// 1. Login as admin
const adminLogin = await login('admin@test.com', 'admin123', 'admin');
console.log('Admin login:', adminLogin);

// 2. Create a new user
const newUser = await createUser({
  name: 'New User',
  email: 'newuser@test.com',
  password: 'password123',
  role: 'makhdoum'
});
console.log('User created:', newUser);

// 3. List all users
const allUsers = await listUsers();
console.log('All users:', allUsers);

// 4. Create attendance for any user
const attendance = await createAttendance({
  userId: newUser.user.id,
  userName: newUser.user.name,
  type: 'mass',
  date: '2024-01-15'
});
console.log('Attendance created:', attendance);
```

### Scenario 2: Khadem User Flow
```javascript
// 1. Login as khadem
const khademLogin = await login('khadem@test.com', 'khadem123', 'khadem');
console.log('Khadem login:', khademLogin);

// 2. Try to create user (should fail)
const createUserResult = await createUser({
  name: 'Test User',
  email: 'test@test.com',
  password: 'password123',
  role: 'makhdoum'
});
console.log('Create user (should fail):', createUserResult);

// 3. List users (should work)
const users = await listUsers();
console.log('List users:', users);

// 4. Create attendance (should work)
const attendance = await createAttendance({
  userId: khademLogin.user.id,
  userName: khademLogin.user.name,
  type: 'specialMeeting',
  date: '2024-01-15'
});
console.log('Attendance created:', attendance);
```

### Scenario 3: Makhdoum User Flow
```javascript
// 1. Login as makhdoum
const makhdoumLogin = await login('makhdoum@test.com', 'makhdoum123', 'makhdoum');
console.log('Makhdoum login:', makhdoumLogin);

// 2. Try to list users (should fail)
const usersResult = await listUsers();
console.log('List users (should fail):', usersResult);

// 3. Try to create attendance (should fail)
const createAttendanceResult = await createAttendance({
  userId: makhdoumLogin.user.id,
  userName: makhdoumLogin.user.name,
  type: 'mass',
  date: '2024-01-15'
});
console.log('Create attendance (should fail):', createAttendanceResult);

// 4. List attendance (should only show own records)
const myAttendance = await listAttendance();
console.log('My attendance:', myAttendance);

// 5. Update own profile (should work)
const updateResult = await updateProfile({
  phone: '+9876543210',
  additionalData: {
    address: 'Updated Address'
  }
});
console.log('Profile updated:', updateResult);
```

---

## 🔍 Error Handling Testing

### Test Common Error Cases
```javascript
// 1. Invalid credentials
const invalidLogin = await login('wrong@email.com', 'wrongpassword', 'admin');
console.log('Invalid login:', invalidLogin);

// 2. Missing token
// Remove token from storage and try protected endpoint
await AsyncStorage.removeItem('auth_token');
const noTokenResult = await getMyProfile();
console.log('No token request:', noTokenResult);

// 3. Insufficient permissions
// Login as makhdoum and try admin action
const makhdoumLogin = await login('makhdoum@test.com', 'makhdoum123', 'makhdoum');
const adminAction = await createUser({ name: 'Test' });
console.log('Permission denied:', adminAction);
```

---

## 📊 Testing Checklist

### Authentication
- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Token persistence
- [ ] Logout functionality
- [ ] Token expiration handling

### User Management
- [ ] Get own profile
- [ ] Update own profile
- [ ] Upload profile image
- [ ] List users (with permissions)
- [ ] Create user (admin only)
- [ ] Update user (with permissions)
- [ ] Delete user (admin only)

### Attendance Management
- [ ] List attendance (with filtering)
- [ ] Create attendance (with permissions)
- [ ] Update attendance (with permissions)
- [ ] Delete attendance (with permissions)
- [ ] Role-based data filtering

### Permission System
- [ ] Admin can do everything
- [ ] Khadem can manage attendance but not users
- [ ] Makhdoum can only view own data
- [ ] Proper error messages for denied access

### Error Handling
- [ ] Network errors
- [ ] Authentication errors
- [ ] Permission errors
- [ ] Validation errors
- [ ] Server errors

---

## 🚨 Common Issues & Solutions

### 1. CORS Issues
If you get CORS errors, make sure the backend has CORS enabled for your mobile app's origin.

### 2. Token Not Persisting
Make sure to store the token in AsyncStorage and add it to request headers.

### 3. Permission Denied
Check if the user has the required role and permissions for the action.

### 4. Network Timeout
Increase timeout settings in your HTTP client configuration.

### 5. File Upload Issues
Make sure to use FormData for file uploads and set correct Content-Type headers.

---

## 📞 Support

If you encounter any issues during testing, check:
1. Backend server is running
2. Database connection is working
3. All migrations are applied
4. Default data is seeded
5. Network connectivity
6. API endpoint URLs are correct

For additional help, contact the backend development team.