import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AgentStatus { idle, running, paused, completed, error }

enum AgentType { assistant, coder, researcher, writer, analyst, custom }

class AgentTool {
  final String name;
  final String description;
  bool enabled;

  AgentTool({required this.name, required this.description, this.enabled = true});

  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'enabled': enabled};
  factory AgentTool.fromJson(Map<String, dynamic> j) =>
      AgentTool(name: j['name'], description: j['description'], enabled: j['enabled'] ?? true);
}

class AgentStep {
  final String id;
  final String action;
  final String result;
  final DateTime timestamp;
  final bool success;

  AgentStep({
    required this.action,
    required this.result,
    required this.success,
    DateTime? timestamp,
  })  : id = _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

class Agent {
  final String id;
  String name;
  String description;
  AgentType type;
  String model;
  String systemPrompt;
  AgentStatus status;
  List<AgentTool> tools;
  List<AgentStep> steps;
  final DateTime createdAt;
  double temperature;
  int maxSteps;
  String? lastOutput;
  String? avatarEmoji;

  Agent({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.model,
    required this.systemPrompt,
    this.status = AgentStatus.idle,
    List<AgentTool>? tools,
    List<AgentStep>? steps,
    DateTime? createdAt,
    this.temperature = 0.7,
    this.maxSteps = 10,
    this.lastOutput,
    this.avatarEmoji,
  })  : id = id ?? _uuid.v4(),
        tools = tools ?? [],
        steps = steps ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'model': model,
        'systemPrompt': systemPrompt,
        'status': status.name,
        'tools': tools.map((t) => t.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'temperature': temperature,
        'maxSteps': maxSteps,
        'lastOutput': lastOutput,
        'avatarEmoji': avatarEmoji,
      };

  factory Agent.fromJson(Map<String, dynamic> j) => Agent(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        type: AgentType.values.byName(j['type'] ?? 'custom'),
        model: j['model'],
        systemPrompt: j['systemPrompt'],
        status: AgentStatus.values.byName(j['status'] ?? 'idle'),
        tools: (j['tools'] as List? ?? []).map((t) => AgentTool.fromJson(t)).toList(),
        createdAt: DateTime.parse(j['createdAt']),
        temperature: (j['temperature'] as num?)?.toDouble() ?? 0.7,
        maxSteps: j['maxSteps'] ?? 10,
        lastOutput: j['lastOutput'],
        avatarEmoji: j['avatarEmoji'],
      );

  String get typeLabel => switch (type) {
        AgentType.assistant => '🤖 Assistant',
        AgentType.coder => '💻 Coder',
        AgentType.researcher => '🔬 Researcher',
        AgentType.writer => '✍️ Writer',
        AgentType.analyst => '📊 Analyst',
        AgentType.custom => '⚙️ Custom',
      };

  String get defaultEmoji => switch (type) {
        AgentType.assistant => '🤖',
        AgentType.coder => '💻',
        AgentType.researcher => '🔬',
        AgentType.writer => '✍️',
        AgentType.analyst => '📊',
        AgentType.custom => '⚙️',
      };
}

class AgentProvider extends ChangeNotifier {
  List<Agent> _agents = [];
  String? _activeAgentId;

  List<Agent> get agents => _agents;
  Agent? get activeAgent => _agents.where((a) => a.id == _activeAgentId).firstOrNull;

  AgentProvider() {
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('agents');
      if (data != null) {
        final list = jsonDecode(data) as List;
        _agents = list.map((a) => Agent.fromJson(a)).toList();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveAgents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('agents', jsonEncode(_agents.map((a) => a.toJson()).toList()));
  }

  Agent createAgent({
    required String name,
    required String description,
    required AgentType type,
    required String model,
    String? systemPrompt,
    double temperature = 0.7,
  }) {
    final defaultPrompts = {
      AgentType.assistant: 'You are a helpful AI assistant. Be concise, accurate, and helpful.',
      AgentType.coder: 'You are an expert software engineer. Write clean, efficient, well-documented code. Always explain your solutions.',
      AgentType.researcher: 'You are a thorough researcher. Analyze information carefully, cite sources when possible, and provide comprehensive summaries.',
      AgentType.writer: 'You are a skilled writer. Craft engaging, clear, and well-structured content tailored to the audience.',
      AgentType.analyst: 'You are a data analyst. Analyze data, identify patterns, and provide actionable insights with clear explanations.',
      AgentType.custom: 'You are a specialized AI assistant.',
    };

    final agent = Agent(
      name: name,
      description: description,
      type: type,
      model: model,
      systemPrompt: systemPrompt ?? defaultPrompts[type] ?? '',
      temperature: temperature,
      tools: _defaultToolsForType(type),
    );

    _agents.add(agent);
    _saveAgents();
    notifyListeners();
    return agent;
  }

  List<AgentTool> _defaultToolsForType(AgentType type) {
    return switch (type) {
      AgentType.coder => [
          AgentTool(name: 'code_execution', description: 'Execute code snippets'),
          AgentTool(name: 'file_read', description: 'Read file contents'),
          AgentTool(name: 'code_search', description: 'Search through code'),
        ],
      AgentType.researcher => [
          AgentTool(name: 'web_search', description: 'Search the web'),
          AgentTool(name: 'summarize', description: 'Summarize documents'),
          AgentTool(name: 'extract_info', description: 'Extract key information'),
        ],
      AgentType.analyst => [
          AgentTool(name: 'data_analysis', description: 'Analyze datasets'),
          AgentTool(name: 'chart_generation', description: 'Generate charts'),
          AgentTool(name: 'statistics', description: 'Compute statistics'),
        ],
      _ => [
          AgentTool(name: 'text_processing', description: 'Process and transform text'),
        ],
    };
  }

  void selectAgent(String id) {
    _activeAgentId = id;
    notifyListeners();
  }

  void deleteAgent(String id) {
    _agents.removeWhere((a) => a.id == id);
    if (_activeAgentId == id) _activeAgentId = null;
    _saveAgents();
    notifyListeners();
  }

  void updateAgent(String id, {String? name, String? description, String? systemPrompt, double? temperature, String? model}) {
    final agent = _agents.where((a) => a.id == id).firstOrNull;
    if (agent != null) {
      if (name != null) agent.name = name;
      if (description != null) agent.description = description;
      if (systemPrompt != null) agent.systemPrompt = systemPrompt;
      if (temperature != null) agent.temperature = temperature;
      if (model != null) agent.model = model;
      _saveAgents();
      notifyListeners();
    }
  }

  void addStep(String agentId, AgentStep step) {
    final agent = _agents.where((a) => a.id == agentId).firstOrNull;
    if (agent != null) {
      agent.steps.add(step);
      notifyListeners();
    }
  }

  void setAgentStatus(String agentId, AgentStatus status) {
    final agent = _agents.where((a) => a.id == agentId).firstOrNull;
    if (agent != null) {
      agent.status = status;
      _saveAgents();
      notifyListeners();
    }
  }

  void setLastOutput(String agentId, String output) {
    final agent = _agents.where((a) => a.id == agentId).firstOrNull;
    if (agent != null) {
      agent.lastOutput = output;
      _saveAgents();
      notifyListeners();
    }
  }
}
