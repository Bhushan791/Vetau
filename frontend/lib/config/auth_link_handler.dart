import 'package:app_links/app_links.dart';
import 'package:frontend/config/auth_storage.dart';

class AuthLinkHandler {
  static final AppLinks _appLinks = AppLinks();

  static Future<void> init(Function onLoginSuccess) async {
    _appLinks.uriLinkStream.listen((uri) {
      processLink(uri, onLoginSuccess);
    });

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      processLink(initialUri, onLoginSuccess);
    }
  }

  // ✅ Rename method to public
  static void processLink(Uri uri, Function onLoginSuccess) {
    if (uri.scheme != "vetau" ||
        uri.host != "auth" ||
        uri.path != "/success") return;

    final accessToken = uri.queryParameters["accessToken"]!;
    final refreshToken = uri.queryParameters["refreshToken"]!;
    final userId = uri.queryParameters["userId"]!;

    AuthStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );

    onLoginSuccess();
  }
}
