/// Stub implementation of ShorebirdCodePush for web platform
/// Shorebird doesn't support web, so this provides a no-op implementation
class ShorebirdCodePush {
  ShorebirdCodePush();

  Future<void> initialize() async {
    // No-op on web
  }

  Future<bool> isNewPatchAvailableForDownload() async {
    return false;
  }

  Future<void> downloadUpdateIfAvailable() async {
    // No-op on web
  }

  Future<int> currentPatchNumber() async {
    return 0;
  }
}

