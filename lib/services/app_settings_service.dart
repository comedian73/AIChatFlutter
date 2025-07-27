import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  late SharedPreferences _prefs;

  static const String _isFirstLaunchKey = 'isFirstLaunch';
  static const String _openRouterApiKey = 'OPENROUTER_API_KEY';
  static const String _baseUrlKey = 'BASE_URL';
  static const String _debugKey = 'DEBUG';
  static const String _logLevelKey = 'LOG_LEVEL';
  static const String _maxTokensKey = 'MAX_TOKENS';
  static const String _temperatureKey = 'TEMPERATURE';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    bool isFirstLaunch = _prefs.getBool(_isFirstLaunchKey) ?? true;

    if (isFirstLaunch) {
      await dotenv.load(fileName: ".env");

      _prefs.setString(_openRouterApiKey, dotenv.env[_openRouterApiKey] ?? '');
      _prefs.setString(_baseUrlKey, dotenv.env[_baseUrlKey] ?? '');
      _prefs.setBool(_debugKey, dotenv.env[_debugKey]?.toLowerCase() == 'true');
      _prefs.setString(_logLevelKey, dotenv.env[_logLevelKey] ?? '');
      _prefs.setInt(
          _maxTokensKey, int.tryParse(dotenv.env[_maxTokensKey] ?? '') ?? 1000);
      _prefs.setDouble(_temperatureKey,
          double.tryParse(dotenv.env[_temperatureKey] ?? '') ?? 0.7);

      await _prefs.setBool(_isFirstLaunchKey, false);
    }
  }

  String get openRouterApiKey => _prefs.getString(_openRouterApiKey) ?? '';
  String get baseUrl => _prefs.getString(_baseUrlKey) ?? '';
  bool get debugMode => _prefs.getBool(_debugKey) ?? false;
  String get logLevel => _prefs.getString(_logLevelKey) ?? 'INFO';
  int get maxTokens => _prefs.getInt(_maxTokensKey) ?? 1000;
  double get temperature => _prefs.getDouble(_temperatureKey) ?? 0.7;

  Future<void> setOpenRouterApiKey(String apiKey) async {
    await _prefs.setString(_openRouterApiKey, apiKey);
  }

  Future<void> setBaseUrl(String baseUrl) async {
    await _prefs.setString(_baseUrlKey, baseUrl);
  }
}
