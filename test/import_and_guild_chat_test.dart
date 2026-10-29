import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_test/flutter_test.dart';
import 'package:life_rpg_dev/providers/game_provider.dart';
import 'package:life_rpg_dev/services/chat_service.dart';

void main() {
  group('import de sauvegarde JSON', () {
    test('normalise une sauvegarde ancienne et conserve les données', () {
      final normalized = normalizeImportedGameData(jsonEncode({
        'user': {'uid': '7', 'pseudo': 'Ancien joueur', 'globalXp': 850},
        'quests': [
          {
            'id': 'q1',
            'title': 'Lire',
            'description': '',
            'difficulty': 2,
            'category': {'id': 'mental', 'label': 'Mental'},
            'status': 0,
            'frequency': 1,
          }
        ],
      }));

      final state = GameState.fromJson(normalized);
      expect(normalized['dataVersion'], isNotNull);
      expect(state.user.pseudo, 'Ancien joueur');
      expect(state.user.globalXp, 850);
      expect(state.quests, hasLength(1));
      expect(state.quests.single.difficulty.name, 'medium');
      expect(state.quests.single.frequency.name, 'daily');
    });

    test('remet au format courant les valeurs scalaires et l’ancien journal XP', () {
      final normalized = normalizeImportedGameData(jsonEncode({
        'user': {'globalXp': '250'},
        'level': '3',
        'lootBoxProgress': '2',
        'quests': [],
        'weeklyXpLog': ['1', 2, null, 4, 5, 6, 7, 8],
      }));

      final state = GameState.fromJson(normalized);
      expect(state.user.globalXp, 250);
      expect(state.user.level, 3);
      expect(state.lootBoxProgress, 2);
      expect(state.weeklyXpLog, [2, 0, 4, 5, 6, 7, 8]);
    });

    test('refuse le JSON illisible, une racine inconnue ou une entrée impossible à récupérer', () {
      expect(() => normalizeImportedGameData('{not json'), throwsFormatException);
      expect(() => normalizeImportedGameData('[]'), throwsFormatException);
      expect(() => normalizeImportedGameData('{"unknown": true}'), throwsFormatException);
      expect(() => normalizeImportedGameData('{"quests": "pas une liste"}'), throwsFormatException);
      expect(() => normalizeImportedGameData('{"currentGuild": "pas un objet"}'), throwsFormatException);
      expect(() => normalizeImportedGameData('{"globalXp": "pas un nombre"}'), throwsFormatException);
      expect(() => normalizeImportedGameData('{"weeklyXpLog": ["pas un nombre"]}'), throwsFormatException);
      expect(
        () => normalizeImportedGameData('{"quests": [{"title": "sans catégorie"}]}'),
        throwsFormatException,
      );
      expect(
        () => normalizeImportedGameData(jsonEncode({
          'quests': [
            {'id': 'q1', 'title': 'Valide', 'category': {'id': 'a', 'label': 'A'}},
            'entrée cassée',
          ],
        })),
        throwsFormatException,
      );
      expect(
        () => normalizeImportedGameData(jsonEncode({
          'myGuilds': [{'invalid': true}],
        })),
        throwsFormatException,
      );
    });
  });

  group('chiffrement des messages de guilde', () {
    const key = '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';

    test('émet le format AES-GCM partagé avec le client web', () {
      const plaintext = 'Bonjour la guilde';
      final payload = ChatService.encryptMessage(plaintext, key);
      final parts = payload.split(':');

      expect(parts, hasLength(2));
      expect(base64Decode(parts[0]), hasLength(12));
      expect(base64Decode(parts[1]).length, greaterThanOrEqualTo(16));
      expect(ChatService.decryptMessage(payload, key), plaintext);
      expect(ChatService.decryptMessage(payload, 'f' * 64), isNot(plaintext));
      expect(() => ChatService.encryptMessage(plaintext, 'invalid'), throwsFormatException);
    });

    test('décrypte l’historique avec les clés précédentes après rotation', () {
      const previousKey = '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
      const currentKey = 'ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100';
      const plaintext = 'Message avant rotation';
      final payload = ChatService.encryptMessage(plaintext, previousKey);

      expect(ChatService.decryptMessage(payload, previousKey), plaintext);
      expect(ChatService.decryptMessage(payload, currentKey), isNot(plaintext));
    });

    test('continue à déchiffrer les messages enregistrés dans l’ancien format', () {
      const plaintext = 'Ancien message';
      final iv = encrypt.IV.fromSecureRandom(12);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(encrypt.Key.fromBase16(key), mode: encrypt.AESMode.gcm),
      );
      final ciphertext = encrypter.encrypt(plaintext, iv: iv);
      final legacyPayload = base64Encode([...iv.bytes, ...ciphertext.bytes]);

      expect(ChatService.decryptMessage(legacyPayload, key), plaintext);
    });
  });
}
