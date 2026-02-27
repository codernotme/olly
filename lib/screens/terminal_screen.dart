import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/log_provider.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _commandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('System Console',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Terminal'),
                    Tab(text: 'System Logs'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.15)),
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTerminalView(isDark, theme),
                    _buildLogsView(isDark, theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalView(bool isDark, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Consumer<LogProvider>(
            builder: (context, logs, _) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                reverse: true,
                itemCount: logs.terminalOutput.length,
                itemBuilder: (context, index) {
                  final line = logs
                      .terminalOutput[logs.terminalOutput.length - 1 - index];
                  return Text(
                    line,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.greenAccent),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Text('\$',
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _commandController,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter command...',
                  ),
                  onSubmitted: (v) {
                    if (v.isNotEmpty) {
                      context.read<LogProvider>().addTerminalOutput('> $v');
                      context.read<LogProvider>().addTerminalOutput(
                          'Command execution simulation for: $v');
                      _commandController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogsView(bool isDark, ThemeData theme) {
    return Consumer<LogProvider>(
      builder: (context, logProvider, _) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logProvider.logs.length,
          separatorBuilder: (_, __) => const Divider(height: 12),
          itemBuilder: (context, index) {
            final log = logProvider.logs[index];
            final color = switch (log.level) {
              'ERROR' => Colors.redAccent,
              'WARN' => Colors.orangeAccent,
              _ => theme.colorScheme.onSurface.withOpacity(0.6),
            };
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}]',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  log.level,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    log.message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
