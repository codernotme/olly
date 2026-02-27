import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ollama_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _memoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController.text = settings.ollamaBaseUrl;
    _systemPromptController.text = settings.defaultSystemPrompt;
    _memoryController.text = settings.sharedMemory;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _systemPromptController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<SettingsProvider, OllamaProvider>(
        builder: (context, settings, ollama, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olly Settings',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Configure your Olly experience',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildSection(
                            title: 'Appearance',
                            icon: Icons.palette_outlined,
                            theme: theme,
                            isDark: isDark,
                            children: [
                              _buildThemeSetting(settings, theme, isDark),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: 'Connection',
                            icon: Icons.lan_outlined,
                            theme: theme,
                            isDark: isDark,
                            children: [
                              _buildConnectionSetting(settings, ollama, theme),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: 'Chat Defaults',
                            icon: Icons.chat_outlined,
                            theme: theme,
                            isDark: isDark,
                            children: [
                              _buildChatSettings(settings, theme, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildSection(
                            title: 'Model Settings',
                            icon: Icons.model_training,
                            theme: theme,
                            isDark: isDark,
                            children: [
                              _buildModelSettings(settings, theme, isDark),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: 'About',
                            icon: Icons.info_outline,
                            theme: theme,
                            isDark: isDark,
                            children: [
                              _buildAbout(theme, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeSetting(
      SettingsProvider settings, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme Mode',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildThemeOption(
                'Light', Icons.light_mode, ThemeMode.light, settings, theme),
            const SizedBox(width: 10),
            _buildThemeOption(
                'Dark', Icons.dark_mode, ThemeMode.dark, settings, theme),
            const SizedBox(width: 10),
            _buildThemeOption('System', Icons.brightness_auto, ThemeMode.system,
                settings, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(String label, IconData icon, ThemeMode mode,
      SettingsProvider settings, ThemeData theme) {
    final isSelected = settings.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => settings.setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                  size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionSetting(
      SettingsProvider settings, OllamaProvider ollama, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ollama Server URL',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'http://localhost:11434',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                settings.setBaseUrl(_urlController.text);
                ollama.updateBaseUrl(_urlController.text);
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Consumer<OllamaProvider>(
              builder: (_, ollama, __) {
                final (color, label) = switch (ollama.status) {
                  OllamaStatus.running => (Colors.green, 'Connected'),
                  OllamaStatus.stopped => (Colors.orange, 'Not Running'),
                  OllamaStatus.notInstalled => (Colors.red, 'Not Installed'),
                  _ => (Colors.grey, 'Checking...'),
                };
                return Row(
                  children: [
                    Icon(Icons.circle, color: color, size: 10),
                    const SizedBox(width: 6),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ],
                );
              },
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: ollama.checkStatus,
              icon: const Icon(Icons.refresh, size: 14),
              label:
                  const Text('Test Connection', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatSettings(
      SettingsProvider settings, ThemeData theme, bool isDark) {
    return Column(
      children: [
        _buildToggleSetting(
          'Streaming Responses',
          'Show responses as they generate in real-time',
          settings.streamingEnabled,
          settings.setStreaming,
          theme,
        ),
        const Divider(height: 24),
        _buildToggleSetting(
          'Markdown Rendering',
          'Render markdown formatting in messages',
          settings.markdownEnabled,
          settings.setMarkdown,
          theme,
        ),
        const Divider(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Default System Prompt',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            const Text(
              'Applied to new chats when no session-specific prompt is set',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _systemPromptController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'You are a helpful assistant...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
                isDense: true,
              ),
              onChanged: settings.setSystemPrompt,
            ),
          ],
        ),
        const Divider(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Memory (Shared Context)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            const Text(
              'Facts about yourself that the assistant should remember.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memoryController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'I am a software developer...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
                isDense: true,
              ),
              onChanged: settings.setSharedMemory,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModelSettings(
      SettingsProvider settings, ThemeData theme, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Default Temperature',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    settings.defaultTemperature.toStringAsFixed(1),
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Slider(
                value: settings.defaultTemperature,
                min: 0,
                max: 2,
                divisions: 20,
                onChanged: settings.setTemperature,
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Max Tokens',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    settings.defaultMaxTokens.toString(),
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Slider(
                value: settings.defaultMaxTokens.toDouble(),
                min: 256,
                max: 8192,
                divisions: 31,
                onChanged: (v) => settings.setMaxTokens(v.toInt()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildAbout(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olly',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Version 1.0.0',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'A powerful desktop client for managing and interacting with locally-run AI models via Ollama.',
          style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildBadge('Flutter', Colors.blue),
            _buildBadge('Ollama API', Colors.purple),
            _buildBadge('Open Source', Colors.green),
            _buildBadge('Local AI', Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
