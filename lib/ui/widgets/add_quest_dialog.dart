import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';

void showAddQuestDialog(BuildContext context, WidgetRef ref, {SkillCategory? initialCategory, Quest? existingQuest}) {
  final t = ref.read(translationsProvider);
  final gameState = ref.read(gameProvider);
  final categories = gameState.categories;
  
  if (categories.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Créez d\'abord une catégorie de compétence dans les réglages.')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) {
      String title = existingQuest?.title ?? '';
      String description = existingQuest?.description ?? '';
      Difficulty difficulty = existingQuest?.difficulty ?? Difficulty.easy;
      SkillCategory category = existingQuest?.category ?? initialCategory ?? categories.first;
      QuestFrequency frequency = existingQuest?.frequency ?? QuestFrequency.once;
      DateTime? reminderDate = existingQuest?.reminderDate;
      DateTime? startTime = existingQuest?.startTime;
      DateTime? dueDate = existingQuest?.dueDate;

      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingQuest == null ? t.newQuest : t.editQuest),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: t.title),
                  initialValue: title,
                  onChanged: (v) => title = v,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: t.description),
                  initialValue: description,
                  onChanged: (v) => description = v,
                  maxLines: 3,
                ),
                ExpansionTile(
                  title: Text(t.planningReminder, style: const TextStyle(fontSize: 14)),
                  children: [
                    ListTile(
                      title: Text(t.start),
                      subtitle: Text(startTime == null ? t.notDefined : '${startTime!.day}/${startTime!.month} ${startTime!.hour}:${startTime!.minute}'),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: startTime ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2100));
                        if (date != null && context.mounted) {
                          final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(startTime ?? DateTime.now()));
                          if (time != null) {
                            setState(() => startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                          }
                        }
                      },
                      trailing: startTime != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => startTime = null)) : null,
                    ),
                    ListTile(
                      title: Text(t.deadlineEnd),
                      subtitle: Text(dueDate == null ? t.notDefined : '${dueDate!.day}/${dueDate!.month} ${dueDate!.hour}:${dueDate!.minute}'),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: dueDate ?? startTime ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2100));
                        if (date != null && context.mounted) {
                          final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(dueDate ?? startTime ?? DateTime.now()));
                          if (time != null) {
                            setState(() => dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                          }
                        }
                      },
                      trailing: dueDate != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => dueDate = null)) : null,
                    ),
                    ListTile(
                      title: Text(t.reminder),
                      subtitle: Text(reminderDate == null ? t.none : '${reminderDate!.day}/${reminderDate!.month} ${reminderDate!.hour}:${reminderDate!.minute}'),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: reminderDate ?? startTime ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (date != null && context.mounted) {
                          final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(reminderDate ?? startTime ?? DateTime.now()));
                          if (time != null) {
                            setState(() => reminderDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                          }
                        }
                      },
                      trailing: reminderDate != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => reminderDate = null)) : null,
                    ),
                    DropdownButtonFormField<QuestFrequency>(
                      initialValue: frequency,
                      items: QuestFrequency.values.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                      onChanged: (v) => setState(() => frequency = v!),
                      decoration: InputDecoration(labelText: t.frequency),
                    ),
                  ],
                ),
                DropdownButtonFormField<Difficulty>(
                  initialValue: difficulty,
                  items: Difficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                  onChanged: (v) => setState(() => difficulty = v!),
                  decoration: InputDecoration(labelText: t.difficulty),
                ),
                DropdownButtonFormField<SkillCategory>(
                  initialValue: category,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(t.translateCategory(c.label)))).toList(),
                  onChanged: (v) => setState(() => category = v!),
                  decoration: InputDecoration(labelText: t.skill),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
            ElevatedButton(
              onPressed: () {
                if (title.isNotEmpty) {
                  if (existingQuest == null) {
                    ref.read(gameProvider.notifier).addQuest(Quest(
                      id: DateTime.now().toString(),
                      title: title,
                      description: description,
                      difficulty: difficulty,
                      category: category,
                      frequency: frequency,
                      reminderDate: reminderDate,
                      startTime: startTime,
                      dueDate: dueDate,
                    ));
                  } else {
                    ref.read(gameProvider.notifier).updateQuest(existingQuest.copyWith(
                      title: title,
                      description: description,
                      difficulty: difficulty,
                      category: category,
                      frequency: frequency,
                      reminderDate: reminderDate,
                      startTime: startTime,
                      dueDate: dueDate,
                    ));
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(existingQuest == null ? t.create : t.modify),
            ),
          ],
        ),
      );
    },
  );
}
