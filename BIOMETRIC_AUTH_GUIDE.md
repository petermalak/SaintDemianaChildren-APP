# Biometric Authentication Guide for Android

## Prerequisites

### Device Requirements
- Android device running Android 6.0 (API level 23) or higher
- Device must have fingerprint sensor or face unlock capability
- At least one biometric method must be enrolled in device settings

### Setup Your Device
1. Go to **Settings** → **Security** → **Biometric security** (or **Fingerprint** / **Face unlock**)
2. Enroll at least one fingerprint or set up face unlock
3. Make sure biometric authentication is enabled on your device

## Building and Running the App

### Step 1: Connect Your Android Device
1. Enable **Developer Options** on your Android device:
   - Go to **Settings** → **About phone**
   - Tap **Build number** 7 times
   - Go back to **Settings** → **Developer options**
   - Enable **USB debugging**

2. Connect your device via USB cable
3. Verify connection:
   ```bash
   flutter devices
   ```
   You should see your device listed

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Run the App
```bash
flutter run
```

Or if you have multiple devices connected:
```bash
flutter run -d <device-id>
```

## Testing Biometric Authentication

### First Time Setup (Required)
1. **Launch the app** on your Android device
2. **Login with email and password** as you normally would
   - This is required the first time to save your credentials securely
   - After successful login, your credentials are automatically saved for biometric login

3. **Logout** from the app (if there's a logout option)

### Using Biometric Login
1. **Open the login screen** again
2. You should now see a **fingerprint icon button** below the login form
   - The button says: "تسجيل الدخول بالبصمة" (Login with fingerprint)
   - If you don't see this button, it means:
     - Your device doesn't support biometrics, OR
     - No biometric is enrolled, OR
     - You haven't logged in with email/password first

3. **Tap the fingerprint button**
4. **Authenticate** using your fingerprint or face unlock
   - The system biometric dialog will appear
   - Place your finger on the sensor or look at the camera
   - Wait for authentication to complete

5. **You should be automatically logged in** after successful biometric authentication

## Troubleshooting

### Biometric Button Not Showing
**Possible causes:**
- Device doesn't support biometric authentication
- No biometric method is enrolled in device settings
- You haven't logged in with email/password first (required to save credentials)

**Solution:**
1. Check if your device has fingerprint/face unlock in Settings
2. Enroll a biometric in device settings
3. Login once with email/password to save credentials

### Authentication Fails
**Possible causes:**
- Fingerprint/face not recognized
- Too many failed attempts
- Biometric sensor issue

**Solution:**
1. Try again with the enrolled fingerprint/face
2. Use your device's PIN/pattern as fallback if prompted
3. If persistent, login with email/password instead

### App Crashes on Biometric Login
**Possible causes:**
- Missing permissions (should be automatic)
- Corrupted secure storage

**Solution:**
1. Clear app data: **Settings** → **Apps** → **SaintDemiana** → **Storage** → **Clear Data**
2. Reinstall the app
3. Login again with email/password first

## How It Works

1. **First Login**: When you login with email/password, the app securely saves your credentials using Android's encrypted storage (EncryptedSharedPreferences)

2. **Biometric Check**: On the login screen, the app checks:
   - If biometric authentication is supported
   - If biometric authentication is available on the device
   - If credentials are saved

3. **Biometric Authentication**: When you tap the fingerprint button:
   - Android's biometric prompt appears
   - You authenticate with fingerprint/face
   - If successful, the app retrieves saved credentials
   - Automatically logs you in

4. **Security**: 
   - Credentials are encrypted using Android's secure storage
   - Biometric authentication is required before accessing credentials
   - Credentials are only stored on your device (never sent to server)

## Notes

- **Web version**: Biometric authentication is NOT available on web - only email/password login
- **iOS**: Works the same way but uses Face ID or Touch ID
- **Security**: Your password is stored encrypted on your device only
- **Privacy**: Biometric data never leaves your device - Android handles it securely

## Testing Checklist

- [ ] Device has biometric authentication enabled
- [ ] At least one fingerprint/face is enrolled
- [ ] App is installed and running
- [ ] First login with email/password successful
- [ ] Biometric button appears on login screen
- [ ] Biometric authentication prompt appears
- [ ] Authentication successful
- [ ] Automatic login works after biometric authentication

