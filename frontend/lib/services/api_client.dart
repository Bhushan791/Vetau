import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
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

  ApiClient({
    required this.baseUrl,
    required this.onSessionExpired,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final tokenService = TokenService();

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

    // If 401, attempt refresh and retry
    if (response.statusCode == 401) {
      print('⚠️ 401 Unauthorized - attempting token refresh');
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        final newAccessToken = await tokenService.getAccessToken();
        if (newAccessToken != null) {
          // Create a new request with the same properties
          final newRequest = _copyRequest(request);
          newRequest.headers['Authorization'] = 'Bearer $newAccessToken';
          response = await _inner.send(newRequest);
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

  /// Refresh access token using refresh token from cookies
  Future<bool> _refreshAccessToken() async {
    try {
      final tokenService = TokenService();

      print('🔄 Calling refresh endpoint...');

      // Call the refresh endpoint
      // http package sends refresh token cookie automatically
      final response = await _inner.post(
        Uri.parse('$baseUrl/users/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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