import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';

class CreateGuildScreen extends ConsumerStatefulWidget {
  const CreateGuildScreen({super.key});

  @override
  ConsumerState<CreateGuildScreen> createState() => _CreateGuildScreenState();
}

class _CreateGuildScreenState extends ConsumerState<CreateGuildScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRÉER UNE GUILDE')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom de la guilde')),
            TextField(controller: _tagController, decoration: const InputDecoration(labelText: 'Tag (ex: [RPG])')),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  ref.read(gameProvider.notifier).createGuild(
                    _nameController.text,
                    _descController.text,
                    _tagController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('CRÉER LA GUILDE'),
            ),
          ],
        ),
      ),
    );
  }
}
