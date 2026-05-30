import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  late SharedPreferences _prefs;
  final Logger _logger = Logger();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _logger.i('Storage service initialized');
    } catch (e) {
      _logger.e('Error initializing storage: $e');
      rethrow;
    }
  }

  Future<void> setApiKey(String key) async {
    try {
      await _prefs.setString('grok_api_key', key);
      _logger.i('API key saved');
    } catch (e) {
      _logger.e('Error saving API key: $e');
      rethrow;
    }
  }

  String? getApiKey() {
    try {
      return _prefs.getString('grok_api_key');
    } catch (e) {
      _logger.e('Error retrieving API key: $e');
      return null;
    }
  }

  Future<void> setAutoStart(bool enabled) async {
    try {
      await _prefs.setBool('auto_start', enabled);
      _logger.i('Auto start set to: $enabled');
    } catch (e) {
      _logger.e('Error setting auto start: $e');
      rethrow;
    }
  }

  bool getAutoStart() {
    try {
      return _prefs.getBool('auto_start') ?? true;
    } catch (e) {
      _logger.e('Error getting auto start: $e');
      return false;
    }
  }

  Future<void> saveCommandHistory(List<String> history) async {
    try {
      await _prefs.setStringList('command_history', history);
    } catch (e) {
      _logger.e('Error saving command history: $e');
      rethrow;
    }
  }

  List<String> getCommandHistory() {
    try {
      return _prefs.getStringList('command_history') ?? [];
    } catch (e) {
      _logger.e('Error retrieving command history: $e');
      return [];
    }
  }

  Future<void> setSelectedModel(String model) async {
    try {
      await _prefs.setString('selected_model', model);
    } catch (e) {
      _logger.e('Error saving model: $e');
      rethrow;
    }
  }

  String? getSelectedModel() {
    try {
      return _prefs.getString('selected_model');
    } catch (e) {
      _logger.e('Error retrieving model: $e');
      return null;
    }
  }

  Future<void> setAiProvider(String provider) async {
    await _prefs.setString('ai_provider', provider);
  }

  // Migrate legacy provider values to 'groq'.
  String getAiProvider() {
    final v = _prefs.getString('ai_provider') ?? 'groq';
    return (v == 'ollama' || v == 'g4f') ? 'groq' : v;
  }

  Future<void> setCohereApiKey(String key) async {
    await _prefs.setString('cohere_api_key', key);
  }

  String? getCohereApiKey() => _prefs.getString('cohere_api_key');

  Future<void> setCohereModel(String model) async {
    await _prefs.setString('cohere_model', model);
  }

  String? getCohereModel() => _prefs.getString('cohere_model');

  Future<void> clearAll() async {
    try {
      await _prefs.clear();
      _logger.i('Storage cleared');
    } catch (e) {
      _logger.e('Error clearing storage: $e');
      rethrow;
    }
  }
}
