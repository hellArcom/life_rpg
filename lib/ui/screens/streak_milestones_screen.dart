import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';

class StreakMilestonesScreen extends ConsumerWidget {
  const StreakMilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final notifier = ref.read(gameProvider.notifier);
    final milestones = notifier.getStreakMilestones();
    final user = ref.watch(gameProvider).user;

    return Scaffold(
      appBar: AppBar(title: Text(t.streakMilestones)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: milestones.length,
        itemBuilder: (context, index) {
          final m = milestones[index];
          final day = m['day'] as int;
          final coins = m['coins'] as int;
          final claimed = m['claimed'] as bool;
          final reached = user.streak >= day;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: claimed
                    ? Colors.green.withValues(alpha: 0.1)
                    : reached
                        ? Colors.amber.withValues(alpha: 0.1)
                        : null,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: claimed
                      ? Colors.green
                      : reached
                          ? Colors.amber
                          : Colors.white12,
                  child: Icon(
                    claimed ? Icons.check : reached ? Icons.bolt : Icons.lock,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  '$day ${t.days}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(claimed
                    ? '${t.rewardClaimed} +$coins💰'
                    : '${t.reward}: +$coins💰'),
                trailing: Text(
                  claimed
                      ? '✓'
                      : reached
                          ? '🎯'
                          : '${day - user.streak} ${t.daysLeft}',
                  style: TextStyle(
                    fontSize: 12,
                    color: claimed
                        ? Colors.green
                        : reached
                            ? Colors.amber
                            : Colors.white38,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
