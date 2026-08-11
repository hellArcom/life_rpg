import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../widgets/xp_bar.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

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
    final skills = ref.watch(gameProvider.select((s) => s.skills));

    return Scaffold(
      appBar: AppBar(
        title: const Text('COMPÉTENCES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context, ref),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: skills.length,
        onReorderItem: (oldIndex, newIndex) {
          ref.read(gameProvider.notifier).reorderSkills(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final skill = skills[index];
          return Container(
            key: ValueKey(skill.category.id),
            margin: const EdgeInsets.only(bottom: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.amberAccent,
                      child: Icon(_getIconByName(skill.category.iconName), color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill.category.label.toUpperCase(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('Niveau ${skill.level}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                XPBar(
                  currentXp: skill.xp,
                  level: skill.level,
                  label: '',
                ),
                const SizedBox(height: 24),
                const Text('PROGRESSION RÉCENTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: skill.xpHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    String label = '';
    String selectedIcon = 'star';
    final List<String> availableIcons = ['star', 'fitness_center', 'menu_book', 'timer', 'groups', 'palette', 'bolt', 'work', 'school'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle catégorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Nom de la compétence'),
                onChanged: (v) => label = v,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedIcon,
                items: availableIcons.map((icon) => DropdownMenuItem(
                  value: icon,
                  child: Row(children: [Icon(_getIconByName(icon)), const SizedBox(width: 10), Text(icon)]),
                )).toList(),
                onChanged: (v) => setState(() => selectedIcon = v!),
                decoration: const InputDecoration(labelText: 'Icône'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (label.isNotEmpty) {
                  ref.read(gameProvider.notifier).addCategory(label, selectedIcon);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
