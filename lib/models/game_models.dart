// --- Modèles avec méthodes fromJson/toJson ---
// Ces classes DOIVENT avoir les méthodes fromJson et toJson implémentées
// pour que Hive puisse les lire et les écrire correctement.

import 'dart:ui' show Color;

/// Parse une valeur d'enum de façon sûre : renvoie [fallback] si la chaîne ne
/// correspond à aucune valeur connue (évite les crash `byName` sur données
/// inattendues du serveur).
T enumFromString<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

enum Difficulty {
  easy,
  medium,
  hard,
  legendary;

  int get xpBase => switch (this) {
    Difficulty.easy => 50,
    Difficulty.medium => 150,
    Difficulty.hard => 400,
    Difficulty.legendary => 1000,
  };
}

enum GuildRole {
  member,
  sub_chief,
  chief;
  
  int get rank => switch (this) {
    GuildRole.member => 0,
    GuildRole.sub_chief => 1,
    GuildRole.chief => 2,
  };
  
  String get label => switch (this) {
    GuildRole.member => 'Membre',
    GuildRole.sub_chief => 'Sous-chef',
    GuildRole.chief => 'Chef',
  };
}

enum GuildJoinType {
  open,
  criteria,
  private;
  
  String get label => switch (this) {
    GuildJoinType.open => 'Ouverte',
    GuildJoinType.criteria => 'Sur critère',
    GuildJoinType.private => 'Privée',
  };
}

enum GuildQuestStatus {
  active,
  completed,
  cancelled;
}

enum GuildLogActionType {
  join,
  leave,
  kick,
  promote,
  demote,
  transfer,
  update,
  invite_accepted,
  quest_completed,
  quest_created;
}

class SkillCategory {
  final String id;
  final String label;
  final String iconName;

  SkillCategory({required this.id, required this.label, this.iconName = 'star'});

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'iconName': iconName};
  factory SkillCategory.fromJson(Map<String, dynamic> json) => 
      SkillCategory(id: json['id'], label: json['label'], iconName: json['iconName'] ?? 'star');
      
  @override
  bool operator ==(Object other) => other is SkillCategory && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

class GameBadge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? expiresAt;

  GameBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'isUnlocked': isUnlocked,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory GameBadge.fromJson(Map<String, dynamic> json) => GameBadge(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    icon: json['icon'],
    isUnlocked: json['isUnlocked'] ?? false,
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
  );
}

class UserProfile {
  final String uid;
  final String pseudo;
  final String? avatarUrl;
  final String? title;
  final int globalXp;
  final int level;
  final int streak;
  final DateTime? lastCheckIn;
  final List<String> badgeIds;
  final int coins;
  final double soundVolume;
  final int hapticLevel;
  final int streakFreezeDaysLeft;
  final int dailyRewardDay;
  final DateTime? lastDailyRewardDate;
  final Map<String, String> characterParts;
  final List<String> unlockedCharacterParts;
  final double xpMultiplier;
  final List<int> claimedStreakMilestones;
  final String referralCode;
  final String? referredBy;
  final bool referralSubmitted;

  UserProfile({
    required this.uid,
    required this.pseudo,
    this.avatarUrl,
    this.title,
    this.globalXp = 0,
    this.level = 1,
    this.streak = 0,
    this.lastCheckIn,
    this.badgeIds = const [],
    this.coins = 0,
    this.soundVolume = 0.7,
    this.hapticLevel = 2,
    this.streakFreezeDaysLeft = 0,
    this.dailyRewardDay = 0,
    this.lastDailyRewardDate,
    this.characterParts = const {
      'skin': 'skin_1',
      'hair': 'hair_1',
      'eyes': 'eyes_1',
      'brow': 'brow_1',
      'mouth': 'mouth_1',
      'outfit': 'outfit_1',
      'hat': 'hat_0',
      'acc': 'acc_0',
    },
    this.unlockedCharacterParts = const [
      'skin_1', 'skin_2', 'skin_3',
      'hair_1',
      'eyes_1',
      'brow_1',
      'mouth_1',
      'outfit_1',
      'hat_0', 'acc_0',
    ],
    this.xpMultiplier = 1.0,
    this.claimedStreakMilestones = const [],
    this.referralCode = '',
    this.referredBy,
    this.referralSubmitted = false,
  });

