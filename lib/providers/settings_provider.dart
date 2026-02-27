import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiKey {
  final String id;
  final String name;
  final String key;
  final DateTime createdAt;
  bool isActive;
  int usageCount;

  ApiKey({
    required this.id,
    required this.name,
    required this.key,
    required this.createdAt,
    this.isActive = true,
    this.usageCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'key': key,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
        'usageCount': usageCount,
      };

  factory ApiKey.fromJson(Map<String, dynamic> json) => ApiKey(
        id: json['id'],
        name: json['name'],
        key: json['key'],
        createdAt: DateTime.parse(json['createdAt']),
        isActive: json['isActive'] ?? true,
        usageCount: json['usageCount'] ?? 0,
      );
}

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _streamingEnabled = true;
  bool _markdownEnabled = true;
  bool _codeHighlightEnabled = true;
  String _defaultSystemPrompt = '';
  double _defaultTemperature = 0.7;
  int _defaultMaxTokens = 2048;
  List<ApiKey> _apiKeys = [];
  String _ollamaBaseUrl = 'http://localhost:11434';
  bool _autoSaveChats = true;
  String _fontFamily = 'Inter';

  ThemeMode get themeMode => _themeMode;
  bool get streamingEnabled => _streamingEnabled;
  bool get markdownEnabled => _markdownEnabled;
  bool get codeHighlightEnabled => _codeHighlightEnabled;
  String get defaultSystemPrompt => _defaultSystemPrompt;
  double get defaultTemperature => _defaultTemperature;
  int get defaultMaxTokens => _defaultMaxTokens;
  List<ApiKey> get apiKeys => _apiKeys;
  String get ollamaBaseUrl => _ollamaBaseUrl;
  bool get autoSaveChats => _autoSaveChats;
  String get fontFamily => _fontFamily;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('theme_mode') ?? 2];
    _streamingEnabled = prefs.getBool('streaming_enabled') ?? true;
    _markdownEnabled = prefs.getBool('markdown_enabled') ?? true;
    _codeHighlightEnabled = prefs.getBool('code_highlight_enabled') ?? true;
    _defaultSystemPrompt = prefs.getString('default_system_prompt') ?? '';
    _defaultTemperature = prefs.getDouble('default_temperature') ?? 0.7;
    _defaultMaxTokens = prefs.getInt('default_max_tokens') ?? 2048;
    _ollamaBaseUrl = prefs.getString('ollama_base_url') ?? 'http://localhost:11434';
    _autoSaveChats = prefs.getBool('auto_save_chats') ?? true;
    _fontFamily = prefs.getString('font_family') ?? 'Inter';

    try {
      final keysJson = prefs.getString('api_keys');
      if (keysJson != null) {
        final list = (jsonDecode(keysJson) as List);
        _apiKeys = list.map((k) => ApiKey.fromJson(k)).toList();
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _themeMode.index);
    await prefs.setBool('streaming_enabled', _streamingEnabled);
    await prefs.setBool('markdown_enabled', _markdownEnabled);
    await prefs.setBool('code_highlight_enabled', _codeHighlightEnabled);
    await prefs.setString('default_system_prompt', _defaultSystemPrompt);
    await prefs.setDouble('default_temperature', _defaultTemperature);
    await prefs.setInt('default_max_tokens', _defaultMaxTokens);
    await prefs.setString('ollama_base_url', _ollamaBaseUrl);
    await prefs.setBool('auto_save_chats', _autoSaveChats);
    await prefs.setString('font_family', _fontFamily);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _save();
    notifyListeners();
  }

  void setStreaming(bool val) {
    _streamingEnabled = val;
    _save();
    notifyListeners();
  }

  void setMarkdown(bool val) {
    _markdownEnabled = val;
    _save();
    notifyListeners();
  }

  void setTemperature(double val) {
    _defaultTemperature = val;
    _save();
    notifyListeners();
  }

  void setMaxTokens(int val) {
    _defaultMaxTokens = val;
    _save();
    notifyListeners();
  }

  void setSystemPrompt(String val) {
    _defaultSystemPrompt = val;
    _save();
    notifyListeners();
  }

  void setBaseUrl(String val) {
    _ollamaBaseUrl = val;
    _save();
    notifyListeners();
  }

  ApiKey addApiKey(String name, String key) {
    final apiKey = ApiKey(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      key: key,
      createdAt: DateTime.now(),
    );
    _apiKeys.add(apiKey);
    _saveApiKeys();
    notifyListeners();
    return apiKey;
  }

  void deleteApiKey(String id) {
    _apiKeys.removeWhere((k) => k.id == id);
    _saveApiKeys();
    notifyListeners();
  }

  void toggleApiKey(String id) {
    final key = _apiKeys.where((k) => k.id == id).firstOrNull;
    if (key != null) {
      key.isActive = !key.isActive;
      _saveApiKeys();
      notifyListeners();
    }
  }

  Future<void> _saveApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_keys', jsonEncode(_apiKeys.map((k) => k.toJson()).toList()));
  }
}
