import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String backendUrl = "http://10.0.2.2:8000";

  static const urlEmulator = "http://10.0.2.2:8000";
  static const urlLocalhost = "http://localhost:8000";

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    backendUrl = prefs.getString('backend_url') ?? urlEmulator;
  }

  static Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_url', url);
    backendUrl = url;
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backend_url');
    backendUrl = urlEmulator;
  }
}
