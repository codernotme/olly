import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  String _language = 'python';

  final List<String> _languages = [
    'python',
    'dart',
    'javascript',
    'cpp',
    'html',
    'css',
    'json',
    'bash'
  ];

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _runAction(String action) {
    // Basic AI integration placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AI $action for code...')),
    );
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
          children: [
            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code, size: 20),
                  const SizedBox(width: 12),
                  const Text('AI Code Workspace',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _language,
                      items: _languages
                          .map((lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _language = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _runAction('Review'),
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('Review Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _runAction('Explain'),
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label: const Text('Explain'),
                  ),
                ],
              ),
            ),
            // Editor
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF282C34)
                      : const Color(0xFFFAFAFA),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line numbers placeholder
                    Container(
                      width: 48,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E2E)
                            : Colors.grey.shade100,
                        border: Border(
                            right: BorderSide(
                                color: theme.colorScheme.outline
                                    .withOpacity(0.15))),
                      ),
                      child: Column(
                        children: List.generate(
                          _codeController.text.split('\n').length > 50
                              ? _codeController.text.split('\n').length
                              : 50,
                          (i) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: 2), // Approx line height matches
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                                color: Colors.grey.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // TextField for editing
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: HighlightView(
                                _codeController.text.isEmpty
                                    ? ' '
                                    : _codeController.text,
                                language: _language,
                                theme: atomOneDarkTheme,
                                padding: const EdgeInsets.all(0),
                                textStyle: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          TextField(
                            controller: _codeController,
                            focusNode: _focusNode,
                            maxLines: null,
                            expands: true,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              color: Colors
                                  .transparent, // Hide actual text, show HighlightView underneath
                              fontFamily: 'monospace',
                              fontSize: 14,
                              height: 1.5,
                            ),
                            cursorColor: theme.colorScheme.primary,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
