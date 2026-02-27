import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ollama_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'models_screen.dart';
import 'agents_screen.dart';
import 'api_keys_screen.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';

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
    ApiKeysScreen(),
    SettingsScreen(),
  ];

  final _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.chat_bubble_rounded, label: 'Chat'),
    _NavItem(icon: Icons.model_training_rounded, label: 'Models'),
    _NavItem(icon: Icons.smart_toy_rounded, label: 'Agents'),
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
        ? const Color(0xFF12121F)
        : const Color(0xFFF8F7FF);
    final selectedColor = theme.colorScheme.primary;

    return Consumer<OllamaProvider>(
      builder: (context, ollama, _) {
        return Container(
          width: 220,
          color: sidebarColor,
          child: Column(
            children: [
              // Logo / App header
              _buildHeader(theme, isDark),
              // Status indicator
              _buildStatusBadge(ollama, theme),
              const SizedBox(height: 8),
              // Navigation items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ollama',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Desktop',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
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
      OllamaStatus.running => (Colors.green, 'Running', Icons.circle),
      OllamaStatus.stopped => (Colors.orange, 'Stopped', Icons.circle),
      OllamaStatus.notInstalled => (Colors.red, 'Not Installed', Icons.circle),
      OllamaStatus.installing => (Colors.blue, 'Installing...', Icons.circle),
      OllamaStatus.checking => (Colors.grey, 'Checking...', Icons.circle),
    };

    return GestureDetector(
      onTap: () {
        if (ollama.status == OllamaStatus.stopped) ollama.startOllama();
        if (ollama.status == OllamaStatus.notInstalled) ollama.installOllama();
        if (ollama.status == OllamaStatus.running) ollama.checkStatus();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 8),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ollama: $label',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (ollama.status == OllamaStatus.stopped || ollama.status == OllamaStatus.notInstalled)
              Icon(Icons.play_arrow, color: color, size: 16),
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
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: selectedColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? selectedColor
                      : isDark
                          ? Colors.white54
                          : Colors.black45,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? selectedColor
                        : isDark
                            ? Colors.white70
                            : Colors.black54,
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
              icon: Icon(Icons.expand_more, size: 16, color: theme.colorScheme.primary),
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
