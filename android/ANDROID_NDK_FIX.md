# Fix: "Release app bundle failed to strip debug symbols from native libraries"

The AAB build needs the **Android NDK** so it can strip debug symbols from native libraries. If the NDK is missing or the wrong version, the build fails.

## Option 1: Install NDK via Android Studio (recommended)

1. Open **Android Studio**.
2. **File → Settings** (or **Android Studio → Settings** on Mac).
3. **Languages & Frameworks → Android SDK**.
4. Open the **SDK Tools** tab.
5. Check **NDK (Side by side)** and ensure a version is installed (e.g. **27.0.12077973** or the latest).
6. If needed, check **Show Package Details** and select the version that matches your project (or use the latest).
7. Click **Apply** and wait for the install.
8. In a terminal, run:
   ```powershell
   flutter doctor --android-licenses
   ```
   Accept all licenses.
9. Then:
   ```powershell
   cd "d:\Projects\SaintDemiana APP\SaintDemianaChildren"
   flutter clean
   flutter pub get
   flutter build appbundle
   ```

## Option 2: Restore ndkVersion (if you need a specific version)

If the build still fails and you have NDK **27.0.12077973** installed, restore the version in `app/build.gradle.kts`:

- Uncomment the line: `ndkVersion = "27.0.12077973"`

## Option 3: Build release APK and upload that (temporary)

Google Play accepts **APK** for internal testing (and in some cases for production). You can use a release APK while fixing NDK:

```powershell
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Note: For production, Play Store prefers AAB. Fixing NDK (Option 1) is the right long-term solution.
