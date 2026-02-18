import 'dart:typed_data';

/// No-op on non-web platforms.
void downloadFileOnWeb(Uint8List bytes, String fileName) {
  // Not used on mobile/desktop.
}
