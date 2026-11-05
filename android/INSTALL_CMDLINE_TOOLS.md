# Fix: "Android sdkmanager not found" / "cmdline-tools component is missing"

Your Android SDK is at **D:\SDK**. Flutter needs the **Android SDK Command-line Tools** there.

---

## Option A: Install via Android Studio (easiest)

1. Open **Android Studio**.
2. **File → Settings** (or **Android Studio → Settings** on Mac).
3. Go to **Languages & Frameworks → Android SDK**.
4. Open the **SDK Tools** tab.
5. Check **Android SDK Command-line Tools (latest)**.
6. Click **Apply** and wait for the install.
7. Confirm the **Android SDK location** is **D:\SDK** (Settings → Android SDK → Android SDK location). If it shows a different path, either change it to D:\SDK or set **ANDROID_HOME** to the path Android Studio uses.
8. In PowerShell run:
   ```powershell
   flutter doctor --android-licenses
   ```
   Accept all with `y`.

---

## Option B: Manual install (no Android Studio)

1. Download **Command line tools for Windows**:  
   https://developer.android.com/studio#command-line-tools-only  
   (e.g. **commandlinetools-win-11076708_latest.zip** or similar.)

2. Create the folder (if it doesn’t exist):
   ```powershell
   New-Item -ItemType Directory -Path "D:\SDK\cmdline-tools\latest" -Force
   ```

3. Unzip the downloaded file. Inside you’ll get a folder like **cmdline-tools** with **bin**, **lib**, etc.  
   Copy the contents of that folder (bin, lib, source.properties, etc.) into **D:\SDK\cmdline-tools\latest\**  
   so that you have:
   - **D:\SDK\cmdline-tools\latest\bin\sdkmanager.bat**
   - **D:\SDK\cmdline-tools\latest\bin\avdmanager.bat**
   - etc.

4. Set **ANDROID_HOME** (if not already set):
   ```powershell
   [System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "D:\SDK", "User")
   ```
   Then close and reopen PowerShell.

5. Run:
   ```powershell
   flutter doctor --android-licenses
   ```
   Accept all with `y`.

---

## Verify

```powershell
flutter doctor -v
```

You should no longer see "cmdline-tools component is missing" or "Android sdkmanager not found".
