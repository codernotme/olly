import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ollama_provider.dart';
import 'chat_screen.dart';
import 'models_screen.dart';
import 'agents_screen.dart';
import 'api_keys_screen.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';
import 'editor_screen.dart';
import 'bots_screen.dart';
import 'terminal_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final _screens = const [
    DashboardScreen(),
    ChatScreen(),
    ModelsScreen(),
    AgentsScreen(),
    EditorScreen(),
    BotsScreen(),
    TerminalScreen(),
    ApiKeysScreen(),
    SettingsScreen(),
  ];

  final _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.chat_bubble_rounded, label: 'Chat'),
    _NavItem(icon: Icons.model_training_rounded, label: 'Models'),
    _NavItem(icon: Icons.smart_toy_rounded, label: 'Agents'),
    _NavItem(icon: Icons.code_rounded, label: 'Code Editor'),
    _NavItem(icon: Icons.chat, label: 'Bots'),
    _NavItem(icon: Icons.terminal_rounded, label: 'Console'),
    _NavItem(icon: Icons.key_rounded, label: 'API Keys'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(theme, isDark),
          // Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, bool isDark) {
    final sidebarColor = isDark
        ? const Color(0xFF1E1E2C).withOpacity(0.85) // Translucent dark
        : const Color(0xFFFFFFFF).withOpacity(0.9); // Translucent light
    final selectedColor = theme.colorScheme.primary;

    return Consumer<OllamaProvider>(
      builder: (context, ollama, _) {
        return Container(
          width: 240, // Slightly wider
          decoration: BoxDecoration(
            color: sidebarColor,
            border: Border(
              right: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Logo / App header
              _buildHeader(theme, isDark),
              // Status indicator
              _buildStatusBadge(ollama, theme),
              const SizedBox(height: 16),
              // Navigation items
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _navItems.length,
                  itemBuilder: (context, index) {
                    final item = _navItems[index];
                    final isSelected = _selectedIndex == index;
                    return _buildNavItem(
                      item: item,
                      isSelected: isSelected,
                      selectedColor: selectedColor,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedIndex = index),
                    );
                  },
                ),
              ),
              // Model selector at bottom
              _buildModelSelector(theme, isDark),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Olly',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OllamaProvider ollama, ThemeData theme) {
    final (color, label, icon) = switch (ollama.status) {
      OllamaStatus.running => (
          Colors.greenAccent.shade400,
          'Running',
          Icons.check_circle_rounded
        ),
      OllamaStatus.stopped => (
          Colors.orangeAccent,
          'Stopped',
          Icons.pause_circle_rounded
        ),
      OllamaStatus.notInstalled => (
          Colors.redAccent,
          'Not Installed',
          Icons.error_rounded
        ),
      OllamaStatus.installing => (
          Colors.lightBlueAccent,
          'Installing...',
          Icons.download_rounded
        ),
      OllamaStatus.checking => (Colors.grey, 'Checking...', Icons.sync_rounded),
    };

    return GestureDetector(
      onTap: () {
        if (ollama.status == OllamaStatus.stopped) ollama.startOllama();
        if (ollama.status == OllamaStatus.notInstalled) ollama.installOllama();
        if (ollama.status == OllamaStatus.running) ollama.checkStatus();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (ollama.status == OllamaStatus.stopped ||
                ollama.status == OllamaStatus.notInstalled)
              Icon(Icons.play_arrow_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required _NavItem item,
    required bool isSelected,
    required Color selectedColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: selectedColor.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: isSelected
                      ? selectedColor
                      : isDark
                          ? Colors.white54
                          : Colors.black54,
                ),
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? selectedColor
                        : isDark
                            ? Colors.white70
                            : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelector(ThemeData theme, bool isDark) {
    return Consumer<OllamaProvider>(
      builder: (context, ollama, _) {
        if (ollama.models.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ollama.selectedModel,
              isExpanded: true,
              icon: Icon(Icons.expand_more,
                  size: 16, color: theme.colorScheme.primary),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              hint: const Text('Select model', style: TextStyle(fontSize: 12)),
              items: ollama.models.map((m) {
                return DropdownMenuItem<String>(
                  value: m.name,
                  child: Text(
                    m.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) ollama.selectModel(val);
              },
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
