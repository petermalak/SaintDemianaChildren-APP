# Fix: INSTALL_FAILED_UPDATE_INCOMPATIBLE / INSTALL_FAILED_USER_RESTRICTED

## 1. Signature mismatch (INSTALL_FAILED_UPDATE_INCOMPATIBLE)

The app on your device was installed with a **different signing key** (e.g. from Play Store or another machine). You must **uninstall the old app** first, then install the new build.

### Option A – On the device
- Open **Settings → Apps** (or **Applications**), find **Saint Demiana** (or the app name), tap **Uninstall**.

### Option B – Using ADB
```bash
adb -s 351c68870721 uninstall com.saint_demiana.services
```

Then run again:
```bash
flutter run -d 351c68870721
```

---

## 2. Install blocked by device (INSTALL_FAILED_USER_RESTRICTED)

“Install canceled by user” often means the device (e.g. Xiaomi M2010J19SG) is blocking USB installs.

- **Allow USB installs**
  - **Settings → Additional settings → Developer options**
  - Enable **“Install via USB”** (or **“USB debugging (Security settings)”** on MIUI).
- When you run `flutter run`, check the **device screen** for an “Install?” or “Allow?” prompt and tap **Allow**.
- On some Xiaomi/Redmi devices:
  - **Settings → Passwords & security → Privacy** (or **Special app access**)
  - Find **“Install via USB”** or **“Install unknown apps”** and allow it for **USB** or your PC.

After uninstalling the old app and enabling USB install, run:

```bash
flutter run -d 351c68870721
```
