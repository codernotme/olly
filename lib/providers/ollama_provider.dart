import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum OllamaStatus { checking, running, stopped, notInstalled, installing }

class OllamaModel {
  final String name;
  final String size;
  final String digest;
  final DateTime modifiedAt;
  final Map<String, dynamic> details;

  OllamaModel({
    required this.name,
    required this.size,
    required this.digest,
    required this.modifiedAt,
    required this.details,
  });

  factory OllamaModel.fromJson(Map<String, dynamic> json) {
    final sizeBytes = json['size'] as int? ?? 0;
    final sizeStr = _formatBytes(sizeBytes);
    return OllamaModel(
      name: json['name'] ?? '',
      size: sizeStr,
      digest: json['digest'] ?? '',
      modifiedAt:
          DateTime.tryParse(json['modified_at'] ?? '') ?? DateTime.now(),
      details: json['details'] ?? {},
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get displayName => name.split(':').first;
  String get tag => name.contains(':') ? name.split(':').last : 'latest';
}

class PullProgress {
  final String status;
  final int completed;
  final int total;
  final String? digest;

  PullProgress({
    required this.status,
    required this.completed,
    required this.total,
    this.digest,
  });

  double get progress => total > 0 ? completed / total : 0;
}

class OllamaProvider extends ChangeNotifier {
  OllamaStatus _status = OllamaStatus.checking;
  List<OllamaModel> _models = [];
  String? _selectedModel;
  String _baseUrl = 'http://localhost:11434';
  bool _isLoading = false;
  String? _error;
  Map<String, PullProgress> _pullProgress = {};
  List<String> _runningModels = [];
  Map<String, dynamic> _systemInfo = {};

  OllamaStatus get status => _status;
  List<OllamaModel> get models {
    return [
      ..._models,
      OllamaModel(
          name: 'gpt-4-turbo',
          size: 'API',
          digest: '',
          modifiedAt: DateTime.now(),
          details: {}),
      OllamaModel(
          name: 'gpt-3.5-turbo',
          size: 'API',
          digest: '',
          modifiedAt: DateTime.now(),
          details: {}),
      OllamaModel(
          name: 'claude-3-opus-20240229',
          size: 'API',
          digest: '',
          modifiedAt: DateTime.now(),
          details: {}),
      OllamaModel(
          name: 'claude-3-sonnet-20240229',
          size: 'API',
          digest: '',
          modifiedAt: DateTime.now(),
          details: {}),
    ];
  }

  String? get selectedModel => _selectedModel;
  String get baseUrl => _baseUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, PullProgress> get pullProgress => _pullProgress;
  List<String> get runningModels => _runningModels;
  Map<String, dynamic> get systemInfo => _systemInfo;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('ollama_base_url') ?? 'http://localhost:11434';
    _selectedModel = prefs.getString('selected_model');
    await checkStatus();
  }

  Future<void> checkStatus() async {
    _status = OllamaStatus.checking;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tags'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _status = OllamaStatus.running;
        await _parseModels(response.body);
        await fetchRunningModels();
      } else {
        _status = OllamaStatus.stopped;
      }
    } catch (e) {
      if (await _isOllamaInstalled()) {
        _status = OllamaStatus.stopped;
      } else {
        _status = OllamaStatus.notInstalled;
      }
    }
    notifyListeners();
  }

  Future<bool> _isOllamaInstalled() async {
    try {
      final result = await Process.run('which', ['ollama']);
      return result.exitCode == 0;
    } catch (_) {
      try {
        final result = await Process.run('where', ['ollama']);
        return result.exitCode == 0;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> _parseModels(String body) async {
    try {
      final data = jsonDecode(body);
      final modelsList = data['models'] as List? ?? [];
      _models = modelsList.map((m) => OllamaModel.fromJson(m)).toList();

      if (_selectedModel == null && _models.isNotEmpty) {
        _selectedModel = _models.first.name;
      }
    } catch (e) {
      _error = 'Failed to parse models: $e';
    }
  }

  Future<void> fetchModels() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/tags'));
      if (response.statusCode == 200) {
        await _parseModels(response.body);
        _error = null;
      }
    } catch (e) {
      _error = 'Failed to fetch models: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRunningModels() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/ps'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final running = data['models'] as List? ?? [];
        _runningModels = running.map((m) => m['name'] as String).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> pullModel(String modelName,
      {Function(PullProgress)? onProgress}) async {
    _pullProgress[modelName] =
        PullProgress(status: 'Starting...', completed: 0, total: 0);
    notifyListeners();

    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/api/pull'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'name': modelName, 'stream': true});

      final response = await request.send();

      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;
        try {
          final data = jsonDecode(chunk);
          final progress = PullProgress(
            status: data['status'] ?? '',
            completed: data['completed'] ?? 0,
            total: data['total'] ?? 0,
            digest: data['digest'],
          );
          _pullProgress[modelName] = progress;
          onProgress?.call(progress);
          notifyListeners();

          if (data['status'] == 'success') {
            _pullProgress.remove(modelName);
            await fetchModels();
            break;
          }
        } catch (_) {}
      }
    } catch (e) {
      _pullProgress.remove(modelName);
      _error = 'Failed to pull model: $e';
      notifyListeners();
    }
  }

  Future<void> deleteModel(String modelName) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': modelName}),
      );
      if (response.statusCode == 200) {
        if (_selectedModel == modelName) _selectedModel = null;
        await fetchModels();
      }
    } catch (e) {
      _error = 'Failed to delete model: $e';
      notifyListeners();
    }
  }

  void selectModel(String model) {
    _selectedModel = model;
    SharedPreferences.getInstance()
        .then((p) => p.setString('selected_model', model));
    notifyListeners();
  }

  Future<String> generateApiKey() async {
    // Generate a local API key for tracking/organization
    final uuid = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    return 'sk-ollama-$uuid-${_randomSuffix()}';
  }

  String _randomSuffix() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
        16, (i) => chars[DateTime.now().microsecond % chars.length]).join();
  }

  Future<Map<String, dynamic>> getModelInfo(String modelName) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/show'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': modelName}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<void> startOllama() async {
    try {
      await Process.start('ollama', ['serve'], mode: ProcessStartMode.detached);
      await Future.delayed(const Duration(seconds: 2));
      await checkStatus();
    } catch (e) {
      _error = 'Failed to start Ollama: $e';
      notifyListeners();
    }
  }

  Future<void> installOllama() async {
    _status = OllamaStatus.installing;
    notifyListeners();
    try {
      if (Platform.isMacOS) {
        await Process.run('brew', ['install', 'ollama']);
      } else if (Platform.isLinux) {
        await Process.run(
            'bash', ['-c', 'curl -fsSL https://ollama.com/install.sh | sh']);
      }
      await checkStatus();
    } catch (e) {
      _error = 'Failed to install Ollama: $e';
      _status = OllamaStatus.notInstalled;
      notifyListeners();
    }
  }

  Future<void> updateBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ollama_base_url', url);
    await checkStatus();
  }

  // Stream chat completions
  Stream<String> streamChat({
    required List<Map<String, String>> messages,
    required String model,
    double temperature = 0.7,
    int maxTokens = 2048,
    String? systemPrompt,
    String? openaiKey,
    String? anthropicKey,
  }) async* {
    if (model.startsWith('gpt-')) {
      yield* _streamOpenAI(
          messages, model, temperature, maxTokens, systemPrompt, openaiKey);
      return;
    }
    if (model.startsWith('claude-')) {
      yield* _streamAnthropic(
          messages, model, temperature, maxTokens, systemPrompt, anthropicKey);
      return;
    }

    final allMessages = <Map<String, String>>[];
    if (systemPrompt != null) {
      allMessages.add({'role': 'system', 'content': systemPrompt});
    }
    allMessages.addAll(messages);

    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/api/chat'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': model,
        'messages': allMessages,
        'stream': true,
        'options': {
          'temperature': temperature,
          'num_predict': maxTokens,
        },
      });

      final response = await request.send();

      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;
        try {
          final data = jsonDecode(chunk);
          final content = data['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }
          if (data['done'] == true) break;
        } catch (_) {}
      }
    } catch (e) {
      yield '\n\n[Error: $e]';
    }
  }

  Stream<String> _streamOpenAI(List<Map<String, String>> messages, String model,
      double temp, int maxTokens, String? sysPrompt, String? apiKey) async* {
    if (apiKey == null || apiKey.isEmpty) {
      yield 'Error: OpenAI API Key not configured in Settings -> API Keys pane.';
      return;
    }
    final allMessages = <Map<String, String>>[];
    if (sysPrompt != null)
      allMessages.add({'role': 'system', 'content': sysPrompt});
    allMessages.addAll(messages);

    try {
      final req = http.Request(
          'POST', Uri.parse('https://api.openai.com/v1/chat/completions'));
      req.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey'
      });
      req.body = jsonEncode({
        'model': model,
        'messages': allMessages,
        'temperature': temp,
        'max_tokens': maxTokens,
        'stream': true
      });
      final res = await req.send();
      await for (final line in res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.isEmpty || !line.startsWith('data: ')) continue;
        final data = line.substring(6);
        if (data == '[DONE]') break;
        try {
          final json = jsonDecode(data);
          final content = json['choices'][0]['delta']['content'] as String?;
          if (content != null) yield content;
        } catch (_) {}
      }
    } catch (e) {
      yield '\n\n[OpenAI Error: $e]';
    }
  }

  Stream<String> _streamAnthropic(
      List<Map<String, String>> messages,
      String model,
      double temp,
      int maxTokens,
      String? sysPrompt,
      String? apiKey) async* {
    if (apiKey == null || apiKey.isEmpty) {
      yield 'Error: Anthropic API Key not configured in Settings -> API Keys pane.';
      return;
    }

    // Convert to Claude format
    final sys = sysPrompt ?? 'You are a helpful assistant.';

    try {
      final req = http.Request(
          'POST', Uri.parse('https://api.anthropic.com/v1/messages'));
      req.headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      });
      req.body = jsonEncode({
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temp,
        'system': sys,
        'messages': messages,
        'stream': true
      });
      final res = await req.send();
      await for (final line in res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.isEmpty || !line.startsWith('data: ')) continue;
        final data = line.substring(6);
        try {
          final json = jsonDecode(data);
          if (json['type'] == 'content_block_delta') {
            final text = json['delta']['text'] as String?;
            if (text != null) yield text;
          }
        } catch (_) {}
      }
    } catch (e) {
      yield '\n\n[Anthropic Error: $e]';
    }
  }

  // Generate embeddings
  Future<List<double>> generateEmbedding(String text, String model) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/embeddings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'model': model, 'prompt': text}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['embedding'] as List).cast<double>();
      }
    } catch (_) {}
    return [];
  }
}
