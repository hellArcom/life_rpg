import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final leaderboard = gameState.leaderboard;

    return Scaffold(
      appBar: AppBar(title: const Text('CLASSEMENT MONDIAL')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final entry = leaderboard[index];
          final isMe = entry.pseudo == gameState.user.pseudo;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isMe ? Theme.of(context).colorScheme.primary : Colors.white10),
            ),
            child: Row(
              children: [
                _buildRankIcon(index + 1),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.pseudo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Série: ${entry.streak} jours', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('NIV ${entry.level}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    Text('${entry.totalXp} XP', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankIcon(int rank) {
    if (rank == 1) return const Text('🥇', style: TextStyle(fontSize: 24));
    if (rank == 2) return const Text('🥈', style: TextStyle(fontSize: 24));
    if (rank == 3) return const Text('🥉', style: TextStyle(fontSize: 24));
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
      child: Text(rank.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
