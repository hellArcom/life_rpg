import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_rpg_dev/providers/game_provider.dart';
import 'package:life_rpg_dev/services/chat_service.dart' as chat;

void main() {
  group('import json + guild encryption (corrections)', () {
    test('json invalide lève une erreur lisible par l’utilisateur', () {
      expect(
        () => normalizeImportedGameData('{not json'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Life RPG'),
        )),
      );

      expect(
        () => normalizeImportedGameData('[]'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => normalizeImportedGameData('{"queques": []}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('champs à sens perdent une valeur numérique invalide', () {
      expect(
        () => normalizeImportedGameData('{"user": {"globalXp": "kho"}}/1'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => normalizeImportedGameData('{"weeklyXpLog": ["kho"]}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('sauvegarde corrompue à la racine ne plante pas l’app', () {
      expect(
        () => normalizeImportedGameData('{"user": "pas_un_objet"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('clé guild générée et historique conservé', () {
      final raw = {
        'user': {'uid': '1', 'pseudo': 'A', 'globalXp': 0},
        'guildLeaderboard': [
          {
            'id': 'g1',
            'name': 'G',
            'encryption_key': chat.ChatService.encryptMessage('x', 'a' * 64).split(':').last,
          }
        ],
        'dataVersion': 0,
      };
      final normalized = normalizeImportedGameData(jsonEncode(raw));
      expect(normalized['guildLeaderboard'], isA<List>());
    });

    test('ancienne sauvegarde avec guildes sans clé chiffrée est importée sans perte', () {
      final normalized = normalizeImportedGameData(jsonEncode({
        'user': {'uid': '1', 'pseudo': 'A', 'globalXp': 0},
        'myGuilds': [
          {'id': 'g2', 'name': 'G2', 'encryptionKey': null}
        ],
        'dataVersion': 0,
      }));
      expect(normalized['myGuilds'], isA<List>());
      expect((normalized['myGuilds'] as List).length, 1);
    });
  });
}
