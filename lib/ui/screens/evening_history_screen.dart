import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';
import 'evening_entry_screen.dart';

class EveningHistoryScreen extends ConsumerWidget {
  const EveningHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final log = ref.watch(gameProvider).eveningLog;
    final sorted = List<EveningEntry>.from(log)..sort((a, b) => b.date.compareTo(a.date));
    final canSubmit = ref.read(gameProvider.notifier).canSubmitEveningEntry();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.eveningHistoryTitle),
        actions: [
          if (canSubmit)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: t.eveningEntryTitle,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EveningEntryScreen()),
              ),
            ),
        ],
      ),
      body: sorted.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(t.eveningHistoryEmpty, style: const TextStyle(color: Colors.grey)),
                  if (canSubmit) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EveningEntryScreen()),
                      ),
                      icon: const Icon(Icons.edit_note),
                      label: Text(t.eveningSubmit),
                    ),
                  ],
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final e = sorted[index];
                return _EntryCard(
                  entry: e,
                  onEdit: () => _showEditDialog(context, ref, e, t),
                  onDelete: () => _confirmDelete(context, ref, e, t),
                );
              },
            ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, EveningEntry entry, Translations t) {
    final controller = TextEditingController(text: entry.text);
    final moods = ['😊', '😐', '😢', '😤', '🥱'];
    String selectedMood = entry.mood;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(t.modify),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.howAreYou, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: moods.map((m) => GestureDetector(
                  onTap: () => setState(() => selectedMood = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selectedMood == m ? Colors.amber.withValues(alpha: 0.2) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: selectedMood == m ? Border.all(color: Colors.amber) : null,
                    ),
                    child: Text(m, style: const TextStyle(fontSize: 24)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: t.eveningHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  ref.read(gameProvider.notifier).updateEveningEntry(entry.id, text, selectedMood);
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, EveningEntry entry, Translations t) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.deleteEntryTitle),
        content: Text(entry.coinReward > 0
            ? '${t.delCoins1}${entry.coinReward}${t.delCoins2}'
            : t.deleteEntryMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(gameProvider.notifier).deleteEveningEntry(entry.id);
              Navigator.of(dialogContext).pop();
            },
            child: Text(t.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  final EveningEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryCard({required this.entry, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final dateStr = DateFormat.yMd(Localizations.localeOf(context).languageCode).format(entry.date);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(entry.mood, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                if (entry.coinReward > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('+${entry.coinReward}💰', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: t.edit,
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: t.delete,
                  visualDensity: VisualDensity.compact,
                  color: Colors.red,
                  onPressed: onDelete,
                ),
              ],
            ),
            if (entry.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(entry.text, style: const TextStyle(fontSize: 14, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}
