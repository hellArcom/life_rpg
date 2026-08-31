import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';

class GuildLeaderboardScreen extends ConsumerStatefulWidget {
  const GuildLeaderboardScreen({super.key});

  @override
  ConsumerState<GuildLeaderboardScreen> createState() => _GuildLeaderboardScreenState();
}

class _GuildLeaderboardScreenState extends ConsumerState<GuildLeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).loadGuildLeaderboard();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(gameProvider.notifier).loadGuildLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final guildLeaderboard = ref.watch(gameProvider.select((s) => s.guildLeaderboard));

    return Scaffold(
      appBar: AppBar(
        title: const Text('CLASSEMENT DES GUILDES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(gameProvider.notifier).loadGuildLeaderboard(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: guildLeaderboard.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucune guilde', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Les guildes apparaîtront ici', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: guildLeaderboard.length,
                itemBuilder: (context, index) {
                  final g = guildLeaderboard[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildRankCircle(index + 1),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            child: Text(
                              g.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  '${g.memberCount}/${g.maxMembers} membres • ${g.totalXp} XP total',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '#${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                              ),
                              Text(
                                'Niv. moy: ${g.avgLevel.toStringAsFixed(1)}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildRankCircle(int rank) {
    if (rank == 1) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(child: Text('1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))),
      );
    }
    if (rank == 2) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(child: Text('2', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))),
      );
    }
    if (rank == 3) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(child: Text('3', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
      );
    }
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
      child: Text(rank.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}
