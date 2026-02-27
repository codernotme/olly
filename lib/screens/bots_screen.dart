import 'package:flutter/material.dart';

class BotsScreen extends StatefulWidget {
  const BotsScreen({super.key});

  @override
  State<BotsScreen> createState() => _BotsScreenState();
}

class _BotsScreenState extends State<BotsScreen> {
  final _tgTokenController = TextEditingController();
  final _waTokenController = TextEditingController();

  bool _tgBotRunning = false;
  bool _waBotRunning = false;

  @override
  void dispose() {
    _tgTokenController.dispose();
    _waTokenController.dispose();
    super.dispose();
  }

  void _toggleTgBot() {
    if (_tgTokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a Telegram Bot Token')));
      return;
    }
    setState(() => _tgBotRunning = !_tgBotRunning);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_tgBotRunning
              ? 'Telegram Bot Started (Polling Mode)'
              : 'Telegram Bot Stopped')),
    );
  }

  void _toggleWaBot() {
    if (_waTokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a WhatsApp API Token')));
      return;
    }
    setState(() => _waBotRunning = !_waBotRunning);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              _waBotRunning ? 'WhatsApp Bot Started' : 'WhatsApp Bot Stopped')),
    );
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
            Text('Social Bots',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Connect your local AI models to Telegram and WhatsApp',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTelegramCard(theme, isDark)),
                const SizedBox(width: 24),
                Expanded(child: _buildWhatsAppCard(theme, isDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelegramCard(ThemeData theme, bool isDark) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.telegram, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Text('Telegram Bot',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              _buildStatusIndicator(_tgBotRunning),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Create a bot via BotFather and paste the token here.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _tgTokenController,
            decoration: InputDecoration(
              labelText: 'Bot Token',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleTgBot,
              style: ElevatedButton.styleFrom(
                backgroundColor: _tgBotRunning
                    ? Colors.red.withOpacity(0.1)
                    : theme.colorScheme.primary,
                foregroundColor: _tgBotRunning ? Colors.red : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_tgBotRunning ? 'Stop Bot' : 'Start Polling'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppCard(ThemeData theme, bool isDark) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Text('WhatsApp Bot',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              _buildStatusIndicator(_waBotRunning),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Enter your Meta Graph API access token.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _waTokenController,
            decoration: InputDecoration(
              labelText: 'Access Token',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleWaBot,
              style: ElevatedButton.styleFrom(
                backgroundColor: _waBotRunning
                    ? Colors.red.withOpacity(0.1)
                    : theme.colorScheme.primary,
                foregroundColor: _waBotRunning ? Colors.red : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                  _waBotRunning ? 'Stop Webhook Mode' : 'Start Webhook Mode'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isRunning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRunning
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle,
              size: 8, color: isRunning ? Colors.green : Colors.grey),
          const SizedBox(width: 4),
          Text(
            isRunning ? 'Running' : 'Stopped',
            style: TextStyle(
                fontSize: 10,
                color: isRunning ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