  String get currentTitle {
    if (level >= 50) return 'Légende Immortelle';
    if (level >= 40) return 'Maître de l\'Existence';
    if (level >= 30) return 'Seigneur de Discipline';
    if (level >= 25) return 'Paladin de l\'Ordre';
    if (level >= 20) return 'Grand Aventurier';
    if (level >= 15) return 'Guerrier d\'Élite';
    if (level >= 10) return 'Éclaireur';
    if (level >= 5) return 'Apprenti';
    return 'Novice';
  }

  static const List<int> streakMilestones = [7, 14, 30, 60, 90, 180, 365];
  static const Map<int, int> milestoneCoins = {
    7: 30, 14: 50, 30: 100, 60: 150, 90: 200, 180: 500, 365: 1000,
  };

  bool hasClaimedMilestone(int day) => claimedStreakMilestones.contains(day);

  String partId(String category) => characterParts[category] ?? '${category}_1';
  bool hasPart(String id) => unlockedCharacterParts.contains(id);
  bool canUnlockPart(String id) {
    final def = UserProfile.allParts.where((p) => p.id == id).firstOrNull;
    return def != null && level >= def.unlockLevel && def.cost == 0;
  }

  static const List<CharacterPartDefinition> allParts = [
    // Skin tones (5)
    CharacterPartDefinition('skin_1', 'skin', 'Clair',    1, 0, Color(0xFFFFE0BD), Color(0xFFD4A574)),
    CharacterPartDefinition('skin_2', 'skin', 'Doré',     1, 0, Color(0xFFF1C27D), Color(0xFFD9A05B)),
    CharacterPartDefinition('skin_3', 'skin', 'Moyen',    1, 0, Color(0xFFD99B6C), Color(0xFFB87D4A)),
    CharacterPartDefinition('skin_4', 'skin', 'Foncé',    5, 0, Color(0xFF8D5524), Color(0xFF6B3F1A)),
    CharacterPartDefinition('skin_5', 'skin', 'Ébène',   10, 0, Color(0xFF5D3A1A), Color(0xFF3D2510)),
    // Hair (8)
    CharacterPartDefinition('hair_0', 'hair', 'Chauve',   1, 0, Color(0xFF2C1810), Color(0xFF4A2C20)),
    CharacterPartDefinition('hair_1', 'hair', 'Court',    1, 0, Color(0xFF2C1810), Color(0xFF4A2C20)),
    CharacterPartDefinition('hair_2', 'hair', 'Long',     4, 0, Color(0xFF1A1A2E), Color(0xFF8B4513)),
    CharacterPartDefinition('hair_3', 'hair', 'Bouclé',   8, 0, Color(0xFFFF6B35), Color(0xFFDAA520)),
    CharacterPartDefinition('hair_4', 'hair', 'Queue',   12, 0, Color(0xFF2C1810), Color(0xFFFF69B4)),
    CharacterPartDefinition('hair_5', 'hair', 'Blond',   14, 0, Color(0xFFF4D03F), Color(0xFFD4AC0D)),
    CharacterPartDefinition('hair_6', 'hair', 'Indigo',  16, 40, Color(0xFF34495E), Color(0xFF7FB3D5)),
    CharacterPartDefinition('hair_7', 'hair', 'Roux',    18, 60, Color(0xFF7E5109), Color(0xFFC0392B)),
    // Eyes (5)
    CharacterPartDefinition('eyes_1', 'eyes', 'Ronds',  1, 0, Color(0xFF1A1A2E), Color(0xFF4A90D9)),
    CharacterPartDefinition('eyes_2', 'eyes', 'Amandes', 3, 0, Color(0xFF1A1A2E), Color(0xFF50C878)),
    CharacterPartDefinition('eyes_3', 'eyes', 'Grands',  6, 0, Color(0xFF1A1A2E), Color(0xFF9B59B6)),
    CharacterPartDefinition('eyes_4', 'eyes', 'Froncés', 9, 0, Color(0xFF1A1A2E), Color(0xFFE74C3C)),
    CharacterPartDefinition('eyes_5', 'eyes', 'Ambre',  12, 0, Color(0xFF1A1A2E), Color(0xFFF1C40F)),
    // Eyebrows (3)
    CharacterPartDefinition('brow_1', 'brow', 'Neutre', 1, 0, Color(0xFF2C1810), Color(0xFF2C1810)),
    CharacterPartDefinition('brow_2', 'brow', 'Arqués', 5, 0, Color(0xFF2C1810), Color(0xFF2C1810)),
    CharacterPartDefinition('brow_3', 'brow', 'Froncés', 8, 0, Color(0xFF2C1810), Color(0xFF2C1810)),
    // Mouth (5)
    CharacterPartDefinition('mouth_1', 'mouth', 'Sourire',   1, 0, Color(0xFFE74C3C), Color(0xFFC0392B)),
    CharacterPartDefinition('mouth_2', 'mouth', 'Grand',     4, 0, Color(0xFFE74C3C), Color(0xFFC0392B)),
    CharacterPartDefinition('mouth_3', 'mouth', 'Neutre',    7, 0, Color(0xFFE74C3C), Color(0xFFC0392B)),
    CharacterPartDefinition('mouth_4', 'mouth', 'Bouche ouverte', 10, 0, Color(0xFFE74C3C), Color(0xFF2C3E50)),
    CharacterPartDefinition('mouth_5', 'mouth', 'Sourire fin', 12, 0, Color(0xFFE74C3C), Color(0xFFC0392B)),
    // Outfit (7 – RPG classes)
    CharacterPartDefinition('outfit_1', 'outfit', 'Guerrier',    1, 0, Color(0xFF7F8C8D), Color(0xFFF1C40F)),
    CharacterPartDefinition('outfit_2', 'outfit', 'Mage',        3, 0, Color(0xFF5B2C6F), Color(0xFFD4AC0D)),
    CharacterPartDefinition('outfit_3', 'outfit', 'Voleur',      7, 0, Color(0xFF1E8449), Color(0xFF17202A)),
    CharacterPartDefinition('outfit_4', 'outfit', 'Paladin',    11, 0, Color(0xFFD5D8DC), Color(0xFFF1C40F)),
    CharacterPartDefinition('outfit_5', 'outfit', 'Chevalier Noir', 15, 0, Color(0xFF17202A), Color(0xFF8B0000)),
    CharacterPartDefinition('outfit_6', 'outfit', 'Ranger',     17, 60, Color(0xFF196F3D), Color(0xFFD4AC0D)),
    CharacterPartDefinition('outfit_7', 'outfit', 'Écuyer',     19, 80, Color(0xFF2E4053), Color(0xFFE74C3C)),
    // Hat (4 + none)
    CharacterPartDefinition('hat_0', 'hat', 'Aucun',     1, 0, Color(0x00000000), Color(0x00000000)),
    CharacterPartDefinition('hat_1', 'hat', 'Casquette', 6, 50, Color(0xFFE74C3C), Color(0xFFC0392B)),
    CharacterPartDefinition('hat_2', 'hat', 'Chapeau',  10, 80, Color(0xFF2E4053), Color(0xFF5D6D7E)),
    CharacterPartDefinition('hat_3', 'hat', 'Couronne', 15, 200, Color(0xFFF1C40F), Color(0xFFD4AC0D)),
    CharacterPartDefinition('hat_4', 'hat', 'Salière',  18, 100, Color(0xFF7E5109), Color(0xFFF1C40F)),
    CharacterPartDefinition('hat_5', 'hat', 'Chapeau Magique', 20, 120, Color(0xFF5B2C6F), Color(0xFF8E44AD)),
    // Accessory (3 + none)
    CharacterPartDefinition('acc_0', 'acc', 'Aucun',    1, 0, Color(0x00000000), Color(0x00000000)),
    CharacterPartDefinition('acc_1', 'acc', 'Lunettes', 7, 60, Color(0xFF1A1A2E), Color(0xFF34495E)),
    CharacterPartDefinition('acc_2', 'acc', 'Masque',  10, 80, Color(0xFF7F8C8D), Color(0xFF95A5A6)),
    CharacterPartDefinition('acc_3', 'acc', 'Diadème', 13, 150, Color(0xFFF1C40F), Color(0xFFE67E22)),
    CharacterPartDefinition('acc_4', 'acc', 'Breloques', 16, 90, Color(0xFFF1C40F), Color(0xFF9B59B6)),
  ];

