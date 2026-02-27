import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../providers/ollama_provider.dart';
import '../providers/chat_provider.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<AgentProvider>(
        builder: (context, agents, _) {
          return Row(
            children: [
              // Agent list
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0E0E1B) : const Color(0xFFF5F5F8),
                  border: Border(right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Agents', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            'Create AI sub-agents with specialized roles',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FilledButton.icon(
                        onPressed: () => _showCreateAgentDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Agent'),
                        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: agents.agents.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('No agents yet', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              itemCount: agents.agents.length,
                              itemBuilder: (context, i) {
                                final agent = agents.agents[i];
                                final isActive = agents.activeAgent?.id == agent.id;
                                return _buildAgentListTile(agent, isActive, agents, theme);
                              },
                            ),
                    ),
                  ],
                ),
              ),
              // Agent detail / chat
              Expanded(
                child: agents.activeAgent == null
                    ? _buildEmptyState(theme)
                    : _buildAgentPanel(agents.activeAgent!, agents, theme, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAgentListTile(Agent agent, bool isActive, AgentProvider agents, ThemeData theme) {
    final statusColor = switch (agent.status) {
      AgentStatus.running => Colors.green,
      AgentStatus.paused => Colors.orange,
      AgentStatus.error => Colors.red,
      AgentStatus.completed => Colors.blue,
      AgentStatus.idle => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(agent.avatarEmoji ?? agent.defaultEmoji, style: const TextStyle(fontSize: 18))),
        ),
        title: Text(
          agent.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.circle, color: statusColor, size: 8),
            const SizedBox(width: 4),
            Text(
              agent.status.name,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          iconSize: 16,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (val) {
            if (val == 'delete') agents.deleteAgent(agent.id);
          },
        ),
        onTap: () => agents.selectAgent(agent.id),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('Select or create an agent', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Agents are specialized AI assistants that can\nperform specific tasks autonomously',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateAgentDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Agent'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPanel(Agent agent, AgentProvider agents, ThemeData theme, bool isDark) {
    final taskController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agent header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15))),
          ),
          child: Row(
            children: [
              Text(agent.avatarEmoji ?? agent.defaultEmoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(agent.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(agent.typeLabel, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                    Text(agent.description, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Agent controls
              Row(
                children: [
                  _buildStatusChip(agent.status, theme),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _showEditAgentDialog(context, agent, agents),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Content area
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: system prompt and tools
              SizedBox(
                width: 280,
                child: _buildAgentConfig(agent, theme, isDark),
              ),
              // Right: agent chat/task execution
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildAgentSteps(agent, theme, isDark)),
                    _buildTaskInput(agent, agents, theme, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentConfig(Agent agent, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1))),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuration', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildConfigCard('Model', agent.model, Icons.model_training, theme),
            _buildConfigCard('Temperature', agent.temperature.toStringAsFixed(1), Icons.thermostat, theme),
            _buildConfigCard('Max Steps', agent.maxSteps.toString(), Icons.repeat, theme),
            const SizedBox(height: 16),
            Text('System Prompt', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              ),
              child: Text(
                agent.systemPrompt,
                style: const TextStyle(fontSize: 12, height: 1.5),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            Text('Tools', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...agent.tools.map((tool) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        tool.enabled ? Icons.check_box : Icons.check_box_outline_blank,
                        color: tool.enabled ? theme.colorScheme.primary : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tool.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard(String label, String value, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAgentSteps(Agent agent, ThemeData theme, bool isDark) {
    if (agent.steps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('No tasks yet', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            const Text(
              'Enter a task below to run this agent',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: agent.steps.length,
      itemBuilder: (context, i) {
        final step = agent.steps[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: step.success ? Colors.green : Colors.red,
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    step.success ? Icons.check_circle : Icons.error,
                    color: step.success ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Step ${i + 1}: ${step.action}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(step.timestamp),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              if (step.result.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  step.result,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskInput(Agent agent, AgentProvider agents, ThemeData theme, bool isDark) {
    final controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Give ${agent.name} a task...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () async {
              final task = controller.text.trim();
              if (task.isEmpty) return;
              controller.clear();
              await _runAgentTask(agent, task, agents);
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(100, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAgentTask(Agent agent, String task, AgentProvider agents) async {
    agents.setAgentStatus(agent.id, AgentStatus.running);
    final ollama = context.read<OllamaProvider>();

    agents.addStep(
      agent.id,
      AgentStep(action: 'Received task', result: task, success: true),
    );

    // Simulate agent thinking
    final messages = [
      {'role': 'system', 'content': agent.systemPrompt},
      {'role': 'user', 'content': task},
    ];

    String fullResponse = '';
    await for (final chunk in ollama.streamChat(
      messages: messages.cast<Map<String, String>>(),
      model: agent.model,
      temperature: agent.temperature,
    )) {
      fullResponse += chunk;
    }

    agents.addStep(
      agent.id,
      AgentStep(action: 'Generated response', result: fullResponse, success: true),
    );
    agents.setLastOutput(agent.id, fullResponse);
    agents.setAgentStatus(agent.id, AgentStatus.completed);
  }

  Widget _buildStatusChip(AgentStatus status, ThemeData theme) {
    final (color, label) = switch (status) {
      AgentStatus.running => (Colors.green, 'Running'),
      AgentStatus.paused => (Colors.orange, 'Paused'),
      AgentStatus.error => (Colors.red, 'Error'),
      AgentStatus.completed => (Colors.blue, 'Completed'),
      AgentStatus.idle => (Colors.grey, 'Idle'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showCreateAgentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    AgentType selectedType = AgentType.assistant;
    String? selectedModel;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final ollama = context.read<OllamaProvider>();
          selectedModel ??= ollama.selectedModel;

          return AlertDialog(
            title: const Text('Create New Agent'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Agent Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AgentType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Agent Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: AgentType.values.map((t) {
                        final agent = Agent(name: '', description: '', type: t, model: '', systemPrompt: '');
                        return DropdownMenuItem(value: t, child: Text(agent.typeLabel));
                      }).toList(),
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedModel,
                      decoration: InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ollama.models.map((m) => DropdownMenuItem(value: m.name, child: Text(m.name))).toList(),
                      onChanged: (v) => setState(() => selectedModel = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty || selectedModel == null) return;
                  context.read<AgentProvider>().createAgent(
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        type: selectedType,
                        model: selectedModel!,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditAgentDialog(BuildContext context, Agent agent, AgentProvider agents) {
    final nameCtrl = TextEditingController(text: agent.name);
    final systemCtrl = TextEditingController(text: agent.systemPrompt);
    double temp = agent.temperature;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Edit ${agent.name}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: systemCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'System Prompt',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Temperature: '),
                    Text(temp.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(value: temp, min: 0, max: 2, divisions: 20, onChanged: (v) => setState(() => temp = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                agents.updateAgent(
                  agent.id,
                  name: nameCtrl.text,
                  systemPrompt: systemCtrl.text,
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

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
