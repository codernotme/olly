import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ollama_provider.dart';
import 'dart:convert';
import 'dart:math';

class ApiKeysScreen extends StatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  String? _generatedKey;
  bool _showKey = false;

  // Simulated API usage data
  final List<Map<String, dynamic>> _apiLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _generateApiKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final prefix = 'sk-ollama-';
    final body = List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
    return '$prefix$body';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('API Keys', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Generate and manage API keys for programmatic access to your Ollama instance',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These API keys are for local organization and tracking. Ollama itself runs without authentication on localhost. Use these keys to organize access in your applications.',
                    style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'My Keys'),
                Tab(text: 'Generate Key'),
                Tab(text: 'API Reference'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyKeys(theme, isDark),
                _buildGenerateKey(theme, isDark),
                _buildApiReference(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyKeys(ThemeData theme, bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        if (settings.apiKeys.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.key_off, size: 64, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No API keys yet', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Generate your first API key', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.add),
                  label: const Text('Generate Key'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: settings.apiKeys.length,
          itemBuilder: (context, i) {
            final key = settings.apiKeys[i];
            return _buildKeyCard(key, settings, theme, isDark);
          },
        );
      },
    );
  }

  Widget _buildKeyCard(ApiKey key, SettingsProvider settings, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: key.isActive
              ? theme.colorScheme.outline.withOpacity(0.2)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: key.isActive
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.key,
                  color: key.isActive ? theme.colorScheme.primary : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(key.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: key.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            key.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              color: key.isActive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Created ${_formatDate(key.createdAt)} • ${key.usageCount} API calls',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Switch(
                    value: key.isActive,
                    onChanged: (_) => settings.toggleApiKey(key.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    onPressed: () => _confirmDeleteKey(key.id, settings),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Key display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 14, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${key.key.substring(0, 20)}${'•' * 20}${key.key.substring(key.key.length - 4)}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: key.key));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API key copied!'), duration: Duration(seconds: 2)),
                    );
                  },
                  tooltip: 'Copy',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKey(String id, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete API Key?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              settings.deleteApiKey(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateKey(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generation form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generate New API Key', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Key Name (e.g., My App, Development)',
                    hintText: 'Give your key a descriptive name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a name for your key')),
                        );
                        return;
                      }
                      final key = _generateApiKey();
                      setState(() {
                        _generatedKey = key;
                        _showKey = true;
                      });
                      context.read<SettingsProvider>().addApiKey(_nameController.text.trim(), key);
                      _nameController.clear();
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate API Key'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_generatedKey != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text('API Key Generated!', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ Copy this key now. For security, we won\'t show the full key again.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black38 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _showKey ? _generatedKey! : '${_generatedKey!.substring(0, 20)}${'•' * 20}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setState(() => _showKey = !_showKey),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedKey!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 2)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApiReference(ThemeData theme, bool isDark) {
    return Consumer<OllamaProvider>(
      builder: (context, ollama, _) {
        final baseUrl = ollama.baseUrl;
        
        final endpoints = [
          _Endpoint('GET', '$baseUrl/api/tags', 'List Models', 'Returns all locally available models'),
          _Endpoint('POST', '$baseUrl/api/chat', 'Chat', 'Generate a chat completion (streaming supported)'),
          _Endpoint('POST', '$baseUrl/api/generate', 'Generate', 'Generate text completion'),
          _Endpoint('POST', '$baseUrl/api/pull', 'Pull Model', 'Download a model from the library'),
          _Endpoint('DELETE', '$baseUrl/api/delete', 'Delete Model', 'Remove a locally installed model'),
          _Endpoint('POST', '$baseUrl/api/embeddings', 'Embeddings', 'Generate text embeddings'),
          _Endpoint('GET', '$baseUrl/api/ps', 'Running Models', 'List currently loaded models'),
          _Endpoint('POST', '$baseUrl/api/show', 'Model Info', 'Get details about a specific model'),
          _Endpoint('POST', '$baseUrl/api/copy', 'Copy Model', 'Duplicate a model'),
        ];

        return ListView(
          padding: const EdgeInsets.all(32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Base URL', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(baseUrl, style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () => Clipboard.setData(ClipboardData(text: baseUrl)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Endpoints', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...endpoints.map((e) => _buildEndpointCard(e, theme, isDark)),
            const SizedBox(height: 16),
            _buildCodeExample(isDark),
          ],
        );
      },
    );
  }

  Widget _buildEndpointCard(_Endpoint endpoint, ThemeData theme, bool isDark) {
    final methodColor = switch (endpoint.method) {
      'GET' => Colors.green,
      'POST' => Colors.blue,
      'DELETE' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: methodColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                endpoint.method,
                style: TextStyle(color: methodColor, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(endpoint.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  endpoint.url,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                ),
                Text(endpoint.description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            onPressed: () => Clipboard.setData(ClipboardData(text: endpoint.url)),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeExample(bool isDark) {
    const code = '''
// Example: Chat with Ollama
const response = await fetch('http://localhost:11434/api/chat', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: 'llama3.2',
    messages: [{ role: 'user', content: 'Hello!' }],
    stream: false
  })
});
const data = await response.json();
console.log(data.message.content);
''';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('JavaScript Example', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white54, size: 16),
                onPressed: () => Clipboard.setData(const ClipboardData(text: code)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            code,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF9CDCFE), height: 1.6),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _Endpoint {
  final String method;
  final String url;
  final String name;
  final String description;

  const _Endpoint(this.method, this.url, this.name, this.description);
}
