import 'dart:convert';

class JwtHelper {
  /// Default buffer: consider token expired this many seconds before actual exp
  static const int expiryBufferSeconds = 60;

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
      final decoded = json.decode(resp);
      if (decoded is! Map) {
        return null;
      }
      return Map<String, dynamic>.from(decoded);
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

  /// Parses JWT `exp` claim (seconds since epoch). Returns null if missing or invalid.
  static int? _expiryUnixSeconds(Map<String, dynamic> payload) {
    final exp = payload['exp'];
    if (exp == null) return null;
    if (exp is int) return exp;
    if (exp is num) return exp.toInt();
    if (exp is String) return int.tryParse(exp);
    return null;
  }

  /// Reads the JWT `iat` claim as a [DateTime]. Returns null if missing or invalid.
  static DateTime? issuedAt(String? token) {
    if (token == null || token.isEmpty) return null;
    final payload = decodeToken(token);
    final iat = payload?['iat'];
    final seconds = iat is num ? iat.toInt() : int.tryParse('$iat');
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  /// Returns true only when we can read a well-formed JWT with [exp] and that time has passed.
  ///
  /// If the string is not a JWT, has no [exp], or cannot be decoded, returns **false** so we do
  /// not clear a valid session locally; the API still returns 401 when the token is invalid.
  /// Uses [expiryBufferSeconds] so we treat the token as expired shortly before actual exp.
  static bool isExpired(String? token) {
    if (token == null || token.isEmpty) return true;
    final payload = decodeToken(token);
    if (payload == null) return false;
    final expSeconds = _expiryUnixSeconds(payload);
    if (expSeconds == null) return false;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds >= (expSeconds - expiryBufferSeconds);
  }
}
