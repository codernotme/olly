import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ollama_provider.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pullController = TextEditingController();
  String _searchQuery = '';

  // Popular models registry
  final List<_ModelTemplate> _popularModels = [
    _ModelTemplate('llama3.2', '3B', '2.0 GB',
        'Meta\'s latest Llama 3.2 - Great for general use', '🦙'),
    _ModelTemplate('llama3.2:1b', '1B', '1.3 GB',
        'Lightweight Llama 3.2 for fast responses', '🦙'),
    _ModelTemplate(
        'llama3.1', '8B', '4.9 GB', 'Powerful 8B model from Meta', '🦙'),
    _ModelTemplate(
        'mistral', '7B', '4.1 GB', 'Excellent performance, efficient', '⚡'),
    _ModelTemplate('gemma2:2b', '2B', '1.6 GB',
        'Google\'s Gemma 2 - very efficient', '💎'),
    _ModelTemplate(
        'gemma2', '9B', '5.4 GB', 'Google\'s Gemma 2 9B model', '💎'),
    _ModelTemplate('phi3.5', '3.8B', '2.2 GB',
        'Microsoft Phi-3.5 - punches above weight', '🔷'),
    _ModelTemplate('qwen2.5', '7B', '4.7 GB',
        'Alibaba\'s Qwen 2.5 - great multilingual', '🌟'),
    _ModelTemplate(
        'codellama', '7B', '3.8 GB', 'Meta\'s code-specialized model', '💻'),
    _ModelTemplate('deepseek-coder-v2', '16B', '8.9 GB',
        'DeepSeek Coder - excellent for coding', '🔍'),
    _ModelTemplate('llava', '7B', '4.5 GB', 'Vision-language model', '👁️'),
    _ModelTemplate(
        'nomic-embed-text', '-', '274 MB', 'Text embeddings model', '📊'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OllamaProvider>().fetchModels();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pullController.dispose();
    super.dispose();
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
          _buildHeader(theme, isDark),
          _buildTabs(theme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInstalledModels(theme, isDark),
                _buildPullModel(theme, isDark),
                _buildModelLibrary(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olly Models',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Consumer<OllamaProvider>(
                builder: (_, ollama, __) => Text(
                  '${ollama.models.length} installed • ${ollama.runningModels.length} running',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ),
            ],
          ),
          const Spacer(),
          Consumer<OllamaProvider>(
            builder: (_, ollama, __) => FilledButton.icon(
              onPressed: ollama.fetchModels,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Installed'),
          Tab(text: 'Pull Model'),
          Tab(text: 'Library'),
        ],
        isScrollable: false,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInstalledModels(ThemeData theme, bool isDark) {
    return Consumer<OllamaProvider>(
      builder: (context, ollama, _) {
        if (ollama.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ollama.models.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.model_training, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No models installed',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('Go to Pull Model tab to install models',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Pull a Model'),
                ),
              ],
            ),
          );
        }

        final filtered = _searchQuery.isEmpty
            ? ollama.models
            : ollama.models
                .where((m) => m.name.contains(_searchQuery))
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search installed models...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                itemCount: filtered.length,
                itemBuilder: (context, i) =>
                    _buildModelCard(filtered[i], ollama, theme, isDark),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelCard(
      OllamaModel model, OllamaProvider ollama, ThemeData theme, bool isDark) {
    final isSelected = model.name == ollama.selectedModel;
    final isRunning = ollama.runningModels.contains(model.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.white.withOpacity(0.04)
            : isSelected
                ? theme.colorScheme.primary.withOpacity(0.05)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.15),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  model.displayName[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        model.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(model.tag,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ),
                      if (isRunning) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Running',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${model.size} • Modified: ${_formatDate(model.modifiedAt)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  if (model.details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Family: ${model.details['family'] ?? 'Unknown'} • Params: ${model.details['parameter_size'] ?? '?'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                if (!isSelected)
                  OutlinedButton(
                    onPressed: () => ollama.selectModel(model.name),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(90, 36),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Select', style: TextStyle(fontSize: 13)),
                  )
                else
                  FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Active', style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(90, 36),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(model.name, ollama),
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Delete', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(90, 36),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String modelName, OllamaProvider ollama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Model?'),
        content: Text(
            'Are you sure you want to delete "$modelName"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ollama.deleteModel(modelName);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPullModel(ThemeData theme, bool isDark) {
    return Consumer<OllamaProvider>(
      builder: (context, ollama, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull input
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pull a Model',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Enter a model name from the Ollama library (e.g., llama3.2, mistral:7b)',
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pullController,
                            decoration: InputDecoration(
                              hintText: 'Model name (e.g., llama3.2)',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _startPull(ollama),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => _startPull(ollama),
                          icon: const Icon(Icons.download),
                          label: const Text('Pull'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(120, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Active pulls
              if (ollama.pullProgress.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Downloading',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...ollama.pullProgress.entries.map((e) {
                  final progress = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(e.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              progress.total > 0
                                  ? '${(progress.progress * 100).toStringAsFixed(1)}%'
                                  : progress.status,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.total > 0 ? progress.progress : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progress.status,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  void _startPull(OllamaProvider ollama) {
    final modelName = _pullController.text.trim();
    if (modelName.isEmpty) return;
    _pullController.clear();
    ollama.pullModel(modelName);
  }

  Widget _buildModelLibrary(ThemeData theme, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _popularModels.length,
      itemBuilder: (context, i) {
        final model = _popularModels[i];
        return _buildLibraryCard(model, theme, isDark);
      },
    );
  }

  Widget _buildLibraryCard(_ModelTemplate model, ThemeData theme, bool isDark) {
    return Consumer<OllamaProvider>(
      builder: (context, ollama, _) {
        final isInstalled = ollama.models
            .any((m) => m.displayName == model.name.split(':').first);
        final isPulling = ollama.pullProgress.containsKey(model.name);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isInstalled
                  ? Colors.green.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(model.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(model.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(
                          '${model.paramSize} • ${model.size}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (isInstalled)
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  model.description,
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: isPulling
                    ? const LinearProgressIndicator()
                    : isInstalled
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Installed',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () => ollama.pullModel(model.name),
                            icon: const Icon(Icons.download, size: 14),
                            label: const Text('Pull',
                                style: TextStyle(fontSize: 12)),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ModelTemplate {
  final String name;
  final String paramSize;
  final String size;
  final String description;
  final String emoji;

  const _ModelTemplate(
      this.name, this.paramSize, this.size, this.description, this.emoji);
}
