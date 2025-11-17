import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "https://vetau.onrender.com/api/v1";

  /// Save tokens to SharedPreferences
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  /// Get the saved access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  /// Get the saved refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  /// Refresh access token when expired
  static Future<bool> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) return false;

    final url = Uri.parse("$baseUrl/auth/refresh-token");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refreshToken": refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      await saveTokens(
        data["accessToken"],
        data["refreshToken"],
      );

      print("🔄 Access token refreshed successfully.");
      return true;
    }

    print("❌ Failed to refresh token: ${response.body}");
    return false;
  }
}
