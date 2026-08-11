/// Version actuelle du format de données persisté (clé Hive `game_data`).
const int currentDataVersion = 1;

/// Convertit une base de données JSON d'un ancien format vers le format courant,
/// **sans perte de données**. Fonction pure et idempotente : sans effet si la
/// base est déjà au format courant.
Map<String, dynamic> migrateData(Map<String, dynamic> data) {
  final version = data['dataVersion'];
  if (version is int && version >= currentDataVersion) {
    return data;
  }

  final result = Map<String, dynamic>.from(data);

  // --- Quêtes : enums stockés en int (ancien format) → name ---
  final quests = result['quests'];
  if (quests is List) {
    final migrated = <dynamic>[];
    for (final q in quests) {
      if (q is Map<String, dynamic>) {
        final quest = Map<String, dynamic>.from(q);
        final diff = quest['difficulty'];
        if (diff is int) {
          const diffMap = {0: 'easy', 1: 'easy', 2: 'medium', 3: 'hard', 4: 'legendary'};
          quest['difficulty'] = diffMap[diff] ?? 'easy';
        }
        final status = quest['status'];
        if (status is int) {
          const statusMap = {0: 'todo', 1: 'completed', 2: 'failed'};
          quest['status'] = statusMap[status] ?? 'todo';
        }
        final frequency = quest['frequency'];
        if (frequency is int) {
          const freqMap = {0: 'once', 1: 'daily', 2: 'weekly', 3: 'monthly'};
          quest['frequency'] = freqMap[frequency] ?? 'once';
        }
        quest.remove('streak');
        quest.remove('lastStreakIncrementDate');
        migrated.add(quest);
      } else {
        migrated.add(q);
      }
    }
    result['quests'] = migrated;
  }

  // --- Paris : status int → name (défensif) ---
  final bets = result['bets'];
  if (bets is List) {
    final migrated = <dynamic>[];
    for (final b in bets) {
      if (b is Map<String, dynamic>) {
        final bet = Map<String, dynamic>.from(b);
        final status = bet['status'];
        if (status is int) {
          const statusMap = {0: 'active', 1: 'won', 2: 'lost'};
          bet['status'] = statusMap[status] ?? 'active';
        }
        migrated.add(bet);
      } else {
        migrated.add(b);
      }
    }
    result['bets'] = migrated;
  }

  // --- Compétences : suppression de `parentId` (catégorie imbriquée) ---
  final skills = result['skills'];
  if (skills is List) {
    final migrated = <dynamic>[];
    for (final s in skills) {
      if (s is Map<String, dynamic>) {
        final skill = Map<String, dynamic>.from(s);
        final cat = skill['category'];
        if (cat is Map<String, dynamic>) {
          skill['category'] = _withoutParentId(cat);
        }
        migrated.add(skill);
      } else {
        migrated.add(s);
      }
    }
    result['skills'] = migrated;
  }

  // --- Catégories : suppression de `parentId` ---
  final categories = result['categories'];
  if (categories is List) {
    result['categories'] = categories.map((c) {
      if (c is Map<String, dynamic>) return _withoutParentId(c);
      return c;
    }).toList();
  }

  // --- Bilan du soir : rétro-compatibilité id (dérivé de la date, 1/jour) ---
  final eveningLog = result['eveningLog'];
  if (eveningLog is List) {
    final migrated = <dynamic>[];
    for (final e in eveningLog) {
      if (e is Map<String, dynamic>) {
        final entry = Map<String, dynamic>.from(e);
        entry['id'] ??= entry['date'];
        migrated.add(entry);
      } else {
        migrated.add(e);
      }
    }
    result['eveningLog'] = migrated;
  }

  result['dataVersion'] = currentDataVersion;
  return result;
}

Map<String, dynamic> _withoutParentId(Map<String, dynamic> map) {
  final m = Map<String, dynamic>.from(map);
  m.remove('parentId');
  return m;
}