  UserProfile copyWith({
    String? pseudo,
    String? avatarUrl,
    String? title,
    int? globalXp,
    int? level,
    int? streak,
    DateTime? lastCheckIn,
    List<String>? badgeIds,
    int? coins,
    double? soundVolume,
    int? hapticLevel,
    int? streakFreezeDaysLeft,
    int? dailyRewardDay,
    DateTime? lastDailyRewardDate,
    Map<String, String>? characterParts,
    List<String>? unlockedCharacterParts,
    double? xpMultiplier,
    List<int>? claimedStreakMilestones,
    String? referralCode,
    String? referredBy,
    bool? referralSubmitted,
  }) {
    return UserProfile(
      uid: uid, 
      pseudo: pseudo ?? this.pseudo,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      title: title ?? this.title,
      globalXp: globalXp ?? this.globalXp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      badgeIds: badgeIds ?? this.badgeIds,
      coins: coins ?? this.coins,
      soundVolume: soundVolume ?? this.soundVolume,
      hapticLevel: hapticLevel ?? this.hapticLevel,
      streakFreezeDaysLeft: streakFreezeDaysLeft ?? this.streakFreezeDaysLeft,
      dailyRewardDay: dailyRewardDay ?? this.dailyRewardDay,
      lastDailyRewardDate: lastDailyRewardDate ?? this.lastDailyRewardDate,
      characterParts: characterParts ?? this.characterParts,
      unlockedCharacterParts: unlockedCharacterParts ?? this.unlockedCharacterParts,
      xpMultiplier: xpMultiplier ?? this.xpMultiplier,
      claimedStreakMilestones: claimedStreakMilestones ?? this.claimedStreakMilestones,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      referralSubmitted: referralSubmitted ?? this.referralSubmitted,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'pseudo': pseudo,
    'avatarUrl': avatarUrl,
    'title': title,
    'globalXp': globalXp,
    'level': level,
    'streak': streak,
    'lastCheckIn': lastCheckIn?.toIso8601String(),
    'badgeIds': badgeIds,
    'coins': coins,
    'soundVolume': soundVolume,
    'hapticLevel': hapticLevel,
    'streakFreezeDaysLeft': streakFreezeDaysLeft,
    'dailyRewardDay': dailyRewardDay,
    'lastDailyRewardDate': lastDailyRewardDate?.toIso8601String(),
    'characterParts': characterParts,
    'unlockedCharacterParts': unlockedCharacterParts,
    'xpMultiplier': xpMultiplier,
    'claimedStreakMilestones': claimedStreakMilestones,
    'referralCode': referralCode,
    'referredBy': referredBy,
    'referralSubmitted': referralSubmitted,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'],
    pseudo: json['pseudo'],
    avatarUrl: json['avatarUrl'],
    title: json['title'],
    globalXp: json['globalXp'] ?? 0,
    level: json['level'] ?? 1,
    streak: json['streak'] ?? 0,
    lastCheckIn: json['lastCheckIn'] != null ? DateTime.parse(json['lastCheckIn']) : null,
    badgeIds: List<String>.from(json['badgeIds'] ?? json['badges'] ?? []),
    coins: json['coins'] ?? 0,
    soundVolume: (json['soundVolume'] ?? (json['soundEnabled'] == false ? 0.0 : 0.7)).toDouble(),
    hapticLevel: json['hapticLevel'] ?? (json['soundEnabled'] == false ? 0 : 2),
    streakFreezeDaysLeft: json['streakFreezeDaysLeft'] ?? (json['streakFreezeActive'] == true ? 1 : 0),
    dailyRewardDay: json['dailyRewardDay'] ?? 0,
    lastDailyRewardDate: json['lastDailyRewardDate'] != null ? DateTime.parse(json['lastDailyRewardDate']) : null,
    characterParts: Map<String, String>.from(json['characterParts'] ?? const {
      'skin': 'skin_1', 'hair': 'hair_1', 'eyes': 'eyes_1',
      'brow': 'brow_1', 'mouth': 'mouth_1', 'outfit': 'outfit_1',
      'hat': 'hat_0', 'acc': 'acc_0',
    }),
    unlockedCharacterParts: List<String>.from(json['unlockedCharacterParts'] ?? const [
      'skin_1', 'skin_2', 'skin_3',
      'hair_1', 'eyes_1', 'brow_1', 'mouth_1', 'outfit_1', 'hat_0', 'acc_0',
    ]),
    xpMultiplier: (json['xpMultiplier'] ?? 1.0).toDouble(),
    claimedStreakMilestones: List<int>.from(json['claimedStreakMilestones'] ?? []),
    referralCode: json['referralCode'] ?? '',
    referredBy: json['referredBy'],
    referralSubmitted: json['referralSubmitted'] ?? false,
  );
}

class Skill {
  final SkillCategory category;
  final int xp;
  final int level;
  final List<int> xpHistory; // XP per day for the last 7 days

