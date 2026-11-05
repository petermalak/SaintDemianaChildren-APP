import 'dart:io';

/// IO implementation: uses [InternetAddress.lookup] and [SocketException].
/// Used only when dart.library.io is available (mobile, desktop).
Future<bool> checkNetworkConnectivity() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 15));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  }
}
