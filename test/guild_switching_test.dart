import 'package:flutter_test/flutter_test.dart';
import 'package:life_rpg_dev/providers/game_provider.dart';

// L'app autorise plusieurs guildes (jusqu'à 5, comme le site web). Depuis la
// liste « Mes guildes » on choisit celle à voir, et le retour en arrière
// (GameNotifier.closeGuild) doit revenir à la liste pour pouvoir changer de
// guilde sans perdre les autres guildes de l'utilisateur.
void main() {
  group('changement de guilde', () {
    GameState stateWithTwoGuilds() => GameState.fromJson({
      'user': {'uid': '1', 'pseudo': 'Testeur'},
      'currentGuild': {'id': 'g1', 'name': 'Guilde 1'},
      'myGuilds': [
        {'id': 'g1', 'name': 'Guilde 1'},
        {'id': 'g2', 'name': 'Guilde 2'},
      ],
      'guildMembers': [
        {
          'id': 'm1',
          'pseudo': 'Membre',
          'level': 3,
          'xp': 10,
          'role': 'member',
        },
      ],
      'guildMessages': [
        {
          'id': 'msg1',
          'senderName': 'Membre',
          'senderId': 'm1',
          'text': 'salut',
          'timestamp': '2026-01-01T10:00:00Z',
        },
      ],
    });

    test('fermer la guilde active vide la vue de détail mais garde la liste', () {
      final state = stateWithTwoGuilds();
      expect(state.currentGuild, isNotNull);
      expect(state.guildMembers, hasLength(1));

      // Même transition que GameNotifier.closeGuild().
      final cleared = state.copyWith(
        clearCurrentGuild: true,
        guildMembers: [],
        guildQuests: [],
        guildLogs: [],
        guildMessages: [],
      );

      expect(cleared.currentGuild, isNull);
      expect(cleared.guildMembers, isEmpty);
      expect(cleared.guildMessages, isEmpty);
      expect(
        cleared.myGuilds.map((g) => g.id).toList(),
        ['g1', 'g2'],
        reason: 'les autres guildes doivent rester sélectionnables',
      );
    });

    test('on peut sélectionner une autre guilde depuis la liste', () {
      final state = stateWithTwoGuilds();
      final other = state.myGuilds.firstWhere((g) => g.id == 'g2');

      // Même transition que GameNotifier.selectGuild().
      final switched = state.copyWith(currentGuild: other, guildMessages: []);

      expect(switched.currentGuild?.id, 'g2');
      expect(switched.guildMessages, isEmpty);
      expect(switched.myGuilds, hasLength(2));
    });
  });
}