  Skill({
    required this.category,
    this.xp = 0,
    this.level = 1,
    this.xpHistory = const [0, 0, 0, 0, 0, 0, 0],
  });

  Skill copyWith({int? xp, int? level, List<int>? xpHistory}) {
    return Skill(
      category: category, 
      xp: xp ?? this.xp,
      level: level ?? this.level,
      xpHistory: xpHistory ?? this.xpHistory,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'category': category.toJson(),
    'xp': xp,
    'level': level,
    'xpHistory': xpHistory,
  };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    category: SkillCategory.fromJson(json['category']),
    xp: json['xp'] ?? 0,
    level: json['level'] ?? 1,
    xpHistory: List<int>.from(json['xpHistory'] ?? List.filled(7, 0)),
  );
}

enum QuestStatus { todo, completed, failed }
enum QuestFrequency { once, daily, weekly, monthly }

enum BetStatus { active, won, lost }

class Bet {
  final String id;
  final String title;
  final List<String> linkedQuestIds;
  final DateTime deadline;
  final DateTime createdAt;
  final int rewardXp;
  final int penaltyXp;
  final BetStatus status;

  Bet({
    required this.id,
    required this.title,
    required this.linkedQuestIds,
    required this.deadline,
    DateTime? createdAt,
    this.rewardXp = 100,
    this.penaltyXp = 50,
    this.status = BetStatus.active,
  }) : createdAt = createdAt ?? DateTime.now();

