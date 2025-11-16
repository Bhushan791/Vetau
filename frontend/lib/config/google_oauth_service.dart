import 'package:flutter/material.dart';
import 'package:frontend/config/google_webview_page.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleOAuthService {
  static final Uri _googleAuthUrl = Uri.parse(
    "https://denice-syncretistical-charline.ngrok-free.dev/api/v1/users/google",
  );

  static void openGoogleLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GoogleWebViewPage(authUrl: _googleAuthUrl),
      ),
    );
  }
}

