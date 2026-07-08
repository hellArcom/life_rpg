import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_rpg/providers/game_provider.dart';
import 'package:life_rpg/models/game_models.dart';

// Test simple : Override de provider pour éviter OfflineManager
void main() {
  test('Completing a quest adds correct XP to user', () {
    final container = ProviderContainer(overrides: []);
    final notifier = container.read(gameProvider.notifier);

    final quest = Quest(
      id: 'q1',
      title: 'Test Quest',
      description: '',
      difficulty: Difficulty.easy, // XP = 50
      category: notifier.state.categories.first,
    );
    
    notifier.addQuest(quest);
    
    final initialXp = container.read(gameProvider).user.globalXp;
    
    notifier.toggleQuestStatus(quest.id);
    
    final finalXp = container.read(gameProvider).user.globalXp;
    
    expect(finalXp, initialXp + 50);
  });
}