  Bet copyWith({
    String? title,
    List<String>? linkedQuestIds,
    DateTime? deadline,
    int? rewardXp,
    int? penaltyXp,
    BetStatus? status,
  }) {
    return Bet(
      id: id,
      title: title ?? this.title,
      linkedQuestIds: linkedQuestIds ?? this.linkedQuestIds,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
      rewardXp: rewardXp ?? this.rewardXp,
      penaltyXp: penaltyXp ?? this.penaltyXp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'linkedQuestIds': linkedQuestIds,
    'deadline': deadline.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'rewardXp': rewardXp,
    'penaltyXp': penaltyXp,
    'status': status.name,
  };

  factory Bet.fromJson(Map<String, dynamic> json) => Bet(
    id: json['id'],
    title: json['title'],
    linkedQuestIds: List<String>.from(json['linkedQuestIds'] ?? []),
    deadline: DateTime.parse(json['deadline']),
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    rewardXp: json['rewardXp'] ?? 100,
    penaltyXp: json['penaltyXp'] ?? 50,
    status: enumFromString(BetStatus.values, json['status'], BetStatus.active),
  );
}

class Quest {
  final String id;
  final String title;
  final String description;
  final Difficulty difficulty;
  final SkillCategory category;
  final QuestStatus status;
  final QuestFrequency frequency;
  final DateTime? lastCompletedDate;
  final DateTime? reminderDate;
  final DateTime? startTime;
  final DateTime? dueDate;
  final DateTime createdAt;
  final int xpReward; 

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    this.status = QuestStatus.todo,
    this.frequency = QuestFrequency.once,
    this.lastCompletedDate,
    this.reminderDate,
    this.startTime,
    this.dueDate,
    DateTime? createdAt,
    this.xpReward = 0, 
  }) : createdAt = createdAt ?? DateTime.now();

  int get xpRewardValue => difficulty.xpBase + xpReward; 

