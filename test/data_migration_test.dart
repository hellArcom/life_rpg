import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:life_rpg_dev/core/data_migration.dart';
import 'package:life_rpg_dev/models/game_models.dart';
import 'package:life_rpg_dev/providers/game_provider.dart';

const _oldFormatData = '''
{
  "user": {
    "uid": "1",
    "pseudo": "Arcom",
    "avatarUrl": null,
    "title": "Novice",
    "globalXp": 1975,
    "level": 5,
    "streak": 0,
    "lastCheckIn": null,
    "badgeIds": ["xp_1000"],
    "coins": 120,
    "soundEnabled": false,
    "streakFreezeActive": false,
    "dailyRewardDay": 3
  },
  "skills": [
    {
      "category": {"id": "1", "label": "Physique", "iconName": "fitness_center", "parentId": null},
      "xp": 500,
      "level": 3,
      "xpHistory": [0, 0, 0, 0, 0, 0, 0]
    }
  ],
  "quests": [
    {
      "id": "q1",
      "title": "Courir",
      "description": "",
      "difficulty": 2,
      "category": {"id": "1", "label": "Physique", "iconName": "fitness_center", "parentId": null},
      "status": 0,
      "frequency": 0,
      "lastCompletedDate": null,
      "reminderDate": null,
      "startTime": null,
      "dueDate": null,
      "xpReward": 50,
      "streak": 0,
      "lastStreakIncrementDate": null
    },
    {
      "id": "q2",
      "title": "Lire",
      "description": "30min",
      "difficulty": 1,
      "category": {"id": "2", "label": "Mental", "iconName": "menu_book", "parentId": null},
      "status": 1,
      "frequency": 1,
      "lastCompletedDate": "2025-01-01T20:00:00.000",
      "reminderDate": null,
      "startTime": null,
      "dueDate": null,
      "xpReward": 150,
      "streak": 0,
      "lastStreakIncrementDate": null
    }
  ],
  "rewards": [],
  "categories": [
    {"id": "1", "label": "Physique", "iconName": "fitness_center", "parentId": null},
    {"id": "2", "label": "Mental", "iconName": "menu_book", "parentId": null}
  ],
  "bets": [],
  "availableBadges": [],
  "eveningLog": [
    {"date": "2025-01-05T21:00:00.000", "text": "Bonne journée", "mood": "😊", "coinReward": 10}
  ]
}
''';

void main() {
  test('migre une ancienne base (enums en int) sans perte de données', () {
    final old = jsonDecode(_oldFormatData) as Map<String, dynamic>;
    final migrated = migrateData(old);

    expect(migrated['dataVersion'], currentDataVersion);

    final state = GameState.fromJson(migrated);

    expect(state.user.globalXp, 1975);
    expect(state.user.coins, 120);
    expect(state.user.soundVolume, 0.0);
    expect(state.user.hapticLevel, 0);

    expect(state.quests.length, 2);
    expect(state.quests[0].difficulty, Difficulty.medium);
    expect(state.quests[0].status, QuestStatus.todo);
    expect(state.quests[0].frequency, QuestFrequency.once);
    expect(state.quests[1].status, QuestStatus.completed);
    expect(state.quests[1].frequency, QuestFrequency.daily);

    expect(state.eveningLog.length, 1);
    expect(state.eveningLog.first.id, '2025-01-05T21:00:00.000');
    expect(state.eveningLog.first.text, 'Bonne journée');
  });

  test('supprime les champs obsolètes et backfill les ids du soir', () {
    final old = jsonDecode(_oldFormatData) as Map<String, dynamic>;
    final migrated = migrateData(old);

    final questJson = (migrated['quests'] as List).first as Map<String, dynamic>;
    expect(questJson.containsKey('streak'), isFalse);
    expect(questJson.containsKey('lastStreakIncrementDate'), isFalse);

    final catJson = (migrated['categories'] as List).first as Map<String, dynamic>;
    expect(catJson.containsKey('parentId'), isFalse);

    final skillCat = ((migrated['skills'] as List).first as Map<String, dynamic>)['category'] as Map<String, dynamic>;
    expect(skillCat.containsKey('parentId'), isFalse);

    final eveningJson = (migrated['eveningLog'] as List).first as Map<String, dynamic>;
    expect(eveningJson['id'], eveningJson['date']);
  });

  test('idempotente : une base déjà au format courant est inchangée', () {
    final old = jsonDecode(_oldFormatData) as Map<String, dynamic>;
    final once = migrateData(old);
    final twice = migrateData(once);

    expect(jsonEncode(twice), jsonEncode(once));
    expect(jsonEncode(twice), jsonEncode(migrateData(twice)));
  });

  test('la vraie base de secours (ancien format) se charge sans perte', () {
    final file = File('life_rpg_backup.json');
    if (!file.existsSync()) {
      markTestSkipped('life_rpg_backup.json absent');
      return;
    }
    final old = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final questCount = (old['quests'] as List).length;
    final xp = ((old['user'] as Map<String, dynamic>)['globalXp'] ?? 0) as int;

    final migrated = migrateData(old);
    expect(migrated['dataVersion'], currentDataVersion);

    final state = GameState.fromJson(migrated);
    expect(state.quests.length, questCount);
    expect(state.user.globalXp, xp);
  });
}
