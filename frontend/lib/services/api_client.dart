import 'package:frontend/services/cookie_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}

class ApiClient extends http.BaseClient {
  final String baseUrl;
  final Function(BuildContext) onSessionExpired;
  final http.Client _inner = http.Client();
  static final Map<String, String> _cookies = {};

  ApiClient({
    required this.baseUrl,
    required this.onSessionExpired,
  }) {
    _loadCookiesFromStorage();
  }

  /// Load cookies from CookieStorage into static map
  Future<void> _loadCookiesFromStorage() async {
    try {
      final uri = Uri.parse(baseUrl);
      final cookies = await CookieStorage.loadCookies(uri);
      for (final cookie in cookies) {
        _cookies[cookie.name] = cookie.value;
        print('🍪 Loaded cookie from storage: ${cookie.name}=${cookie.value}');
      }
      
      // Also load refresh token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken != null) {
        _cookies['refreshToken'] = refreshToken;
        print('🍪 Loaded refresh token from SharedPreferences');
      }
    } catch (e) {
      print('❌ Error loading cookies from storage: $e');
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final tokenService = TokenService();

    // Add cookies to request
    _addCookiesToRequest(request);

    // Check if access token is expired
    if (await tokenService.isAccessTokenExpired()) {
      print('🔄 Access token expired, refreshing...');
      if (!_cookies.containsKey('refreshToken')) {
        print('❌ No refresh token available, clearing session');
        await tokenService.clearAccessToken();
        throw UnauthorizedException('Session expired. Please login again.');
      }
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        throw UnauthorizedException('Session expired. Please login again.');
      }
    }

    // Add access token to Authorization header
    final accessToken = await tokenService.getAccessToken();
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    print('📤 Sending request to: ${request.url}');
    var response = await _inner.send(request);

    // Store cookies from response
    _storeCookiesFromResponse(response);

    // If 401, attempt refresh and retry
    if (response.statusCode == 401) {
      print('⚠️ 401 Unauthorized - attempting token refresh');
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        final newAccessToken = await tokenService.getAccessToken();
        if (newAccessToken != null) {
          // Create a new request with the same properties
          final newRequest = _copyRequest(request);
          _addCookiesToRequest(newRequest);
          newRequest.headers['Authorization'] = 'Bearer $newAccessToken';
          response = await _inner.send(newRequest);
          _storeCookiesFromResponse(response);
        }
      }
    }

    return response;
  }

  /// Helper function to copy a request
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;

    if (request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('Cannot copy a StreamedRequest');
    } else {
      throw Exception('Cannot copy an unknown request type: $request');
    }

    requestCopy
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return requestCopy;
  }

  void _addCookiesToRequest(http.BaseRequest request) {
    if (_cookies.isNotEmpty) {
      final cookieHeader = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
      request.headers['Cookie'] = cookieHeader;
      print('🍪 Adding cookies to request: $cookieHeader');
    } else {
      print('🍪 No cookies to add to request');
    }
  }

  void _storeCookiesFromResponse(http.StreamedResponse response) {
    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders != null) {
      print('🍪 Received set-cookie header: $setCookieHeaders');
      final cookies = setCookieHeaders.split(',');
      for (final cookie in cookies) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) {
          final cookieName = parts[0].trim();
          final cookieValue = parts[1].trim();
          _cookies[cookieName] = cookieValue;
          print('🍪 Stored cookie: $cookieName=$cookieValue');
          
          // Save refresh token to SharedPreferences
          if (cookieName == 'refreshToken') {
            _saveRefreshTokenToPrefs(cookieValue);
          }
        }
      }
      
      // Also save to persistent storage
      _saveCookiesToStorage(setCookieHeaders);
    } else {
      print('🍪 No set-cookie header in response');
    }
  }
  
  /// Save refresh token to SharedPreferences
  Future<void> _saveRefreshTokenToPrefs(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', refreshToken);
      print('🍪 Refresh token saved to SharedPreferences');
    } catch (e) {
      print('❌ Error saving refresh token: $e');
    }
  }

  /// Save cookies to persistent storage
  Future<void> _saveCookiesToStorage(String setCookieHeader) async {
    try {
      final uri = Uri.parse(baseUrl);
      await CookieStorage.saveCookies(uri, [setCookieHeader]);
      print('🍪 Cookies saved to persistent storage');
    } catch (e) {
      print('❌ Error saving cookies to storage: $e');
    }
  }

  /// Refresh access token using refresh token from cookies
Future<bool> _refreshAccessToken() async {
  final uri = Uri.parse('$baseUrl/users/refresh-token');

  try {
    final tokenService = TokenService();

    print('🔄 Refreshing access token...');

    // Use static cookies map
    final cookieHeader = _cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');

    print('🍪 Using cookies for refresh: $cookieHeader');

    final response = await http.post(
      uri,
      headers: {
        if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        "Content-Type": "application/json",
      },
    );

    print('🔄 Refresh response status: ${response.statusCode}');
    print('🔄 Refresh response body: ${response.body}');

    // Store cookies from refresh response
    _storeCookiesFromResponse(http.StreamedResponse(
      http.ByteStream.fromBytes(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    ));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final newAccessToken = json['data']['accessToken'];

      await tokenService.saveAccessToken(newAccessToken);

      print("✅ Access token refreshed");
      return true;
    } else {
      print("❌ Refresh failed: ${response.statusCode}");
      await tokenService.clearAccessToken();
      return false;
    }
  } catch (e) {
    print("❌ Exception during refresh: $e");
    return false;
  }
}

}