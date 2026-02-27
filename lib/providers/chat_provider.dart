import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';

const _uuid = Uuid();

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  String content;
  final DateTime timestamp;
  bool isStreaming;
  Map<String, dynamic>? metadata;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isStreaming = false,
    this.metadata,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, String> toApiMap() => {
        'role': role.name,
        'content': content,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        role: MessageRole.values.byName(json['role']),
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class ChatSession {
  final String id;
  String title;
  List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  String? model;
  String? systemPrompt;
  double temperature;

  ChatSession({
    String? id,
    required this.title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.model,
    this.systemPrompt,
    this.temperature = 0.7,
  })  : id = id ?? _uuid.v4(),
        messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'model': model,
        'systemPrompt': systemPrompt,
        'temperature': temperature,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        title: json['title'],
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        model: json['model'],
        systemPrompt: json['systemPrompt'],
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      );
}

class ChatProvider extends ChangeNotifier {
  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  bool _isGenerating = false;
  final FlutterTts _tts = FlutterTts();
  bool _voiceOutputEnabled = false;

  List<ChatSession> get sessions => _sessions;
  ChatSession? get currentSession =>
      _sessions.where((s) => s.id == _currentSessionId).firstOrNull;
  bool get isGenerating => _isGenerating;
  bool get voiceOutputEnabled => _voiceOutputEnabled;

  void toggleVoiceOutput() {
    _voiceOutputEnabled = !_voiceOutputEnabled;
    if (!_voiceOutputEnabled) _tts.stop();
    notifyListeners();
  }

  ChatProvider() {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('chat_sessions');
      if (data != null) {
        final list = jsonDecode(data) as List;
        _sessions = list.map((s) => ChatSession.fromJson(s)).toList();
        _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_sessions',
          jsonEncode(_sessions.map((s) => s.toJson()).toList()));
    } catch (_) {}
  }

  ChatSession createSession({String? model, String? systemPrompt}) {
    final session = ChatSession(
      title: 'New Chat',
      model: model,
      systemPrompt: systemPrompt,
    );
    _sessions.insert(0, session);
    _currentSessionId = session.id;
    _saveSessions();
    notifyListeners();
    return session;
  }

  void selectSession(String id) {
    _currentSessionId = id;
    notifyListeners();
  }

  void deleteSession(String id) {
    _sessions.removeWhere((s) => s.id == id);
    if (_currentSessionId == id) {
      _currentSessionId = _sessions.isNotEmpty ? _sessions.first.id : null;
    }
    _saveSessions();
    notifyListeners();
  }

  void clearSession(String id) {
    final session = _sessions.where((s) => s.id == id).firstOrNull;
    if (session != null) {
      session.messages.clear();
      session.title = 'New Chat';
      _saveSessions();
      notifyListeners();
    }
  }

  Future<void> addMessage({
    required String sessionId,
    required MessageRole role,
    required String content,
    bool isStreaming = false,
  }) async {
    final session = _sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session == null) return;

    final message =
        ChatMessage(role: role, content: content, isStreaming: isStreaming);
    session.messages.add(message);
    session.updatedAt = DateTime.now();

    if (session.messages.length == 1) {
      session.title =
          content.length > 40 ? '${content.substring(0, 40)}...' : content;
    }

    notifyListeners();
    await _saveSessions();
  }

  Future<void> streamResponse({
    required String sessionId,
    required Stream<String> stream,
  }) async {
    final session = _sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session == null) return;

    _isGenerating = true;
    final message = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );
    session.messages.add(message);
    notifyListeners();

    try {
      await for (final chunk in stream) {
        message.content += chunk;
        notifyListeners();
      }
    } finally {
      message.isStreaming = false;
      _isGenerating = false;
      session.updatedAt = DateTime.now();
      notifyListeners();
      await _saveSessions();
      if (_voiceOutputEnabled && message.content.isNotEmpty) {
        _tts.speak(message.content);
      }
    }
  }

  void updateSessionSettings({
    required String sessionId,
    String? model,
    String? systemPrompt,
    double? temperature,
  }) {
    final session = _sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session != null) {
      if (model != null) session.model = model;
      if (systemPrompt != null) session.systemPrompt = systemPrompt;
      if (temperature != null) session.temperature = temperature;
      _saveSessions();
      notifyListeners();
    }
  }

  void stopGeneration() {
    _isGenerating = false;
    _tts.stop();
    final session = currentSession;
    if (session != null && session.messages.isNotEmpty) {
      final last = session.messages.last;
      if (last.isStreaming) {
        last.isStreaming = false;
        last.content += '\n\n[Generation stopped]';
      }
    }
    notifyListeners();
  }
}
