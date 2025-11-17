import 'dart:convert';
import 'package:frontend/services/authService.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://vetau.onrender.com/api/v1";

  /// Handles GET, POST, PUT, DELETE with auto refreshing
  static Future<http.Response> sendRequest(
    String path, {
    String method = "GET",
    Map<String, String>? headers,
    dynamic body,
    bool retry = true,
  }) async {
    final String? accessToken = await AuthService.getAccessToken();

    final requestHeaders = {
      "Accept": "application/json",
      "Content-Type": "application/json",
      if (accessToken != null) "Authorization": "Bearer $accessToken",
      ...?headers,
    };

    final url = Uri.parse("$baseUrl$path");

    late http.Response response;

    if (method == "POST") {
      response = await http.post(url, headers: requestHeaders, body: jsonEncode(body));
    } else if (method == "PUT") {
      response = await http.put(url, headers: requestHeaders, body: jsonEncode(body));
    } else if (method == "DELETE") {
      response = await http.delete(url, headers: requestHeaders);
    } else {
      response = await http.get(url, headers: requestHeaders);
    }

    // If token expired, refresh & retry once
    if (response.statusCode == 401 &&
        response.body.contains("jwt expired") &&
        retry) {
      print("🔐 Token expired — refreshing...");

      bool refreshed = await AuthService.refreshAccessToken();

      if (refreshed) {
        return sendRequest(path,
            method: method, headers: headers, body: body, retry: false);
      }
    }

    return response;
  }
}
