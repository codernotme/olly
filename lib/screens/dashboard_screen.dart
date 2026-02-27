import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ollama_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/agent_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OllamaProvider>().checkStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 32),
            _buildStatsRow(theme),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildModelsPanel(theme, isDark)),
                const SizedBox(width: 20),
                Expanded(
                    flex: 2, child: _buildQuickActionsPanel(theme, isDark)),
              ],
            ),
            const SizedBox(height: 24),
            _buildRecentChats(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Consumer<OllamaProvider>(
      builder: (context, ollama, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getStatusMessage(ollama.status),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getStatusMessage(OllamaStatus status) => switch (status) {
        OllamaStatus.running => '✅ Ollama is running and ready to use',
        OllamaStatus.stopped =>
          '⚠️ Ollama is stopped — click the status badge to start',
        OllamaStatus.notInstalled =>
          '❌ Ollama is not installed — click to install',
        OllamaStatus.installing => '⏳ Installing Ollama...',
        OllamaStatus.checking => '🔍 Checking Ollama status...',
      };

  Widget _buildStatsRow(ThemeData theme) {
    return Consumer3<OllamaProvider, ChatProvider, AgentProvider>(
      builder: (context, ollama, chat, agents, _) {
        final stats = [
          _StatCard(
            label: 'Models',
            value: ollama.models.length.toString(),
            icon: Icons.model_training,
            color: const Color(0xFF9C27B0), // Purple
            bgColor: const Color(0xFFF3E5F5), // Light purple
            darkBgColor: const Color(0xFF321946),
          ),
          _StatCard(
            label: 'Chats',
            value: chat.sessions.length.toString(),
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF2196F3), // Blue
            bgColor: const Color(0xFFE3F2FD), // Light blue
            darkBgColor: const Color(0xFF132B4C),
          ),
          _StatCard(
            label: 'Agents',
            value: agents.agents.length.toString(),
            icon: Icons.smart_toy_rounded,
            color: const Color(0xFF00E676), // Green
            bgColor: const Color(0xFFE8F5E9), // Light green
            darkBgColor: const Color(0xFF1B3B2B),
          ),
          _StatCard(
            label: 'Running',
            value: ollama.runningModels.length.toString(),
            icon: Icons.play_circle_fill_rounded,
            color: const Color(0xFFFF9800), // Orange
            bgColor: const Color(0xFFFFF3E0), // Light orange
            darkBgColor: const Color(0xFF4C3011),
          ),
        ];

        return Row(
          children: stats
              .map((s) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: _buildStatCard(s, theme),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(_StatCard stat, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: stat.color.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [
                BoxShadow(
                  color: stat.color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? stat.darkBgColor : stat.bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(stat.icon, color: stat.color, size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
              Text(
                stat.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelsPanel(ThemeData theme, bool isDark) {
    return Consumer<OllamaProvider>(
      builder: (context, ollama, _) {
        return _buildPanel(
          theme: theme,
          isDark: isDark,
          title: 'Installed Models',
          trailing: IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: ollama.fetchModels,
          ),
          child: ollama.models.isEmpty
              ? _buildEmptyState('No models installed',
                  'Pull models from the Models tab', Icons.model_training)
              : Column(
                  children: ollama.models.take(6).map((model) {
                    final isSelected = model.name == ollama.selectedModel;
                    final isRunning = ollama.runningModels.contains(model.name);
                    return _buildModelTile(
                        model, isSelected, isRunning, ollama, theme);
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildModelTile(OllamaModel model, bool isSelected, bool isRunning,
      OllamaProvider ollama, ThemeData theme) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            model.displayName[0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      title: Text(
        model.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: Text(
        '${model.tag} • ${model.size}',
        style: TextStyle(
            fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Running',
                  style: TextStyle(fontSize: 10, color: Colors.green)),
            ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle,
                color: theme.colorScheme.primary, size: 16),
          ],
        ],
      ),
      onTap: () => ollama.selectModel(model.name),
    );
  }

  Widget _buildQuickActionsPanel(ThemeData theme, bool isDark) {
    return _buildPanel(
      theme: theme,
      isDark: isDark,
      title: 'Quick Actions',
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'New Chat',
            color: Colors.blue,
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.download_rounded,
            label: 'Pull a Model',
            color: Colors.purple,
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.smart_toy_outlined,
            label: 'Create Agent',
            color: Colors.green,
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.key_outlined,
            label: 'Generate API Key',
            color: Colors.orange,
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.refresh,
            label: 'Refresh Status',
            color: Colors.teal,
            onTap: () => context.read<OllamaProvider>().checkStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: Colors.grey.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChats(ThemeData theme, bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return _buildPanel(
          theme: theme,
          isDark: isDark,
          title: 'Recent Chats',
          child: chat.sessions.isEmpty
              ? _buildEmptyState(
                  'No chats yet',
                  'Start a conversation in the Chat tab',
                  Icons.chat_bubble_outline)
              : Column(
                  children: chat.sessions.take(5).map((session) {
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(Icons.chat_bubble_outline,
                          size: 18, color: theme.colorScheme.primary),
                      title: Text(
                        session.title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${session.messages.length} messages • ${_formatDate(session.updatedAt)}',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildPanel({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _StatCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color darkBgColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.bgColor = Colors.transparent,
    this.darkBgColor = Colors.transparent,
  });
}
