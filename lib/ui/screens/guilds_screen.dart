#guilde pas encore faite option a venir

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import 'package:intl/intl.dart';
import 'create_guild_screen.dart';

class GuildsScreen extends ConsumerStatefulWidget {
  const GuildsScreen({super.key});

  @override
  ConsumerState<GuildsScreen> createState() => _GuildsScreenState();
}

class _GuildsScreenState extends ConsumerState<GuildsScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final guild = gameState.currentGuild;

    return Scaffold(
      appBar: AppBar(title: const Text('GUILDES & SOCIAL')),
      body: guild == null 
          ? _buildGuildBrowser(context, ref, gameState.availableGuilds) 
          : _buildGuildMain(context, ref, guild, gameState.guildMessages),
    );
  }

  Widget _buildGuildBrowser(BuildContext context, WidgetRef ref, List<Guild> guilds) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGuildScreen())),
            child: const Text('CRÉER MA PROPRE GUILDE'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: guilds.length,
            itemBuilder: (context, index) {
              final g = guilds[index];
              return Card(
                key: ValueKey('guild_${g.id}'),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 8),
                      Text(g.description, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(gameProvider.notifier).joinGuild(g.id),
                        child: const Text('REJOINDRE'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGuildMain(BuildContext context, WidgetRef ref, Guild guild, List<ChatMessage> messages) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.shield)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guild.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text('Guilde active • Niveau 1', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => ref.read(gameProvider.notifier).leaveGuild(),
                child: const Text('QUITTER', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[messages.length - 1 - index];
              final isSystem = msg.senderName == "Système";
              return Container(
                key: ValueKey('msg_${msg.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: isSystem ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    if (!isSystem)
                      Text(msg.senderName, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSystem ? Colors.white10 : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(msg.text, style: TextStyle(fontStyle: isSystem ? FontStyle.italic : null)),
                    ),
                    Text(DateFormat('HH:mm').format(msg.timestamp), style: const TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Écrire un message...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_messageController.text.isNotEmpty) {
                    ref.read(gameProvider.notifier).addChatMessage(
                      ref.read(gameProvider).user.pseudo,
                      _messageController.text,
                    );
                    _messageController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