  Quest copyWith({
    String? title,
    String? description,
    Difficulty? difficulty,
    SkillCategory? category,
    QuestStatus? status,
    QuestFrequency? frequency,
    DateTime? lastCompletedDate,
    DateTime? reminderDate,
    DateTime? startTime,
    DateTime? dueDate,
    DateTime? createdAt,
    int? xpReward, 
  }) {
    return Quest(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      status: status ?? this.status,
      frequency: frequency ?? this.frequency,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      reminderDate: reminderDate ?? this.reminderDate,
      startTime: startTime ?? this.startTime,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      xpReward: xpReward ?? this.xpReward, 
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'difficulty': difficulty.name,
    'category': category.toJson(),
    'status': status.name,
    'frequency': frequency.name,
    'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    'reminderDate': reminderDate?.toIso8601String(),
    'startTime': startTime?.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'xpReward': xpReward, 
  };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    difficulty: enumFromString(Difficulty.values, json['difficulty'], Difficulty.easy),
    category: SkillCategory.fromJson(json['category']),
    status: enumFromString(QuestStatus.values, json['status'], QuestStatus.todo),
    frequency: enumFromString(QuestFrequency.values, json['frequency'], QuestFrequency.once),
    lastCompletedDate: json['lastCompletedDate'] != null ? DateTime.parse(json['lastCompletedDate']) : null,
    reminderDate: json['reminderDate'] != null ? DateTime.parse(json['reminderDate']) : null,
    startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    xpReward: json['xpReward'] ?? 0, 
  );
}

class Reward {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'isUnlocked': isUnlocked,
  };

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    icon: json['icon'],
    isUnlocked: json['isUnlocked'] ?? false,
  );
}

class Guild {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final GuildJoinType joinType;
  final int minLevel;
  final int maxMembers;
  final String? encryptionKey;
  final List<GuildMember> members;
  final int totalXp;
  final int level;
  final int memberCount;
  final double avgLevel;
  final String? myRole;

  Guild({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.joinType = GuildJoinType.open,
    this.minLevel = 0,
    this.maxMembers = 50,
    this.encryptionKey,
    this.members = const [],
    this.totalXp = 0,
    this.level = 1,
    this.avgLevel = 0.0,
    int? memberCount,
    this.myRole,
  }) : memberCount = memberCount ?? members.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'logoUrl': logoUrl,
    'joinType': joinType.name,
    'minLevel': minLevel,
    'maxMembers': maxMembers,
    'encryptionKey': encryptionKey,
    'members': members.map((m) => m.toJson()).toList(),
    'totalXp': totalXp,
    'level': level,
    'avgLevel': avgLevel,
    'memberCount': memberCount,
    'my_role': myRole,
  };

  factory Guild.fromJson(Map<String, dynamic> json) => Guild(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    logoUrl: json['logoUrl'] ?? json['logo_url'],
    joinType: enumFromString(GuildJoinType.values, json['joinType'] ?? json['join_type'], GuildJoinType.open),
    minLevel: json['minLevel'] ?? json['min_level'] ?? 0,
    maxMembers: json['maxMembers'] ?? json['max_members'] ?? 50,
    encryptionKey: json['encryptionKey'] ?? json['encryption_key'],
    members: (json['members'] as List<dynamic>?)
        ?.map((m) => GuildMember.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
    totalXp: json['totalXp'] ?? json['total_xp'] ?? 0,
    level: json['level'] ?? 1,
    avgLevel: (json['avg_level'] ?? json['avgLevel'] ?? 0.0).toDouble(),
    memberCount: json['member_count'] ?? json['memberCount'],
    myRole: json['my_role'],
  );

  Guild copyWith({
    String? name,
    String? description,
    String? logoUrl,
    GuildJoinType? joinType,
    int? minLevel,
    int? maxMembers,
    String? encryptionKey,
    List<GuildMember>? members,
    int? totalXp,
    int? level,
  }) {
    return Guild(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      joinType: joinType ?? this.joinType,
      minLevel: minLevel ?? this.minLevel,
      maxMembers: maxMembers ?? this.maxMembers,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      members: members ?? this.members,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
    );
  }

GuildMember? getMember(String uid) {
    try {
      return members.firstWhere((m) => m.uid == uid);
    } catch (_) {
      return null;
    }
  }

  bool get hasChief => members.any((m) => m.role == GuildRole.chief);
}

