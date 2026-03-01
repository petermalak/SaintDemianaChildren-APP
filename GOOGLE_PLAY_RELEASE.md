# Google Play Release – AAB & Release Notes

## 1. Build the Android App Bundle (AAB)

From the Flutter project folder:

```powershell
cd "d:\Projects\SaintDemiana APP\SaintDemianaChildren"
flutter build appbundle
```

- **Output:** `build\app\outputs\bundle\release\app-release.aab`
- First build can take 5–10+ minutes (Gradle). Later builds are faster.

### Release signing (required for Play Store)

The project is set up to use **keystore.properties** for release signing. Create this file if you don’t have it:

**File:** `SaintDemianaChildren/android/keystore.properties`

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=path/to/your/upload-keystore.jks
```

- `storeFile` is relative to the `android` folder (e.g. `upload-keystore.jks` if the file is in `android/`).
- Use the same keystore you used for previous Play Store uploads. If this is your first upload, create a keystore and keep it safe.

---

## 2. Release notes for Google Play Console

Use the contents of **`release_notes_1.0.6.txt`** when Google Play asks for “Release notes” (or copy below).

You can paste the full text or shorten as needed. Play Console allows a short and a long version; you can use the Arabic section as the main text and the English as optional.

### Short version (for “Short description” if needed)

```
الإصدار 1.0.6: متجر التايو (إضافة هدية لعدة فصول)، تحديث إلزامي من الخادم، إصلاح رفع الصور على الويب، وإشعارات المتجر.
```

### Full version (in release_notes_1.0.6.txt)

The file **release_notes_1.0.6.txt** in the project root contains the full Arabic + English release notes. Open it and copy the text into the Play Console “Release notes” field.

---

## 3. Upload to Google Play Console

1. Open [Google Play Console](https://play.google.com/console) → your app.
2. **Release** → **Production** (or **Testing** if you use a track).
3. **Create new release**.
4. Upload **`app-release.aab`** from `build\app\outputs\bundle\release\`.
5. In **Release notes**, paste the text from **release_notes_1.0.6.txt** (or the short version above).
6. Save and send the release for review.

---

## Current version (pubspec.yaml)

- **Version name:** 1.0.6  
- **Version code (build number):** 6  

After publishing, for the next release increase both in `pubspec.yaml` (e.g. `1.0.7+7`) and create a new release notes file.
