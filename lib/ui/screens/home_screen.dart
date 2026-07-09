import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';
import '../../core/utils.dart';
import '../widgets/xp_bar.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/character_preview.dart';
import 'character_customization_screen.dart';
import 'streak_milestones_screen.dart';
import 'evening_entry_screen.dart';
import 'evening_history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _celebrationShown = false;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final gameState = ref.watch(gameProvider);
    final user = gameState.user;
    final unlockedBadges = gameState.availableBadges.where((GameBadge b) => user.badgeIds.contains(b.id)).toList();
    final notifier = ref.read(gameProvider.notifier);

    if (gameState.celebrationPending && !_celebrationShown) {
      _celebrationShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => CelebrationOverlay(
              title: 'Quête terminée !',
              subtitle: '+ pièces !',
              onDismiss: () {
                ref.read(gameProvider.notifier).dismissCelebration();
                Navigator.of(context).pop();
              },
            ),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.heroProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditPseudoDialog(context, ref, user.pseudo, t),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section Avatar & Skin Évolutif
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                CharacterPreview(parts: user.characterParts, size: 100),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CharacterCustomizationScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.pseudo,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              t.translateUserTitle(user.currentTitle).toUpperCase(),
              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text('${t.levelPrefix} ${user.level}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            XPBar(currentXp: user.globalXp, level: user.level, label: t.progressionNextLevel),
            const SizedBox(height: 24),

            // Daily reward & streak freeze
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context, '🎁', t.dailyReward,
                    user.lastDailyRewardDate != null && isSameDay(user.lastDailyRewardDate!, DateTime.now())
                        ? 'Jour ${user.dailyRewardDay} ✓' : '${t.dayLabel} ${(user.dailyRewardDay % 7) + 1}',
                    () => notifier.claimDailyReward(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context, '🧊', t.streakFreezeLabel,
                    user.streakFreezeDaysLeft > 0 ? '${user.streakFreezeDaysLeft}j ⛵' : '-50💰',
                    () => _confirmStreakFreeze(context, t, notifier),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                Expanded(child: _buildStatCard(context, t.streak, '${user.streak} j', Icons.fireplace, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, t.multiplier, 'x${user.xpMultiplier.toStringAsFixed(1)}', Icons.trending_up, Colors.cyan)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, t.quests,
                    '${gameState.quests.where((q) => q.status == QuestStatus.completed).length}',
                    Icons.check_circle, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, t.coinsLabel, '${user.coins}💰', Icons.monetization_on, Colors.amber)),
              ],
            ),
            const SizedBox(height: 24),

            // Streak milestones & Evening entry
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context, '🏆', t.milestones,
                    user.streak > 0 ? '${user.streak} / ${UserProfile.streakMilestones.firstWhere((m) => m > user.streak, orElse: () => user.streak)} j' : 'Démarrer',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakMilestonesScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context, '🌙', t.eveningEntryTitle,
                    notifier.canSubmitEveningEntry() ? '+10💰' : '✓ ${t.eveningDone}',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => notifier.canSubmitEveningEntry()
                            ? const EveningEntryScreen()
                            : const EveningHistoryScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Loot box progress
            if (gameState.lootBoxes.isNotEmpty)
              _buildLootBoxProgress(context, gameState, t),
            const SizedBox(height: 24),

            _buildBadgesSection(context, unlockedBadges, t, user),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String emoji, String title, String subtitle, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLootBoxProgress(BuildContext context, GameState gameState, Translations t) {
    if (gameState.lootBoxes.isEmpty) return const SizedBox.shrink();
    final box = gameState.lootBoxes.first;
    final ready = gameState.lootBoxProgress >= box.questsRequired;
    final progress = (gameState.lootBoxProgress / box.questsRequired).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: ready ? () => _openLootBoxDialog(context, box, t) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ready ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ready ? Colors.green.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(box.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('${t.lootBox} : ${box.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (ready)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Ouvrir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                else
                  Text('${gameState.lootBoxProgress}/${box.questsRequired}', style: const TextStyle(color: Colors.amber)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ready ? 1.0 : progress,
                backgroundColor: Colors.white12,
                color: ready ? Colors.green : Colors.amber,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLootBoxDialog(BuildContext context, LootBox box, Translations t) {
    final notifier = ref.read(gameProvider.notifier);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CelebrationOverlay(
        title: '${box.icon} ${box.name}',
        subtitle: 'Ouverture...',
        onDismiss: () {
          final result = notifier.openLootBox();
          Navigator.of(context).pop();
          if (result != null && context.mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) _showLootBoxReward(context, box, result);
            });
          }
        },
      ),
    );
  }

  void _showLootBoxReward(BuildContext context, LootBox box, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${box.icon} Récompense !'),
        content: Text(msg, style: const TextStyle(fontSize: 18, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Super !'),
          ),
        ],
      ),
    );
  }

  void _confirmStreakFreeze(BuildContext context, Translations t, GameNotifier notifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🧊 Gel de série'),
        content: const Text('Dépenser 50 pièces pour activer le gel de série ?\nUn jour manqué ne cassera pas votre série.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              notifier.activateStreakFreeze();
              Navigator.of(context).pop();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showEditPseudoDialog(BuildContext context, WidgetRef ref, String currentPseudo, Translations t) {
    String newPseudo = currentPseudo;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.changePseudo),
        content: TextFormField(
          initialValue: currentPseudo,
          decoration: InputDecoration(labelText: t.newPseudo),
          onChanged: (v) => newPseudo = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () {
              final trimmed = newPseudo.trim();
              if (trimmed.isNotEmpty) {
                ref.read(gameProvider.notifier).updatePseudo(trimmed);
                Navigator.pop(context);
              }
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, List<GameBadge> unlockedBadges, Translations t, UserProfile user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.myExpertBadges, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        if (unlockedBadges.isEmpty)
          Center(child: Text(t.noBadges, style: const TextStyle(color: Colors.grey, fontSize: 12))),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: unlockedBadges.length,
          itemBuilder: (context, index) {
            final badge = unlockedBadges[index];
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.withValues(alpha: 0.2), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(badge.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.translateBadgeTitle(badge.id), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(t.translateBadgeDesc(badge.id), style: const TextStyle(fontSize: 8, color: Colors.grey), maxLines: 2),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