class GuildMember {
  final String uid;
  final String pseudo;
  final int level;
  final int xp;
  final GuildRole role;
  final DateTime joinedAt;
  final String? avatarUrl;

  GuildMember({
    required this.uid,
    required this.pseudo,
    required this.level,
    required this.xp,
    required this.role,
    required this.joinedAt,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'pseudo': pseudo,
    'level': level,
    'xp': xp,
    'role': role.name,
    'joinedAt': joinedAt.toIso8601String(),
    'avatarUrl': avatarUrl,
  };

  factory GuildMember.fromJson(Map<String, dynamic> json) => GuildMember(
    uid: (json['id'] ?? json['uid'])?.toString() ?? '',
    pseudo: json['username'] ?? json['pseudo'],
    level: json['level'] ?? 1,
    xp: json['xp'] ?? 0,
    role: GuildRole.values
        .where((r) => r.name == (json['role'] ?? 'member'))
        .firstOrNull ?? GuildRole.member,
    joinedAt: json['joinedAt'] != null
        ? DateTime.parse(json['joinedAt'])
        : DateTime.now(),
    avatarUrl: json['avatarUrl'],
  );
}

class GuildInvitation {
  final String id;
  final String guildId;
  final String guildName;
  final String inviterUid;
  final String inviterPseudo;
  final String inviteeUid;
  final String inviteePseudo;
  final String status; // pending, accepted, declined, cancelled
  final DateTime createdAt;

