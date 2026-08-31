import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';
import '../../providers/game_provider.dart';
import '../../models/game_models.dart';

class CreateGuildScreen extends ConsumerStatefulWidget {
  const CreateGuildScreen({super.key});

  @override
  ConsumerState<CreateGuildScreen> createState() => _CreateGuildScreenState();
}

class _CreateGuildScreenState extends ConsumerState<CreateGuildScreen> {
  Translations get t => ref.read(translationsProvider);
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  final _minLevelController = TextEditingController(text: '0');
  final _maxMembersController = TextEditingController(text: '50');
  final _logoUrlController = TextEditingController();
  GuildJoinType _joinType = GuildJoinType.open;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _tagController.dispose();
    _minLevelController.dispose();
    _maxMembersController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.createGuildTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: t.guildName),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                decoration: InputDecoration(labelText: t.description),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagController,
                decoration: InputDecoration(labelText: t.guildTag),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _logoUrlController,
                decoration: InputDecoration(labelText: t.logoUrl),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GuildJoinType>(
                value: _joinType,
                decoration: InputDecoration(labelText: t.guildType),
                items: GuildJoinType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type == GuildJoinType.open
                      ? t.open
                      : type == GuildJoinType.criteria
                          ? t.byCriteria
                          : t.private),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _joinType = value);
                },
              ),
              const SizedBox(height: 16),
              if (_joinType == GuildJoinType.criteria)
                TextField(
                  controller: _minLevelController,
                  decoration: InputDecoration(labelText: t.minLevel),
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxMembersController,
                decoration: InputDecoration(labelText: t.maxMembers),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  final minLevel = int.tryParse(_minLevelController.text) ?? 0;
                  final maxMembers = int.tryParse(_maxMembersController.text) ?? 50;
                  ref.read(gameProvider.notifier).createGuild(
                    name,
                    _descController.text.trim(),
                    _tagController.text.trim(),
                    joinType: _joinType,
                    minLevel: minLevel,
                    maxMembers: maxMembers.clamp(2, 50),
                    logoUrl: _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: Text(t.createGuild),
              ),
            ],
          ),
        ),
      ),
    );
  }
}