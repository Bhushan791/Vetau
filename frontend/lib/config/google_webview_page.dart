import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'auth_link_handler.dart';

class GoogleWebViewPage extends StatefulWidget {
  final Uri authUrl;

  const GoogleWebViewPage({super.key, required this.authUrl});

  @override
  State<GoogleWebViewPage> createState() => _GoogleWebViewPageState();
}

class _GoogleWebViewPageState extends State<GoogleWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);

            // Check if this is your deep link
            if (uri.scheme == "vetau" && uri.host == "auth") {
              AuthLinkHandler.processLink(uri, () {
                Navigator.pop(context); // close WebView
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google login successful!')),
                );
              });
              return NavigationDecision.prevent; // stop navigation
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(widget.authUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Google Sign In")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
