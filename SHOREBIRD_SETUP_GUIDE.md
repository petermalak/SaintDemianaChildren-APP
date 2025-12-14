# Shorebird OTA Updates Setup Guide

## Overview

Shorebird has been integrated into your app for Over-The-Air (OTA) updates. This allows you to push updates to your app without going through app stores.

## Features Implemented

✅ **Update Service** - Checks for and downloads updates
✅ **Force Update** - Option to force users to update
✅ **Update Dialogs** - Beautiful UI for update notifications
✅ **Automatic Checking** - Checks for updates on app start
✅ **Background Updates** - Non-blocking update checks

## Initial Setup

### 1. Install Shorebird CLI

**Windows (using winget):**
```bash
winget install --id Shorebird.Shorebird -e
```

**Windows (using PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/shorebirdtech/shorebird/main/bin/install.ps1 | iex"
```

**macOS/Linux:**
```bash
curl -L https://raw.githubusercontent.com/shorebirdtech/shorebird/main/bin/install.sh | bash
```

**Alternative (if above doesn't work):**
Download the latest release from: https://github.com/shorebirdtech/shorebird/releases

After installation, verify it works:
```bash
shorebird --version
```

### 2. Login to Shorebird

```bash
shorebird login
```

### 3. Initialize Shorebird in Your Project

```bash
cd SaintDemianaChildren
shorebird init
```

This will:
- Create a `shorebird.yaml` configuration file
- Set up your app for Shorebird updates

### 4. Get Your App ID

After initialization, you'll get an app ID. This is used to identify your app in Shorebird.

## Building with Shorebird

### First Release Build

```bash
# Build release with Shorebird
shorebird release android
# or
shorebird release ios
```

This creates the initial release that users will download from app stores.

### Creating Patches (OTA Updates)

After making code changes:

```bash
# Create a patch
shorebird patch android
# or
shorebird patch ios
```

This creates an OTA patch that will be downloaded by users automatically.

## Force Update Configuration

To enable force updates, you have two options:

### Option 1: Backend API Integration

Modify `UpdateService.isForceUpdateRequired()` to check your backend API:

```dart
@override
Future<bool> isForceUpdateRequired() async {
  // Call your backend API to check if force update is required
  // Example:
  // final response = await _apiService.get('/app/force-update');
  // return response.data['forceUpdate'] == true;
  
  return false; // Change based on your API response
}
```

### Option 2: Patch Number Based

Modify the logic in `UpdateService.isForceUpdateRequired()`:

```dart
final currentPatch = await getCurrentPatchNumber();
// If patch difference is significant, force update
if (currentPatch != null && patchNumber > currentPatch + 5) {
  return true; // Force update
}
```

## How It Works

1. **App Start**: App checks for updates automatically
2. **Update Available**: If update is found, dialog is shown
3. **Force Update**: If marked as force update, user cannot dismiss
4. **Download**: Update is downloaded in background
5. **Apply**: App restarts with new patch automatically

## Update Dialog Types

### Optional Update
- User can dismiss the dialog
- "لاحقاً" (Later) button available
- User can continue using the app

### Force Update
- Dialog cannot be dismissed
- No "Later" button
- User must update to continue

## Testing Updates

### 1. Create Initial Release

```bash
shorebird release android
```

### 2. Install on Device

Install the release build on your device.

### 3. Make Code Changes

Make any code changes you want to push.

### 4. Create Patch

```bash
shorebird patch android
```

### 5. Test Update

Open the app on your device. The update should be detected and the dialog should appear.

## Configuration Files

### shorebird.yaml

Created by `shorebird init`, contains:
- App ID
- Platform configurations
- Update settings

### Update Service

Located at: `lib/core/services/update_service.dart`

Key methods:
- `checkForUpdate()` - Checks if update is available
- `downloadUpdate()` - Downloads and applies update
- `isForceUpdateRequired()` - Determines if update is mandatory

## Best Practices

1. **Test Patches Thoroughly**: Always test patches before releasing
2. **Version Control**: Keep track of patch numbers
3. **Backend Integration**: Use backend API for force update flags
4. **User Communication**: Provide clear release notes
5. **Gradual Rollout**: Use Shorebird's rollout features for staged releases

## Troubleshooting

### Update Not Showing

1. Check if patch was created successfully
2. Verify app is connected to internet
3. Check Shorebird dashboard for patch status
4. Verify app ID matches in `shorebird.yaml`

### Force Update Not Working

1. Check `isForceUpdateRequired()` logic
2. Verify backend API (if using)
3. Check patch metadata

### Update Download Fails

1. Check internet connection
2. Verify Shorebird service is accessible
3. Check app logs for errors

## Production Checklist

- [ ] Shorebird CLI installed and logged in
- [ ] `shorebird.yaml` configured
- [ ] Initial release built with Shorebird
- [ ] Force update logic configured
- [ ] Update dialogs tested
- [ ] Backend API integrated (if using)
- [ ] Update flow tested end-to-end

## Additional Resources

- [Shorebird Documentation](https://docs.shorebird.dev/)
- [Shorebird CLI Reference](https://docs.shorebird.dev/reference/cli)
- [Shorebird Dashboard](https://shorebird.dev/)

## Support

For issues or questions:
1. Check Shorebird documentation
2. Review app logs
3. Check Shorebird dashboard
4. Contact Shorebird support

