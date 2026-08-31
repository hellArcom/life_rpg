import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';
import '../widgets/add_quest_dialog.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final quests = ref.watch(gameProvider.select((s) => s.quests));
    final categories = ref.watch(gameProvider.select((s) => s.categories));

    return DefaultTabController(
      length: categories.length + 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.questJournal),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              Tab(text: t.all),
              Tab(text: t.daily),
              ...categories.map((cat) => Tab(text: t.translateCategory(cat.label).toUpperCase())),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _QuestList(quests: quests, onEdit: (q) => showAddQuestDialog(context, ref, initialCategory: q.category, existingQuest: q)),
            _QuestList(
              quests: quests.where((q) => q.frequency == QuestFrequency.daily).toList(),
              onEdit: (q) => showAddQuestDialog(context, ref, initialCategory: q.category, existingQuest: q),
            ),
            ...categories.map((cat) {
              final categoryQuests = quests.where((q) => q.category.id == cat.id).toList();
              return _QuestList(quests: categoryQuests, onEdit: (q) => showAddQuestDialog(context, ref, initialCategory: q.category, existingQuest: q));
            }),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          onPressed: () {
            if (categories.isNotEmpty) {
              showAddQuestDialog(context, ref, initialCategory: categories.first);
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _QuestList extends ConsumerWidget {
  final List<Quest> quests;
  final Function(Quest) onEdit;

  const _QuestList({required this.quests, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    if (quests.isEmpty) {
      return Center(child: Text(t.noQuestsInCategory, style: const TextStyle(color: Colors.grey)));
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      onReorderItem: (oldIndex, newIndex) {
        final questId = quests[oldIndex].id;
        final beforeQuestId = newIndex < quests.length ? quests[newIndex].id : null;
        ref.read(gameProvider.notifier).reorderQuests(questId, beforeQuestId);
      },
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _QuestCard(
          key: ValueKey(quest.id),
          quest: quest, 
          onEdit: onEdit,
        );
      },
    );
  }
}

class _QuestCard extends ConsumerWidget {
  final Quest quest;
  final Function(Quest) onEdit;

  const _QuestCard({super.key, required this.quest, required this.onEdit});

  IconData _getIconByName(String iconName) {
    switch (iconName) {
      case 'fitness_center': return Icons.fitness_center;
      case 'menu_book': return Icons.menu_book;
      case 'timer': return Icons.timer;
      case 'groups': return Icons.groups;
      case 'palette': return Icons.palette;
      case 'bolt': return Icons.bolt;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      default: return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final isCompleted = quest.status == QuestStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isCompleted ? Colors.green.withValues(alpha: 0.1) : null,
      child: ListTile(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(quest.title),
              content: Text(quest.description.isEmpty ? t.noDescription : quest.description),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(gameProvider.notifier).deleteQuest(quest.id);
                    Navigator.pop(context);
                  },
                  child: Text(t.delete, style: const TextStyle(color: Colors.red)),
                ),
                TextButton(onPressed: () { Navigator.pop(context); onEdit(quest); }, child: Text(t.modify)),
                TextButton(onPressed: () => Navigator.pop(context), child: Text(t.close)),
              ],
            ),
          );
        },
        leading: Icon(_getIconByName(quest.category.iconName), color: Colors.amber),
        title: Text(
          quest.title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${quest.difficulty.name.toUpperCase()} • +${quest.xpRewardValue} XP'),
            if (quest.reminderDate != null)
              Text('${t.reminder}: ${quest.reminderDate!.day}/${quest.reminderDate!.month} ${quest.reminderDate!.hour.toString().padLeft(2, '0')}:${quest.reminderDate!.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.blue, fontSize: 10)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          onPressed: () => ref.read(gameProvider.notifier).toggleQuestStatus(quest.id),
        ),
      ),
    );
  }
}
