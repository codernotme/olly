import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/chat_provider.dart';
import '../providers/ollama_provider.dart';
import '../providers/settings_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _showSessions = true;

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: (result) {
      if (mounted) {
        setState(() {
          _inputController.text = result.recognizedWords;
        });
      }
    });
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final chat = context.read<ChatProvider>();
    final ollama = context.read<OllamaProvider>();
    final settings = context.read<SettingsProvider>();

    if (chat.currentSession == null) {
      chat.createSession(model: ollama.selectedModel);
    }

    final session = chat.currentSession!;
    final model = session.model ?? ollama.selectedModel;

    if (model == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a model first')),
      );
      return;
    }

    _inputController.clear();

    await chat.addMessage(
      sessionId: session.id,
      role: MessageRole.user,
      content: text,
    );
    _scrollToBottom();

    final messages = session.messages
        .where((m) => !m.isStreaming)
        .map((m) => m.toApiMap())
        .toList();

    String finalSystemPrompt =
        session.systemPrompt ?? settings.defaultSystemPrompt;
    if (settings.sharedMemory.isNotEmpty) {
      finalSystemPrompt +=
          '\n\n[User Personal Context / Memory]\n${settings.sharedMemory}';
    }

    String? openaiKey = settings.apiKeys
        .where((k) => k.name.toLowerCase().contains('openai') && k.isActive)
        .firstOrNull
        ?.key;
    String? anthropicKey = settings.apiKeys
        .where((k) =>
            (k.name.toLowerCase().contains('anthropic') ||
                k.name.toLowerCase().contains('claude')) &&
            k.isActive)
        .firstOrNull
        ?.key;

    final stream = ollama.streamChat(
      messages: messages,
      model: model,
      temperature: session.temperature,
      systemPrompt: finalSystemPrompt,
      openaiKey: openaiKey,
      anthropicKey: anthropicKey,
    );

    await chat.streamResponse(sessionId: session.id, stream: stream);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // Session list
        if (_showSessions) _buildSessionList(theme, isDark),
        // Chat area
        Expanded(
          child: Column(
            children: [
              _buildChatHeader(theme, isDark),
              Expanded(child: _buildMessageList(theme, isDark)),
              _buildInputArea(theme, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionList(ThemeData theme, bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return Container(
          width: 240,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E0E1B) : const Color(0xFFF5F5F8),
            border: Border(
                right: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.15))),
          ),
          child: Column(
            children: [
              // New chat button
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: () => chat.createSession(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Chat'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              Expanded(
                child: chat.sessions.isEmpty
                    ? const Center(
                        child: Text('No chats yet',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: chat.sessions.length,
                        itemBuilder: (context, i) {
                          final session = chat.sessions[i];
                          final isSelected =
                              session.id == chat.currentSession?.id;
                          return _buildSessionTile(
                              session, isSelected, chat, theme);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionTile(ChatSession session, bool isSelected,
      ChatProvider chat, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Icon(
          Icons.chat_bubble_outline,
          size: 16,
          color: isSelected ? theme.colorScheme.primary : Colors.grey,
        ),
        title: Text(
          session.title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${session.messages.length} msgs',
          style: const TextStyle(fontSize: 10),
        ),
        trailing: PopupMenuButton(
          iconSize: 14,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'clear', child: Text('Clear')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (val) {
            if (val == 'clear') chat.clearSession(session.id);
            if (val == 'delete') chat.deleteSession(session.id);
          },
        ),
        onTap: () => chat.selectSession(session.id),
      ),
    );
  }

  Widget _buildChatHeader(ThemeData theme, bool isDark) {
    return Consumer2<ChatProvider, OllamaProvider>(
      builder: (context, chat, ollama, _) {
        final session = chat.currentSession;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F0F1A).withOpacity(0.8)
                : Colors.white,
            border: Border(
                bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.15))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_showSessions ? Icons.menu_open : Icons.menu),
                onPressed: () => setState(() => _showSessions = !_showSessions),
                iconSize: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session?.title ?? 'New Chat',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Model selector
              if (ollama.models.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: session?.model ?? ollama.selectedModel,
                      isDense: true,
                      icon: Icon(Icons.expand_more,
                          size: 14, color: theme.colorScheme.primary),
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600),
                      items: ollama.models
                          .map((m) => DropdownMenuItem(
                                value: m.name,
                                child: Text(m.displayName,
                                    style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ollama.selectModel(val);
                          if (session != null) {
                            chat.updateSessionSettings(
                                sessionId: session.id, model: val);
                          }
                        }
                      },
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  chat.voiceOutputEnabled ? Icons.volume_up : Icons.volume_off,
                  color: chat.voiceOutputEnabled
                      ? theme.colorScheme.primary
                      : Colors.grey,
                ),
                onPressed: () => chat.toggleVoiceOutput(),
                iconSize: 20,
                tooltip: 'Toggle Voice Output',
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showSessionSettings(context, chat, ollama),
                iconSize: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSessionSettings(
      BuildContext context, ChatProvider chat, OllamaProvider ollama) {
    final session = chat.currentSession;
    if (session == null) return;

    final systemController =
        TextEditingController(text: session.systemPrompt ?? '');
    double temp = session.temperature;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Chat Settings'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Prompt',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: systemController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter system prompt...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Temperature',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    Text(temp.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Slider(
                  value: temp,
                  min: 0,
                  max: 2,
                  divisions: 20,
                  onChanged: (v) => setState(() => temp = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                chat.updateSessionSettings(
                  sessionId: session.id,
                  systemPrompt: systemController.text,
                  temperature: temp,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme, bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final session = chat.currentSession;
        if (session == null || session.messages.isEmpty) {
          return _buildWelcomeScreen(theme);
        }

        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: session.messages.length,
          itemBuilder: (context, i) {
            final message = session.messages[i];
            return _buildMessageBubble(message, theme, isDark);
          },
        );
      },
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary
                ],
              ),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text('Start a conversation',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Select a model and type a message to begin',
            style:
                TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestion('✍️ Write a blog post about AI', theme),
              _buildSuggestion('💻 Write a Python function', theme),
              _buildSuggestion('🔍 Explain quantum computing', theme),
              _buildSuggestion('🎨 Describe a painting style', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion(String text, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        _inputController.text = text.substring(3); // Remove emoji prefix
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildMessageBubble(
      ChatMessage message, ThemeData theme, bool isDark) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'System: ${message.content}',
          style: const TextStyle(fontSize: 12, color: Colors.orange),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary
                    ]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : isDark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: message.isStreaming && message.content.isEmpty
                      ? const _TypingIndicator()
                      : isUser
                          ? SelectableText(
                              message.content,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.5),
                            )
                          : _buildMarkdownContent(
                              message.content, theme, isDark),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Icon(Icons.person,
                      size: 16, color: theme.colorScheme.primary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 42,
              right: isUser ? 42 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ),
                if (!isUser && !message.isStreaming) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 1)),
                      );
                    },
                    child: Icon(Icons.copy,
                        size: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Share to Social Media'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.flutter_dash,
                                    color: Colors.blue),
                                title: const Text('Twitter / X'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Shared to Twitter!')));
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.facebook,
                                    color: Colors.blueAccent),
                                title: const Text('Facebook'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Shared to Facebook!')));
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                    Icons.connect_without_contact,
                                    color: Colors.purple),
                                title: const Text('LinkedIn'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Shared to LinkedIn!')));
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel')),
                          ],
                        ),
                      );
                    },
                    child: Icon(Icons.share,
                        size: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String content, ThemeData theme, bool isDark) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, height: 1.6),
        code: TextStyle(
          fontSize: 13,
          backgroundColor: isDark ? Colors.black45 : Colors.grey.shade200,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 3)),
          color: theme.colorScheme.primary.withOpacity(0.05),
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F0F1A).withOpacity(0.8)
                : Colors.white,
            border: Border(
                top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.15))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        if (!chat.isGenerating) _sendMessage();
                      }
                    },
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      maxLines: 6,
                      minLines: 1,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'Message (Enter to send, Shift+Enter for newline)...',
                        hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_speechEnabled &&
                  !chat.isGenerating &&
                  _inputController.text.isEmpty)
                IconButton.filled(
                  onPressed: _isListening ? _stopListening : _startListening,
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  style: IconButton.styleFrom(
                    backgroundColor: _isListening
                        ? Colors.redAccent
                        : theme.colorScheme.primary.withOpacity(0.1),
                    foregroundColor:
                        _isListening ? Colors.white : theme.colorScheme.primary,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              if (_speechEnabled &&
                  !chat.isGenerating &&
                  _inputController.text.isEmpty)
                const SizedBox(width: 8),
              if (chat.isGenerating)
                IconButton.filled(
                  onPressed: chat.stopGeneration,
                  icon: const Icon(Icons.stop_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 600));
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(0.3 + 0.7 * _controllers[i].value),
            ),
          ),
        );
      }),
    );
  }
}
