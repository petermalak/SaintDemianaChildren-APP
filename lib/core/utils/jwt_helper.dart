import 'dart:convert';

class JwtHelper {
  /// Decode JWT token and extract payload
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      if (payloadMap is! Map<String, dynamic>) {
        return null;
      }

      return payloadMap;
    } catch (e) {
      print('Error decoding JWT: $e');
      return null;
    }
  }

  /// Extract classId from JWT token
  static String? extractClassIdFromToken(String? token) {
    if (token == null) return null;

    final payload = decodeToken(token);
    if (payload == null) return null;

    // Try classMemberships array
    if (payload['classMemberships'] != null &&
        payload['classMemberships'] is List) {
      final memberships = payload['classMemberships'] as List;
      if (memberships.isNotEmpty &&
          memberships[0] != null &&
          memberships[0]['classId'] != null) {
        return memberships[0]['classId'] as String;
      }
    }

    // Try direct classId
    return payload['classId'] as String?;
  }
}
