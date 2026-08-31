import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';

class BetsScreen extends ConsumerStatefulWidget {
  const BetsScreen({super.key});

  @override
  ConsumerState<BetsScreen> createState() => _BetsScreenState();
}

class _BetsScreenState extends ConsumerState<BetsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      ref.read(gameProvider.notifier).checkBets();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final bets = ref.watch(gameProvider.select((s) => s.bets));
    final activeBets = bets.where((b) => b.status == BetStatus.active).toList();
    final pastBets = bets.where((b) => b.status != BetStatus.active).toList();

    return Scaffold(
      appBar: AppBar(title: Text(t.bets.toUpperCase())),
      body: CustomScrollView(
        slivers: [
          if (activeBets.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(t.inProgress, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _BetCard(bet: activeBets[index]),
              childCount: activeBets.length,
            ),
          ),
          if (pastBets.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(t.history, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _BetCard(bet: pastBets[index]),
              childCount: pastBets.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAddBetDialog(context, ref),
        child: const Icon(Icons.add_task),
      ),
    );
  }

  void _showAddBetDialog(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final gameState = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final quests = gameState.quests.where((q) => q.status == QuestStatus.todo).toList();

    showDialog(
      context: context,
      builder: (context) {
        String title = '';
        List<String> selectedQuestIds = [];
        DateTime deadline = DateTime.now().add(const Duration(days: 1));
        int rewardXp = 100;
        int penaltyXp = 50;
        final rewardController = TextEditingController(text: rewardXp.toString());
        final penaltyController = TextEditingController(text: penaltyXp.toString());

        int currentCap() {
          if (selectedQuestIds.isEmpty) return 300;
          final linked = quests.where((q) => selectedQuestIds.contains(q.id));
          if (linked.isEmpty) return 300;
          return linked.fold(0, (sum, q) => sum + q.difficulty.xpBase * GameNotifier.betXpMultiplier);
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final cap = currentCap();
            return AlertDialog(
            title: Text(t.newBet),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: t.betTitleLabel),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 16),
                  Text(t.linkedQuests, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...quests.map((q) => CheckboxListTile(
                    title: Text(q.title),
                    value: selectedQuestIds.contains(q.id),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedQuestIds.add(q.id);
                        } else {
                          selectedQuestIds.remove(q.id);
                        }
                        final newCap = currentCap();
                        rewardXp = rewardXp.clamp(0, newCap);
                        penaltyXp = penaltyXp.clamp(0, newCap);
                        rewardController.text = rewardXp.toString();
                        penaltyController.text = penaltyXp.toString();
                      });
                    },
                  )),
                  ListTile(
                    title: Text(t.deadline),
                    subtitle: Text('${deadline.day}/${deadline.month}/${deadline.year} ${deadline.hour}:${deadline.minute}'),
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: deadline, firstDate: DateTime.now(), lastDate: DateTime(2100));
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(deadline));
                        if (time != null) {
                          setState(() => deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                        }
                      }
                    },
                  ),
                  Text('${t.maxAllowed} $cap XP', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rewardController,
                          decoration: InputDecoration(labelText: t.rewardXp),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            rewardXp = (int.tryParse(v) ?? 0).clamp(0, cap);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: penaltyController,
                          decoration: InputDecoration(labelText: t.penaltyXp),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            penaltyXp = (int.tryParse(v) ?? 0).clamp(0, cap);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (title.isNotEmpty && selectedQuestIds.isNotEmpty) {
                    final safeCap = notifier.maxBetRewardXp(selectedQuestIds);
                    ref.read(gameProvider.notifier).addBet(Bet(
                      id: DateTime.now().toString(),
                      title: title,
                      linkedQuestIds: selectedQuestIds,
                      deadline: deadline,
                      rewardXp: rewardXp.clamp(0, safeCap),
                      penaltyXp: penaltyXp.clamp(0, safeCap),
                    ));
                    Navigator.pop(context);
                  }
                },
                child: Text(t.placeBet),
              ),
            ],
            );
          },
        );
      },
    );
  }
}

class _BetCard extends ConsumerWidget {
  final Bet bet;

  const _BetCard({required this.bet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final now = DateTime.now();
    final remaining = bet.deadline.difference(now);
    final isExpired = remaining.isNegative;
    final color = bet.status == BetStatus.won ? Colors.green : (bet.status == BetStatus.lost ? Colors.red : Colors.amber);
    final statusText = bet.status == BetStatus.won
        ? t.statusWon
        : (bet.status == BetStatus.lost ? t.statusLost : t.statusActive);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(bet.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusText, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (bet.status == BetStatus.active) ...[
              Text(
                isExpired
                    ? t.timeUp
                    : '${t.timeLeft} ${remaining.inDays}j ${remaining.inHours % 24}h ${remaining.inMinutes % 60}min',
                style: TextStyle(color: isExpired ? Colors.red : Colors.blue, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: isExpired ? 1.0 : 1.0 - (remaining.inMinutes / bet.deadline.difference(bet.createdAt).inMinutes).clamp(0, 1),
                backgroundColor: Colors.white10,
                color: color,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🏆 +${bet.rewardXp} XP', style: const TextStyle(color: Colors.green, fontSize: 12)),
                Text('💀 -${bet.penaltyXp} XP', style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
