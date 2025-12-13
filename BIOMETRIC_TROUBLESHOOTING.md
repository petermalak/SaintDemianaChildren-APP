# Biometric Button Not Showing - Troubleshooting Guide

## Quick Diagnosis

If the fingerprint button is not showing, check the debug output in your console/logs. You should see messages like:

```
🔍 [LoginScreen] Checking biometric availability...
✅ [LoginScreen] Biometric is supported, checking availability...
📱 [LoginScreen] Biometric available: true/false
🔐 [LoginScreen] Has saved credentials: true/false
```

## Common Reasons Why Button Doesn't Show

### 1. **No Saved Credentials (Most Common)**
**Symptom:** Button doesn't appear on first login attempt

**Reason:** You must login with email/password at least ONCE before biometric login becomes available. This is required to save your credentials securely.

**Solution:**
1. Login with your email and password
2. After successful login, logout or close the app
3. Open the login screen again
4. The fingerprint button should now appear

### 2. **Biometric Not Enrolled on Device**
**Symptom:** Debug shows "Biometric available: false"

**Reason:** Your device doesn't have any fingerprints or face unlock enrolled

**Solution:**
1. Go to **Settings** → **Security** → **Biometric security**
2. Enroll at least one fingerprint or set up face unlock
3. Restart the app

### 3. **Device Doesn't Support Biometrics**
**Symptom:** Debug shows "Biometric not supported"

**Reason:** Your device doesn't have a fingerprint sensor or face unlock capability

**Solution:**
- Use a device with biometric support (Android 6.0+ with fingerprint/face unlock)
- Or use email/password login (which always works)

### 4. **App Permission Issues**
**Symptom:** Biometric check fails silently

**Reason:** Android permissions might not be properly configured

**Solution:**
- The `local_auth` package should handle permissions automatically
- Try uninstalling and reinstalling the app
- Check Android logs: `adb logcat | grep -i biometric`

## Step-by-Step Testing

### Step 1: Check Device Biometric Setup
```bash
# On your Android device:
Settings → Security → Biometric security
# Make sure at least one fingerprint/face is enrolled
```

### Step 2: First Login (Required)
1. Open the app
2. Login with **email and password**
3. Wait for successful login
4. **This step saves your credentials for biometric login**

### Step 3: Test Biometric Login
1. Logout or close the app completely
2. Open the app again (you should see login screen)
3. Look for the fingerprint button below the login form
4. If you see debug text, check the values:
   - `Checking=false` (should be false after check completes)
   - `Available=true` (should be true if everything is set up)

### Step 4: Check Logs
```bash
# Run app with verbose logging
flutter run --verbose

# Or check Android logs
adb logcat | grep -i "LoginScreen\|Biometric\|LoginCubit"
```

## Expected Behavior

### First Time (No Button)
- Login screen shows only email/password fields
- No fingerprint button visible
- This is **normal** - you need to login first

### After First Login (Button Appears)
- Login screen shows email/password fields
- **Fingerprint button appears** below the form
- Button says: "تسجيل الدخول بالبصمة"
- Tapping button triggers biometric authentication

## Debug Information

The app includes debug logging. Look for these messages in your console:

```
🔍 [LoginScreen] Checking biometric availability...
✅ [LoginScreen] Biometric is supported, checking availability...
📱 [LoginScreen] Biometric available: true
🔐 [LoginScreen] Has saved credentials: true
✅ [LoginScreen] Biometric login is available!
```

If you see:
- `Biometric available: false` → Enroll biometrics in device settings
- `Has saved credentials: false` → Login with email/password first
- `Biometric not supported` → Device doesn't support biometrics

## Manual Testing

You can also test the biometric service directly:

1. **Check if biometric is supported:**
   - The app checks this automatically
   - Should return `true` on Android devices with biometric sensors

2. **Check if biometric is available:**
   - Device must have at least one enrolled biometric
   - Check in device Settings → Security

3. **Check if credentials are saved:**
   - Only true after you've logged in with email/password at least once
   - Credentials are saved in encrypted storage after successful login

## Still Not Working?

1. **Clear app data and try again:**
   ```bash
   # On device: Settings → Apps → SaintDemiana → Storage → Clear Data
   # Or via adb:
   adb shell pm clear com.saint_demiana.services
   ```

2. **Reinstall the app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Check Android version:**
   - Minimum: Android 6.0 (API 23)
   - Recommended: Android 9.0+ (API 28+)

4. **Verify device has biometric sensor:**
   - Check device specifications
   - Test with another app that uses biometrics

## Contact for Help

If the issue persists after trying all steps:
1. Share the debug log output
2. Share your device model and Android version
3. Confirm you've completed first login with email/password

