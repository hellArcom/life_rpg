import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';

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
    final gameState = ref.watch(gameProvider);
    final activeBets = gameState.bets.where((b) => b.status == BetStatus.active).toList();
    final pastBets = gameState.bets.where((b) => b.status != BetStatus.active).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('MES PARIS')),
      body: CustomScrollView(
        slivers: [
          if (activeBets.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('EN COURS', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
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
                child: Text('HISTORIQUE', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
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
        onPressed: () => _showAddBetDialog(context, ref),
        child: const Icon(Icons.add_task),
      ),
    );
  }

  void _showAddBetDialog(BuildContext context, WidgetRef ref) {
    final gameState = ref.read(gameProvider);
    final quests = gameState.quests.where((q) => q.status == QuestStatus.todo).toList();
    
    showDialog(
      context: context,
      builder: (context) {
        String title = '';
        List<String> selectedQuestIds = [];
        DateTime deadline = DateTime.now().add(const Duration(days: 1));
        int rewardXp = 100;
        int penaltyXp = 50;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Nouveau Pari'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Titre du pari'),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 16),
                  const Text('Quêtes liées:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      });
                    },
                  )),
                  ListTile(
                    title: const Text('Date limite'),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Récompense XP'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => rewardXp = int.tryParse(v) ?? 100,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Pénalité XP'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => penaltyXp = int.tryParse(v) ?? 50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () {
                  if (title.isNotEmpty && selectedQuestIds.isNotEmpty) {
                    ref.read(gameProvider.notifier).addBet(Bet(
                      id: DateTime.now().toString(),
                      title: title,
                      linkedQuestIds: selectedQuestIds,
                      deadline: deadline,
                      rewardXp: rewardXp,
                      penaltyXp: penaltyXp,
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Parier'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BetCard extends StatelessWidget {
  final Bet bet;

  const _BetCard({required this.bet});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = bet.deadline.difference(now);
    final isExpired = remaining.isNegative;
    final color = bet.status == BetStatus.won ? Colors.green : (bet.status == BetStatus.lost ? Colors.red : Colors.amber);

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
                  child: Text(bet.status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (bet.status == BetStatus.active) ...[
              Text(
                isExpired ? 'Temps écoulé !' : 'Il reste: ${remaining.inDays}j ${remaining.inHours % 24}h ${remaining.inMinutes % 60}min',
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
