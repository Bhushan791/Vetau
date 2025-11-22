import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'token_service.dart';

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
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final tokenService = TokenService();

    // Add cookies to request
    _addCookiesToRequest(request);

    // Check if access token is expired
    if (await tokenService.isAccessTokenExpired()) {
      print('🔄 Access token expired, refreshing...');
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
          _cookies[parts[0].trim()] = parts[1].trim();
          print('🍪 Stored cookie: ${parts[0].trim()}=${parts[1].trim()}');
        }
      }
    } else {
      print('🍪 No set-cookie header in response');
    }
  }

  /// Refresh access token using refresh token from cookies
  Future<bool> _refreshAccessToken() async {
    try {
      final tokenService = TokenService();

      print('🔄 Calling refresh endpoint...');

      // Create request with cookies
      final request = http.Request('POST', Uri.parse('$baseUrl/users/refresh-token/'));
      request.headers['Content-Type'] = 'application/json';
      _addCookiesToRequest(request);

      final response = await _inner.send(request);
      final responseBody = await response.stream.bytesToString();
      
      _storeCookiesFromResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final newAccessToken = data['data']['accessToken'];

        await tokenService.saveAccessToken(newAccessToken);
        print('✅ Access token refreshed successfully');

        return true;
      } else {
        print('❌ Failed to refresh: ${response.statusCode}');
        await tokenService.clearAccessToken();
        return false;
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
      return false;
    }
  }
}