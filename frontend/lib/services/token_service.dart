import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TokenService {
  static final TokenService _instance = TokenService._internal();

  factory TokenService() {
    return _instance;
  }

  TokenService._internal();

  static const String _accessTokenKey = 'accessToken';

  /// Save access token to SharedPreferences after login
  Future<void> saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    print('✅ Access token saved to SharedPreferences');
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Clear access token on logout
  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    print('✅ Access token cleared');
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Decode JWT token to check expiry
  Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      // Proper base64 padding
      String padded = payload;
      switch (padded.length % 4) {
        case 2:
          padded += '==';
          break;
        case 3:
          padded += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(padded));
      return jsonDecode(decoded);
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }

  /// Check if access token is expired
  Future<bool> isAccessTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;

    final payload = decodeToken(token);
    if (payload == null) return true;

    final exp = payload['exp'] as int?;
    if (exp == null) return true;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    // Refresh 5 minutes before actual expiry
    return DateTime.now().isAfter(expiryTime.subtract(Duration(minutes: 5)));
  }
}