  GuildInvitation({
    required this.id,
    required this.guildId,
    required this.guildName,
    required this.inviterUid,
    required this.inviterPseudo,
    required this.inviteeUid,
    required this.inviteePseudo,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'guildId': guildId,
    'guildName': guildName,
    'inviterUid': inviterUid,
    'inviterPseudo': inviterPseudo,
    'inviteeUid': inviteeUid,
    'inviteePseudo': inviteePseudo,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GuildInvitation.fromJson(Map<String, dynamic> json) => GuildInvitation(
    id: json['id'].toString(),
    guildId: (json['guildId'] ?? json['guild_id'] ?? '').toString(),
    guildName: json['guildName'] ?? json['guild_name'] ?? '',
    inviterUid: (json['inviterUid'] ?? json['inviter_id'] ?? '').toString(),
    inviterPseudo: json['inviterPseudo'] ?? json['inviter_name'] ?? '',
    inviteeUid: (json['inviteeUid'] ?? json['invitee_id'] ?? '').toString(),
    inviteePseudo: json['inviteePseudo'] ?? json['invitee_name'] ?? '',
    status: json['status'] ?? 'pending',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
  );
}

class GuildQuest {
  final String id;
  final String guildId;
  final String title;
  final String description;
  final int xpReward;
  final int coinReward;
  final String creatorUid;
  final String creatorPseudo;
  final GuildQuestStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  GuildQuest({
    required this.id,
    required this.guildId,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.coinReward,
    required this.creatorUid,
    required this.creatorPseudo,
    this.status = GuildQuestStatus.active,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'guildId': guildId,
    'title': title,
    'description': description,
    'xpReward': xpReward,
    'coinReward': coinReward,
    'creatorUid': creatorUid,
    'creatorPseudo': creatorPseudo,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory GuildQuest.fromJson(Map<String, dynamic> json) => GuildQuest(
    id: json['id'].toString(),
    guildId: (json['guildId'] ?? json['guild_id'] ?? '').toString(),
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    xpReward: json['xpReward'] ?? json['xp_reward'] ?? 0,
    coinReward: json['coinReward'] ?? json['coin_reward'] ?? 0,
    creatorUid: (json['creatorUid'] ?? json['creator_id'] ?? '').toString(),
    creatorPseudo: json['creatorPseudo'] ?? json['creator_name'] ?? '',
    status: enumFromString(GuildQuestStatus.values, json['status'], GuildQuestStatus.active),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
  );
}

class GuildLog {
  final String id;
  final String guildId;
  final String actorUid;
  final String actorPseudo;
  final GuildLogActionType actionType;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  GuildLog({
    required this.id,
    required this.guildId,
    required this.actorUid,
    required this.actorPseudo,
    required this.actionType,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'guildId': guildId,
    'actorUid': actorUid,
    'actorPseudo': actorPseudo,
    'actionType': actionType.name,
    'details': details,
    'timestamp': timestamp.toIso8601String(),
  };

  factory GuildLog.fromJson(Map<String, dynamic> json) => GuildLog(
    id: json['id'].toString(),
    guildId: (json['guildId'] ?? json['guild_id'] ?? '').toString(),
    actorUid: (json['actorUid'] ?? json['actor_id'] ?? '').toString(),
    actorPseudo: json['actorPseudo'] ?? json['actor_name'] ?? '',
    actionType: enumFromString(GuildLogActionType.values, json['actionType'] ?? json['action_type'], GuildLogActionType.join),
    details: Map<String, dynamic>.from(json['details'] ?? {}),
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
  );
}

class ChatMessage {
  final String id;
  final String senderName;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String? room;
  final bool isEncrypted;
  final bool deleted;
  final DateTime? deletedAt;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.room,
    this.isEncrypted = false,
    this.deleted = false,
    this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderName': senderName,
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'room': room,
    'isEncrypted': isEncrypted,
    'deleted': deleted,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString() ?? '',
    senderName: json['senderName'],
    senderId: json['senderId'] ?? '',
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
    room: json['room'],
    isEncrypted: json['isEncrypted'] ?? false,
    deleted: json['deleted'] ?? false,
    deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
  );
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int cost;
  final String type; // 'character_part', 'title', 'boost', 'streak_freeze'
  final String? value;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.cost,
    required this.type,
    this.value,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'cost': cost,
    'type': type,
    'value': value,
  };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    icon: json['icon'],
    cost: json['cost'],
    type: json['type'],
    value: json['value'],
  );
}

class LootBox {
  final String id;
  final String name;
  final String icon;
  final int questsRequired;
  final List<String> possibleBadgeIds;

  LootBox({
    required this.id,
    required this.name,
    required this.icon,
    this.questsRequired = 5,
    this.possibleBadgeIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'questsRequired': questsRequired,
    'possibleBadgeIds': possibleBadgeIds,
  };

  factory LootBox.fromJson(Map<String, dynamic> json) => LootBox(
    id: json['id'],
    name: json['name'],
    icon: json['icon'],
    questsRequired: json['questsRequired'] ?? 5,
    possibleBadgeIds: List<String>.from(json['possibleBadgeIds'] ?? []),
  );
}

class LeaderboardEntry {
  final String pseudo;
  final int level;
  final int totalXp;
  final int streak;

  LeaderboardEntry({
    required this.pseudo,
    required this.level,
    required this.totalXp,
    required this.streak,
  });

  Map<String, dynamic> toJson() => {
    'pseudo': pseudo,
    'level': level,
    'totalXp': totalXp,
    'streak': streak,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    pseudo: json['pseudo'],
    level: json['level'] ?? 1,
    totalXp: json['totalXp'] ?? 0,
    streak: json['streak'] ?? 0,
  );
}

class EveningEntry {
  final String id;
  final DateTime date;
  final String text;
  final String mood;
  final int coinReward;

  EveningEntry({
    String? id,
    required this.date,
    required this.text,
    required this.mood,
    this.coinReward = 0,
  }) : id = id ?? date.toIso8601String();

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'text': text,
    'mood': mood,
    'coinReward': coinReward,
  };

  factory EveningEntry.fromJson(Map<String, dynamic> json) => EveningEntry(
    id: json['id'],
    date: DateTime.parse(json['date']),
    text: json['text'],
    mood: json['mood'],
    coinReward: json['coinReward'] ?? 0,
  );

  EveningEntry copyWith({
    String? text,
    String? mood,
  }) {
    return EveningEntry(
      id: id,
      date: date,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      coinReward: coinReward,
    );
  }
}

class CharacterPartDefinition {
  final String id;
  final String category;
  final String label;
  final int unlockLevel;
  final int cost;
  final Color color1;
  final Color color2;

  const CharacterPartDefinition(
    this.id,
    this.category,
    this.label,
    this.unlockLevel,
    this.cost,
    this.color1,
    this.color2,
  );

  String get assetPath => 'assets/characters/$id.png';
}
