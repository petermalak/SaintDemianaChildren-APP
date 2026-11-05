# SaintDemiana Release Build Information

## Release APK Location
Your release APK has been successfully built at:
```
build\app\outputs\flutter-apk\app-release.apk (27.0MB)
```

## App Configuration
- **App Name**: SaintDemiana
- **Application ID**: com.saint_demiana.services
- **Version**: 1.0.0+1
- **Build Type**: Release (Signed)

## Signing Configuration
- **Keystore File**: `android/saint-demiana-release-key.jks`
- **Keystore Properties**: `android/keystore.properties`
- **Key Alias**: saint-demiana
- **Passwords**: saintdemiana2025 (both store and key)
- **Validity**: 10,000 days (~27 years)

## Important Security Notes
⚠️ **KEEP THESE FILES SECURE**:
- `android/saint-demiana-release-key.jks` - Your signing keystore
- `android/keystore.properties` - Contains passwords
- **Never commit these files to version control**
- **Backup them securely** - you need the same keystore for all future updates

Add these to your `.gitignore`:
```
android/saint-demiana-release-key.jks
android/keystore.properties
```

## Next Steps for Google Play Release

### 1. Test the APK
Install and test the APK on a real device:
```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

### 2. Build App Bundle (Recommended for Google Play)
Google Play prefers AAB (Android App Bundle) format:
```bash
flutter build appbundle --release
```
This will create: `build\app\outputs\bundle\release\app-release.aab`

### 3. Google Play Console Setup
1. Go to https://play.google.com/console
2. Create a new application
3. Fill in all required information:
   - App name: SaintDemiana
   - Category: Education or Lifestyle
   - Content rating
   - Privacy policy
   - Screenshots and graphics
4. Upload the AAB file

### 4. Future Updates
For updates, increment the version in `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Format: versionName+versionCode
```
Always use the same keystore for updates!

## Build Configuration

### Current Settings
- **Code Shrinking**: Disabled (to avoid R8 issues)
- **Resource Shrinking**: Disabled
- **Target SDK**: Latest Flutter default
- **Min SDK**: Flutter minimum

### To Enable Code Shrinking (Optional)
If you want to reduce APK size, you'll need to:
1. Add Play Core library dependency
2. Update ProGuard rules properly
3. Test thoroughly after enabling

## Build Commands Reference

### Build APK
```bash
flutter build apk --release
```

### Build App Bundle (for Google Play)
```bash
flutter build appbundle --release
```

### Build Split APKs (smaller downloads)
```bash
flutter build apk --release --split-per-abi
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## Troubleshooting

### If build fails
1. Run `flutter clean`
2. Run `flutter pub get`
3. Try building again

### If signing fails
Check that:
- `keystore.properties` exists in `android/` folder
- `saint-demiana-release-key.jks` exists in `android/` folder
- File paths in `keystore.properties` are correct

## App Permissions
The app requests the following permissions:
- `CALL_PHONE` - For calling church members
- `INTERNET` - For backend communication
- `POST_NOTIFICATIONS` - For Firebase notifications (Android 13+)

Make sure to document these in your Google Play listing!

