import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';

class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final xpLog = notifier.getWeeklyXpLog();
    final totalXp = notifier.totalWeeklyXp;
    final completedQuests = gameState.quests.where((q) => q.status == QuestStatus.completed).length;

    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return Scaffold(
      appBar: AppBar(title: Text(t.weeklySummary)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('$totalXp', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.cyan)),
                    Text('XP cette semaine', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Text('$completedQuests quêtes complétées', style: TextStyle(color: Colors.amber)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('XP par jour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: xpLog.reduce((a, b) => a > b ? a : b).toDouble().clamp(100, double.infinity),
                  barGroups: xpLog.asMap().entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(
                      toY: e.value.toDouble().clamp(0, double.infinity),
                      color: Colors.cyan,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    )],
                  )).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                        return Text(days[idx], style: const TextStyle(fontSize: 10));
                      },
                    )),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
