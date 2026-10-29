import 'package:flutter_test/flutter_test.dart';
import 'package:life_rpg_dev/models/character_catalog.g.dart';
import 'package:life_rpg_dev/models/character_part.dart';
import 'package:life_rpg_dev/models/game_models.dart';

void main() {
  group('Peaux de personnage', () {
    test('toutes les peaux sont disponibles au niveau 1 et gratuites', () {
      final skins = kCharacterParts
          .where((p) => p.category == CharacterCategory.skin)
          .toList();
      expect(skins, hasLength(5));
      for (final skin in skins) {
        expect(skin.unlockLevel, 1, reason: '${skin.id} doit être débloquée au niveau 1');
        expect(skin.cost, 0, reason: '${skin.id} doit être gratuite');
      }
    });

    test('UserProfile autorise toutes les peaux au niveau 1', () {
      final user = UserProfile(uid: 'test', pseudo: 'test', level: 1);
      for (final part in UserProfile.allParts.where((p) => p.category == 'skin')) {
        expect(user.canUnlockPart(part.id), isTrue, reason: part.id);
      }
    });
  });
}
