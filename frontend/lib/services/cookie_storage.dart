import 'package:cookie_jar/cookie_jar.dart';

class CookieStorage {
  static final CookieJar cookieJar = CookieJar();

  static Future<void> saveCookies(Uri uri, List<String> setCookie) async {
    final cookies = setCookie.map((e) => Cookie.fromSetCookieValue(e)).toList();
    await cookieJar.saveFromResponse(uri, cookies);
  }

  static Future<List<Cookie>> loadCookies(Uri uri) async {
    return cookieJar.loadForRequest(uri);
  }

  static Future<void> clear() async {
    await cookieJar.deleteAll();
  }
}
