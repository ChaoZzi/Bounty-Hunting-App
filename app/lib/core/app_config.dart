import 'package:shared_preferences/shared_preferences.dart';

/// 全局配置：服务器地址可在 App 内修改，避免 IP 变了要重新打包。
class AppConfig {
  static const String _kBaseUrl = 'base_url';
  static const String _kToken = 'token';
  static const String _kNickname = 'nickname';

  /// 编译期默认值：flutter build apk --dart-define=API_BASE=http://192.168.1.23:8080
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static late SharedPreferences _prefs;

  static String baseUrl = _defaultBaseUrl;
  static String? token;
  static String? nickname;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    baseUrl = _prefs.getString(_kBaseUrl) ?? _defaultBaseUrl;
    token = _prefs.getString(_kToken);
    nickname = _prefs.getString(_kNickname);
  }

  static Future<bool> hasToken() async => token != null && token!.isNotEmpty;

  static Future<void> setBaseUrl(String url) async {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await _prefs.setString(_kBaseUrl, baseUrl);
  }

  static Future<void> saveLogin(String t, String name) async {
    token = t;
    nickname = name;
    await _prefs.setString(_kToken, t);
    await _prefs.setString(_kNickname, name);
  }

  static Future<void> logout() async {
    token = null;
    nickname = null;
    await _prefs.remove(_kToken);
    await _prefs.remove(_kNickname);
  }
}
