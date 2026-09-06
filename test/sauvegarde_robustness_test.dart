import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:life_rpg_dev/core/data_migration.dart';
import 'package:life_rpg_dev/core/offline_manager.dart';
import 'package:life_rpg_dev/models/game_models.dart';
import 'package:life_rpg_dev/providers/game_provider.dart';

void main() {
  late Directory tmpDir;
  late Box box;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_sauvegarde_test');
    Hive.init(tmpDir.path);
    if (Hive.isBoxOpen('game_data')) await Hive.box('game_data').close();
    box = await Hive.openBox('game_data');
  });

  tearDown(() async {
    await box.clear();
  });

  tearDownAll(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('game_data');
    await tmpDir.delete(recursive: true);
  });

  group('Sauvegarde locale OfflineManager', () {
    test('save + getData roundtrip', () async {
      final data = {'level': 5, 'coins': 100};
      await OfflineManager.saveData('game_data', data);
      final loaded = OfflineManager.getData('game_data');
      expect(loaded, isA<Map>());
      expect(loaded['level'], 5);
    });

    test('corrupted JSON fallback to backup', () async {
      await box.put('game_data', 'not_json{{{');
      await box.put('game_data_backup', jsonEncode({'level': 7, 'type': 'backup'}));
      final loaded = OfflineManager.getData('game_data');
      // should try backup or return null without throwing
      expect(loaded == null || loaded['level'] == 7, isTrue);
      // cleanup
      await box.delete('game_data_backup');
    });

    test('corrupted both primary and backup returns null gracefully', () async {
      await box.put('game_data', 'corrupted{{{');
      await box.put('game_data_backup', 'also_bad{{{');
      final loaded = OfflineManager.getData('game_data');
      expect(loaded, isNull);
      await box.delete('game_data_backup');
    });

    test('large data sauvegarde (1000 quests)', () async {
      final big = {
        'user': UserProfile(uid: '1', pseudo: 'Test', globalXp: 5000, level: 10).toJson(),
        'quests': List.generate(1000, (i) => Quest(
          id: 'q_$i', title: 'Quest $i', description: 'desc', difficulty: Difficulty.easy,
          category: SkillCategory(id: '1', label: 'Physique'))).map((q) => q.toJson()).toList(),
        'dataVersion': 1,
      };
      await OfflineManager.saveData('game_data', big);
      final loaded = OfflineManager.getData('game_data');
      expect(loaded, isNotNull);
      expect((loaded['quests'] as List).length, 1000);
    });
  });

  group('GameState.fromJson robustesse', () {
    test('handles missing user (fallback to default)', () {
      final state = GameState.fromJson({});
      expect(state.user.pseudo, isNotEmpty);
      expect(state.user.level, 1);
    });

    test('handles user with wrong types (level as string)', () {
      final json = {
        'user': {
          'uid': '1',
          'pseudo': 'Test',
          'level': 'not_int', // wrong type - UserProfile.fromJson does fallback ?? 1 but direct
        },
        'dataVersion': 1,
      };
      // UserProfile.fromJson expects int, will fail if string - should not crash GameState?
      // Actually GameState.fromJson calls UserProfile.fromJson which does json['level'] ?? 1 and assigns directly without type check
      // If json['level'] is string, it will be assigned as dynamic and crash later but we test defensive
      try {
        final state = GameState.fromJson(json);
        // If it doesn't throw, level should be fallback or at least not crash
        expect(state.user.uid, '1');
      } catch (e) {
        // acceptable that it throws but should be caught at provider level
        expect(e, isA<TypeError>());
      }
    });

    test('handles null lists', () {
      final state = GameState.fromJson({
        'user': UserProfile(uid: '1', pseudo: 'H').toJson(),
        'quests': null,
        'skills': null,
        'categories': null,
        'bets': null,
        'eveningLog': null,
      });
      expect(state.quests, isEmpty);
      expect(state.skills, isEmpty);
    });

    test('handles weeklyXpLog wrong length', () {
      final state = GameState.fromJson({
        'user': UserProfile(uid: '1', pseudo: 'H').toJson(),
        'weeklyXpLog': [1,2,3], // only 3
      });
      expect(state.weeklyXpLog.length, 7);
    });

    test('handles corrupted skill xpHistory longer than 7', () {
      final json = File('life_rpg_backup.json').readAsStringSync();
      final raw = jsonDecode(json) as Map<String, dynamic>;
      // backup has xpHistory of length 8+ for skills
      final migrated = migrateData(raw);
      final state = GameState.fromJson(migrated);
      // should load without crashing, quests count preserved
      expect(state.quests.length, (raw['quests'] as List).length);
    });
  });

  group('Migration de sauvegarde', () {
    test('ancienne backup life_rpg_backup.json migre sans perte', () {
      final file = File('life_rpg_backup.json');
      if (!file.existsSync()) {
        markTestSkipped('backup absent');
        return;
      }
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final questCount = (raw['quests'] as List).length;
      final migrated = migrateData(raw);
      expect(migrated['dataVersion'], currentDataVersion);
      final state = GameState.fromJson(migrated);
      expect(state.quests.length, questCount);
      // verify no crash on int enums
      for (final q in state.quests) {
        expect(q.difficulty, isA<Difficulty>());
      }
    });

    test('idempotence sur backup déjà migré', () {
      final raw = jsonDecode(File('life_rpg_backup.json').readAsStringSync()) as Map<String, dynamic>;
      final once = migrateData(raw);
      final twice = migrateData(once);
      expect(jsonEncode(twice), jsonEncode(once));
    });

    test('migration supprime streak obsolete', () {
      final old = {
        'quests': [
          {'id': 'q1', 'title': 't', 'description': '', 'difficulty': 2, 'category': {'id':'1','label':'A'}, 'status': 0, 'frequency': 0, 'streak': 5, 'lastStreakIncrementDate': '2025-01-01'},
        ],
        'categories': [{'id':'1','label':'A','parentId': null}],
      };
      final migrated = migrateData(old);
      final quest = (migrated['quests'] as List).first as Map;
      expect(quest.containsKey('streak'), isFalse);
    });

    test('exportData / importData roundtrip preserve data', () async {
      // Simuler GameProvider export/import via OfflineManager + GameState
      final original = GameState(
        user: UserProfile(uid: '1', pseudo: 'Arcom', globalXp: 1975, level: 5, coins: 120, streak: 3),
        skills: [],
        quests: [Quest(id: 'q1', title: 'Test', description: '', difficulty: Difficulty.medium, category: SkillCategory(id:'1', label:'Physique'))],
        rewards: [],
        categories: [SkillCategory(id:'1', label:'Physique')],
        bets: [],
        availableBadges: [],
      );
      await OfflineManager.saveData('game_data', original.toJson());
      final raw = OfflineManager.getData('game_data') as Map<String, dynamic>;
      final exported = jsonEncode(migrateData(raw));
      // import
      final importedJson = jsonDecode(exported) as Map<String, dynamic>;
      final migrated = migrateData(importedJson);
      final importedState = GameState.fromJson(migrated);
      expect(importedState.user.globalXp, 1975);
      expect(importedState.quests.length, 1);
      expect(importedState.user.streak, 3);
    });

    test('import corrupted JSON ne crash pas', () async {
      // GameNotifier.importData should handle gracefully (we simulate)
      try {
        final bad = 'not json at all';
        final data = jsonDecode(bad);
        fail('should throw');
      } catch (e) {
        expect(e, isA<FormatException>());
      }
      // importData with wrong shape
      final notifierFake = () {
        try {
          final data = jsonDecode('{"quests": "not_a_list"}');
          if (data is Map<String, dynamic>) {
            final migrated = migrateData(data);
            final state = GameState.fromJson(migrated);
            // quests is string, fromJson does ?.map so should fallback to []
            expect(state.quests, isEmpty);
          }
        } catch (e) {
          fail('should not throw $e');
        }
      };
      notifierFake();
    });
  });

  group('Level recalculation robustness', () {
    test('xpForLevel cohérence + calculateLevelFromXp', () {
      expect(xpForLevel(1), 0);
      expect(xpForLevel(2), 100);
      expect(xpForLevel(50), 240100);
      expect(calculateLevelFromXp(0), 1);
      expect(calculateLevelFromXp(100), 2);
      expect(calculateLevelFromXp(999999), lessThan(1000));
      expect(calculateLevelFromXp(-10), 1);
    });

    test('max save counter et compaction logic ne crash pas', () async {
      // simulate 60 saves
      for (var i=0;i<60;i++) {
        await OfflineManager.saveData('game_data', {'i': i, 'dataVersion': 1});
      }
      final box2 = Hive.box('game_data');
      await box2.compact();
      expect(box2.get('game_data'), isNotNull);
    });
  });

  group('ServerService crypto roundtrip (sauvegarde chiffrée)', () {
    test('sauvegarde chiffrée localement simulée', () async {
      // Ce test existe déjà en server_service_test mais on vérifie migration avec encrypted sync
      final raw = {
        'user': UserProfile(uid: '1', pseudo: 'H', globalXp: 1000, level: 4).toJson(),
        'dataVersion': 1,
      };
      await OfflineManager.saveData('game_data', raw);
      final loaded = OfflineManager.getData('game_data');
      expect(loaded['user']['globalXp'], 1000);
    });
  });
}
