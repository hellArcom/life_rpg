import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart'; 
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../core/offline_manager.dart';

class GameState {
  final UserProfile user;
  final List<Skill> skills;
  final List<Quest> quests;
  final List<Reward> rewards;
  final List<SkillCategory> categories;
  final List<Bet> bets;
  final List<GameBadge> availableBadges;
  final Guild? currentGuild;
  final List<Guild> availableGuilds;
  final List<ChatMessage> guildMessages;
  final List<LeaderboardEntry> leaderboard;
  final List<ShopItem> shopItems;
  final List<LootBox> lootBoxes;
  final int lootBoxProgress;
  final List<int> weeklyXpLog;
  final DateTime? lastPenaltyDate;
  final bool celebrationPending;
  final List<EveningEntry> eveningLog;

  GameState({
    required this.user,
    required this.skills,
    required this.quests,
    required this.rewards,
    required this.categories,
    this.bets = const [],
    this.availableBadges = const [],
    this.currentGuild,
    this.availableGuilds = const [],
    this.guildMessages = const [],
    this.leaderboard = const [],
    this.shopItems = const [],
    this.lootBoxes = const [],
    this.lootBoxProgress = 0,
    this.weeklyXpLog = const [],
    this.lastPenaltyDate,
    this.celebrationPending = false,
    this.eveningLog = const [],
  });

  GameState copyWith({
    UserProfile? user,
    List<Skill>? skills,
    List<Quest>? quests,
    List<Reward>? rewards,
    List<SkillCategory>? categories,
    List<Bet>? bets,
    List<GameBadge>? availableBadges,
    Guild? currentGuild,
    List<Guild>? availableGuilds,
    List<ChatMessage>? guildMessages,
    List<LeaderboardEntry>? leaderboard,
    List<ShopItem>? shopItems,
    List<LootBox>? lootBoxes,
    int? lootBoxProgress,
    List<int>? weeklyXpLog,
    DateTime? lastPenaltyDate,
    bool? celebrationPending,
    List<EveningEntry>? eveningLog,
  }) {
    return GameState(
      user: user ?? this.user,
      skills: skills ?? this.skills,
      quests: quests ?? this.quests,
      rewards: rewards ?? this.rewards,
      categories: categories ?? this.categories,
      bets: bets ?? this.bets,
      availableBadges: availableBadges ?? this.availableBadges,
      currentGuild: currentGuild ?? this.currentGuild,
      availableGuilds: availableGuilds ?? this.availableGuilds,
      guildMessages: guildMessages ?? this.guildMessages,
      leaderboard: leaderboard ?? this.leaderboard,
      shopItems: shopItems ?? this.shopItems,
      lootBoxes: lootBoxes ?? this.lootBoxes,
      lootBoxProgress: lootBoxProgress ?? this.lootBoxProgress,
      weeklyXpLog: weeklyXpLog ?? this.weeklyXpLog,
      lastPenaltyDate: lastPenaltyDate ?? this.lastPenaltyDate,
      celebrationPending: celebrationPending ?? this.celebrationPending,
      eveningLog: eveningLog ?? this.eveningLog,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'skills': skills.map((s) => s.toJson()).toList(),
    'quests': quests.map((q) => q.toJson()).toList(),
    'rewards': rewards.map((r) => r.toJson()).toList(),
    'categories': categories.map((c) => c.toJson()).toList(),
    'bets': bets.map((b) => b.toJson()).toList(),
    'availableBadges': availableBadges.map((b) => b.toJson()).toList(),
    'shopItems': shopItems.map((s) => s.toJson()).toList(),
    'lootBoxes': lootBoxes.map((l) => l.toJson()).toList(),
    'lootBoxProgress': lootBoxProgress,
    'weeklyXpLog': weeklyXpLog,
    'lastPenaltyDate': lastPenaltyDate?.toIso8601String(),
    'celebrationPending': celebrationPending,
    'eveningLog': eveningLog.map((e) => e.toJson()).toList(),
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    final skillsJson = json['skills'] as List<dynamic>?;
    final questsJson = json['quests'] as List<dynamic>?;
    final rewardsJson = json['rewards'] as List<dynamic>?;
    final categoriesJson = json['categories'] as List<dynamic>?;
    final betsJson = json['bets'] as List<dynamic>?;
    final badgesJson = json['availableBadges'] as List<dynamic>?;

    return GameState(
      user: userJson != null ? UserProfile.fromJson(userJson) : UserProfile(uid: '1', pseudo: 'Héros', title: 'Novice', globalXp: 0, level: 1, streak: 0),
      skills: skillsJson?.map((s) => Skill.fromJson(s as Map<String, dynamic>)).toList() ?? [],
      quests: questsJson?.map((q) => Quest.fromJson(q as Map<String, dynamic>)).toList() ?? [],
      rewards: rewardsJson?.map((r) => Reward.fromJson(r as Map<String, dynamic>)).toList() ?? [],
      categories: categoriesJson?.map((c) => SkillCategory.fromJson(c as Map<String, dynamic>)).toList() ?? [],
      bets: betsJson?.map((b) => Bet.fromJson(b as Map<String, dynamic>)).toList() ?? [],
      availableBadges: badgesJson?.map((b) => GameBadge.fromJson(b as Map<String, dynamic>)).toList() ?? [],
      shopItems: (json['shopItems'] as List<dynamic>?)?.map((s) => ShopItem.fromJson(s)).toList() ?? [],
      lootBoxes: (json['lootBoxes'] as List<dynamic>?)?.map((l) => LootBox.fromJson(l)).toList() ?? [],
      lootBoxProgress: json['lootBoxProgress'] ?? 0,
      weeklyXpLog: List<int>.from(json['weeklyXpLog'] ?? List.filled(7, 0)),
      lastPenaltyDate: json['lastPenaltyDate'] != null ? DateTime.parse(json['lastPenaltyDate']) : null,
      celebrationPending: json['celebrationPending'] ?? false,
      eveningLog: (json['eveningLog'] as List<dynamic>?)?.map((e) => EveningEntry.fromJson(e)).toList() ?? [],
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() {
    try {
      final savedData = OfflineManager.getData('game_data');
      if (savedData != null && savedData is Map<String, dynamic>) {
        return GameState.fromJson(savedData);
      }
    } catch (e, stacktrace) {
      debugPrint("Erreur critique lors du chargement des données: $e\n$stacktrace");
    }
    return _buildDefaultState();
  }

  List<SkillCategory> get defaultCategories => [
    SkillCategory(id: '1', label: 'Physique', iconName: 'fitness_center'),
    SkillCategory(id: '2', label: 'Mental', iconName: 'menu_book'),
    SkillCategory(id: '3', label: 'Discipline', iconName: 'timer'),
    SkillCategory(id: '4', label: 'Social', iconName: 'groups'),
    SkillCategory(id: '5', label: 'Créativité', iconName: 'palette'),
  ];

  GameState _buildDefaultState() {
    final defaultBadges = [
      GameBadge(id: 'xp_1000', title: 'Apprenti motivé', description: 'Atteindre 1000 XP globale', icon: '✨'),
      GameBadge(id: 'quest_10', title: 'Persévérant', description: 'Terminer 10 quêtes', icon: '📜'),
      GameBadge(id: 'streak_3', title: 'Régulier', description: 'Maintenir une série de 3 jours', icon: '🔥'),
      GameBadge(id: 'level_10', title: 'Vétéran', description: 'Atteindre le niveau 10', icon: '🎖️'),
      GameBadge(id: 'focus_5', title: 'Moine Novice', description: 'Rester concentré 5 min', icon: '🧘'),
      GameBadge(id: 'focus_10', title: 'Esprit Calme', description: 'Rester concentré 10 min', icon: '🧠'),
      GameBadge(id: 'focus_20', title: 'Maître Zen', description: 'Rester concentré 20 min', icon: '💎'),
      GameBadge(id: 'focus_60', title: 'Concentration Absolue', description: 'Rester concentré 1 heure', icon: '🌀'),
      GameBadge(id: 'loot_10', title: 'Chasseur de Coffres', description: 'Ouvrir 10 coffres', icon: '🎁', isUnlocked: true),
      GameBadge(id: 'coins_500', title: 'Économiseur', description: 'Accumuler 500 pièces', icon: '💰', isUnlocked: true),
    ];

    return GameState(
      user: UserProfile(uid: '1', pseudo: 'Héros', title: 'Novice', globalXp: 0, level: 1, streak: 0),
      skills: defaultCategories.map((cat) => Skill(category: cat, xp: 0, level: 1, xpHistory: List.filled(7, 0))).toList(),
      quests: [],
      rewards: [],
      categories: defaultCategories,
      bets: [],
      availableBadges: defaultBadges,
      shopItems: _defaultShopItems(),
      lootBoxes: _defaultLootBoxes(),
      weeklyXpLog: List.filled(7, 0),
    );
  }

  List<ShopItem> _defaultShopItems() => [
    ShopItem(id: 'hat_1', name: 'Casquette Rouge', description: 'Une casquette stylée', icon: '🧢', cost: 50, type: 'character_part', value: 'hat_1'),
    ShopItem(id: 'hat_3', name: 'Couronne Royale', description: 'Une couronne de roi', icon: '👑', cost: 200, type: 'character_part', value: 'hat_3'),
    ShopItem(id: 'acc_3', name: 'Diadème Étincelant', description: 'Un diadème précieux', icon: '💎', cost: 150, type: 'character_part', value: 'acc_3'),
    ShopItem(id: 'title_legend', name: 'Titre: Légende Vivante', description: 'Titre exclusif dans votre profil', icon: '🏆', cost: 300, type: 'title', value: 'Légende Vivante'),
    ShopItem(id: 'title_sage', name: 'Titre: Sage Ancien', description: 'Titre mystique pour votre profil', icon: '📜', cost: 200, type: 'title', value: 'Sage Ancien'),
    ShopItem(id: 'freeze_1', name: 'Gel de Série ×1', description: 'Protège votre série pour un jour', icon: '🧊', cost: 50, type: 'streak_freeze'),
    ShopItem(id: 'freeze_3', name: 'Gel de Série ×3', description: 'Protège votre série 3 jours', icon: '🧊🧊🧊', cost: 120, type: 'streak_freeze'),
    ShopItem(id: 'boost_x2', name: 'Boost XP ×2 (24h)', description: 'Doublez vos XP pendant 24h', icon: '⚡', cost: 80, type: 'boost'),
  ];

  List<LootBox> _defaultLootBoxes() => [
    LootBox(id: 'box_bronze', name: 'Coffre Bronze', icon: '📦', questsRequired: 3, possibleBadgeIds: ['loot_3', 'coins_50']),
    LootBox(id: 'box_silver', name: 'Coffre Argent', icon: '🎁', questsRequired: 7, possibleBadgeIds: ['loot_7', 'coins_100']),
    LootBox(id: 'box_gold', name: 'Coffre Or', icon: '🏆', questsRequired: 15, possibleBadgeIds: ['loot_15', 'coins_300']),
  ];

  void _saveAllToHive() {
    try {
      OfflineManager.saveData('game_data', state.toJson());

      final user = state.user;
      WidgetService.updateWidget(
        level: user.level,
        streak: user.streak,
        coins: user.coins,
      );

      final xpForCurrent = (user.level - 1) * (user.level - 1) * 100;
      final xpForNext = user.level * user.level * 100;
      WidgetService.updateProgressWidget(
        level: user.level,
        xp: user.globalXp,
        xpForCurrent: xpForCurrent,
        xpForNext: xpForNext,
        streak: user.streak,
        coins: user.coins,
        title: user.currentTitle,
      );

      final dailyQuests = state.quests
          .where((q) => q.frequency == QuestFrequency.daily)
          .take(5)
          .toList();
      WidgetService.updateDailyQuestsWidget(dailyQuests);

      final now = DateTime.now();
      final todayQuests = state.quests.where((q) {
        if (q.frequency == QuestFrequency.daily) return true;
        if (q.dueDate != null &&
            q.dueDate!.year == now.year &&
            q.dueDate!.month == now.month &&
            q.dueDate!.day == now.day) return true;
        return false;
      }).toList();
      WidgetService.updateCalendarWidget(
        year: now.year,
        month: now.month,
        todayDay: now.day,
        quests: todayQuests,
      );
    } catch (e) {
      debugPrint("Erreur lors de la sauvegarde Hive: $e");
    }
  }

  List<int> _trimHistory(List<int> history, int newValue) {
    final updated = List<int>.from(history)..add(newValue);
    return updated.length > 7 ? updated.sublist(updated.length - 7) : updated;
  }

  bool _listsDiffer(List<Bet> a, List<Bet> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i].status != b[i].status) return true;
    }
    return false;
  }

  bool _unlockBadge(List<String> badgeIds, String id, String title, {String prefix = "Nouveau Badge !"}) {
    if (!badgeIds.contains(id)) {
      badgeIds.add(id);
      NotificationService.showFeedback(prefix, "Vous avez débloqué : $title");
      return true;
    }
    return false;
  }

  // ====== ÉCONOMIE ======

  int get coins => state.user.coins;

  void addCoins(int amount) {
    state = state.copyWith(user: state.user.copyWith(coins: state.user.coins + amount));
    _saveAllToHive();
  }

  bool spendCoins(int amount) {
    if (state.user.coins < amount) return false;
    state = state.copyWith(user: state.user.copyWith(coins: state.user.coins - amount));
    _saveAllToHive();
    return true;
  }

  // ====== BOUTIQUE ======

  bool buyItem(String itemId) {
    final item = state.shopItems.firstWhere((s) => s.id == itemId);

    if (item.type == 'character_part' && item.value != null) {
      if (state.user.unlockedCharacterParts.contains(item.value)) {
        NotificationService.showFeedback("Déjà possédé !", "Vous avez déjà cet objet.");
        return false;
      }
    }
    if (item.type == 'title' && item.value != null) {
      if (state.user.badgeIds.contains('title_${item.value}')) {
        NotificationService.showFeedback("Déjà possédé !", "Vous avez déjà ce titre.");
        return false;
      }
    }

    if (!spendCoins(item.cost)) return false;
    
    if (item.type == 'streak_freeze') {
      final count = item.id == 'freeze_3' ? 3 : 1;
      state = state.copyWith(user: state.user.copyWith(streakFreezeDaysLeft: state.user.streakFreezeDaysLeft + count));
      NotificationService.showFeedback("Achat réussi !", "Gel de série prolongé de $count jour(s).");
    } else if (item.type == 'title') {
      final currentBadgeIds = List<String>.from(state.user.badgeIds);
      currentBadgeIds.add('title_${item.value}');
      state = state.copyWith(user: state.user.copyWith(badgeIds: currentBadgeIds));
      NotificationService.showFeedback("Titre débloqué !", "Vous avez débloqué : ${item.value}");
    } else if (item.type == 'character_part' && item.value != null) {
      final parts = List<String>.from(state.user.unlockedCharacterParts);
      parts.add(item.value!);
      final currentParts = Map<String, String>.from(state.user.characterParts);
      final cat = UserProfile.allParts.where((p) => p.id == item.value).firstOrNull?.category;
      if (cat != null) currentParts[cat] = item.value!;
      state = state.copyWith(user: state.user.copyWith(unlockedCharacterParts: parts, characterParts: currentParts));
      NotificationService.showFeedback("Pièce débloquée !", "Vous avez débloqué : ${item.name} (équipé automatiquement)");
    }
    
    _saveAllToHive();
    return true;
  }

  // ====== RÉCOMPENSE QUOTIDIENNE ======

  void claimDailyReward() {
    final now = DateTime.now();
    final user = state.user;
    final lastReward = user.lastDailyRewardDate;
    int newDay = 1;
    
    if (lastReward != null && _isSameDay(lastReward, now)) return;
    
    if (lastReward != null && now.difference(lastReward).inHours < 48) {
      newDay = (user.dailyRewardDay % 7) + 1;
    }
    
    final rewards = [10, 15, 25, 40, 60, 80, 150];
    final coinsGained = rewards[newDay - 1];
    final newMultiplier = min(2.0, (user.xpMultiplier + 0.1).toDouble());
    
    state = state.copyWith(user: state.user.copyWith(
      coins: user.coins + coinsGained,
      dailyRewardDay: newDay,
      lastDailyRewardDate: now,
      streak: user.streak + 1,
      xpMultiplier: newMultiplier,
    ));
    
    _checkStreakMilestones();
    
    NotificationService.showFeedback(
      "Récompense quotidienne !",
      "Jour $newDay : +$coinsGained pièces  (x${newMultiplier.toStringAsFixed(1)})",
    );
    if (state.user.soundVolume > 0 || state.user.hapticLevel > 0) {
      AudioService.playSuccess(volume: state.user.soundVolume, hapticLevel: state.user.hapticLevel);
    }
    _saveAllToHive();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

  // ====== PÉNALITÉ QUOTIDIENNE ======

  void checkDailyPenalties() {
    final now = DateTime.now();
    if (state.lastPenaltyDate != null && _isSameDay(state.lastPenaltyDate!, now)) return;

    final dailyQuests = state.quests.where((q) => q.frequency == QuestFrequency.daily).toList();
    int penalty = 0;

    for (final quest in dailyQuests) {
      if (quest.lastCompletedDate == null || !_isSameDay(quest.lastCompletedDate!, now)) {
        if (state.user.streakFreezeDaysLeft > 0) {
          state = state.copyWith(user: state.user.copyWith(streakFreezeDaysLeft: state.user.streakFreezeDaysLeft - 1));
          NotificationService.showFeedback("Gel de série utilisé !", "Votre série est protégée pour aujourd'hui.");
        } else {
          penalty += quest.xpRewardValue ~/ 2;
        }
      }
    }

    if (penalty > 0) {
      final newXp = max(0, state.user.globalXp - penalty);
      final coinPenalty = (penalty ~/ 10).clamp(0, state.user.coins);
      
      state = state.copyWith(
        user: state.user.copyWith(
          globalXp: newXp,
          level: _calculateLevel(newXp),
          coins: state.user.coins - coinPenalty,
          xpMultiplier: 1.0,
        ),
        lastPenaltyDate: now,
      );
      NotificationService.showFeedback("Pénalité !", "Quêtes quotidiennes non faites : -$penalty XP, -$coinPenalty pièces. Multiplicateur réinitialisé.");
    } else {
      state = state.copyWith(lastPenaltyDate: now);
    }
    _saveAllToHive();
  }

  // ====== STREAK FREEZE ======

  void activateStreakFreeze() {
    if (!spendCoins(50)) return;
    state = state.copyWith(user: state.user.copyWith(streakFreezeDaysLeft: state.user.streakFreezeDaysLeft + 1));
    NotificationService.showFeedback("Série gelée !", "Votre prochaine journée manquée ne cassera pas votre série.");
    _saveAllToHive();
  }

  // ====== COFFRES / LOOT BOXES ======

  void addLootBoxProgress() {
    state = state.copyWith(lootBoxProgress: state.lootBoxProgress + 1);
    _saveAllToHive();
  }

  String? openLootBox() {
    if (state.lootBoxes.isEmpty) return null;
    final eligible = state.lootBoxes.where((b) => state.lootBoxProgress >= b.questsRequired).toList();
    if (eligible.isEmpty) return null;

    final box = eligible.first;
    final coinReward = 20 + Random().nextInt(80);
    addCoins(coinReward);

    bool gotBadge = false;
    if (Random().nextDouble() < 0.3) {
      final currentBadgeIds = List<String>.from(state.user.badgeIds);
      _unlockBadge(currentBadgeIds, 'loot_found', 'Chercheur de Trésor 🎲', prefix: 'Badge spécial coffre !');
      state = state.copyWith(user: state.user.copyWith(badgeIds: currentBadgeIds));
      gotBadge = true;
    }

    state = state.copyWith(lootBoxProgress: state.lootBoxProgress - box.questsRequired);
    _saveAllToHive();

    final msg = '+$coinReward pièces${gotBadge ? '\n🎲 Badge spécial débloqué !' : ''}';
    return msg;
  }

  void dismissCelebration() {
    state = state.copyWith(celebrationPending: false);
  }

  // ====== AUDIO / HAPTICS ======

  void setSoundVolume(double volume) {
    state = state.copyWith(user: state.user.copyWith(soundVolume: volume.clamp(0.0, 1.0)));
    _saveAllToHive();
  }

  void setHapticLevel(int level) {
    state = state.copyWith(user: state.user.copyWith(hapticLevel: level.clamp(0, 3)));
    _saveAllToHive();
  }

  // ====== BADGES & FOMO ======

  void checkBadges() {
    final user = state.user;
    final completedQuestsCount = state.quests.where((q) => q.status == QuestStatus.completed).length;
    final currentBadgeIds = List<String>.from(user.badgeIds);
    bool changed = false;

    if (user.globalXp >= 1000) changed = _unlockBadge(currentBadgeIds, 'xp_1000', 'Apprenti motivé') || changed;
    if (completedQuestsCount >= 10) changed = _unlockBadge(currentBadgeIds, 'quest_10', 'Persévérant') || changed;
    if (user.streak >= 3) changed = _unlockBadge(currentBadgeIds, 'streak_3', 'Régulier') || changed;
    if (user.level >= 10) changed = _unlockBadge(currentBadgeIds, 'level_10', 'Vétéran') || changed;
    if (user.coins >= 500) changed = _unlockBadge(currentBadgeIds, 'coins_500', 'Économiseur') || changed;

    if (changed) {
      state = state.copyWith(user: user.copyWith(badgeIds: currentBadgeIds));
      if (state.user.soundVolume > 0 || state.user.hapticLevel > 0) {
      AudioService.playLevelUp(volume: state.user.soundVolume, hapticLevel: state.user.hapticLevel);
    }
      _saveAllToHive();
    }
  }

  // ====== PERSONNALISATION ======

  void selectCharacterPart(String partId) {
    final def = UserProfile.allParts.where((p) => p.id == partId).firstOrNull;
    if (def == null) return;
    if (!state.user.hasPart(partId)) return;
    final parts = Map<String, String>.from(state.user.characterParts);
    parts[def.category] = partId;
    state = state.copyWith(user: state.user.copyWith(characterParts: parts));
    _saveAllToHive();
  }

  void _checkCharacterPartUnlocks() {
    final user = state.user;
    final currentParts = List<String>.from(user.unlockedCharacterParts);
    bool changed = false;

    for (final part in UserProfile.allParts) {
      if (!currentParts.contains(part.id) && user.canUnlockPart(part.id)) {
        currentParts.add(part.id);
        changed = true;
        NotificationService.showFeedback("Nouvelle pièce !", "${part.label} débloqué !");
      }
    }

    if (changed) {
      final parts = Map<String, String>.from(user.characterParts);
      for (final part in UserProfile.allParts) {
        if (currentParts.contains(part.id) && parts[part.category] == null) {
          parts[part.category] = part.id;
        }
      }
      state = state.copyWith(user: user.copyWith(unlockedCharacterParts: currentParts, characterParts: parts));
      if (state.user.soundVolume > 0 || state.user.hapticLevel > 0) {
      AudioService.playLevelUp(volume: state.user.soundVolume, hapticLevel: state.user.hapticLevel);
    }
      _saveAllToHive();
    }
  }

  // ====== PALIERS DE STREAK ======

  void _checkStreakMilestones() {
    final user = state.user;
    final current = List<int>.from(user.claimedStreakMilestones);
    bool changed = false;

    for (final milestone in UserProfile.streakMilestones) {
      if (user.streak >= milestone && !current.contains(milestone)) {
        current.add(milestone);
        final coins = UserProfile.milestoneCoins[milestone] ?? 0;
        state = state.copyWith(user: state.user.copyWith(coins: state.user.coins + coins, claimedStreakMilestones: current));
        changed = true;
        NotificationService.showFeedback("Palier de série !", "$milestone jours ! +$coins pièces ! 🎉");
      }
    }

    if (changed) {
      if (state.user.soundVolume > 0 || state.user.hapticLevel > 0) {
      AudioService.playLevelUp(volume: state.user.soundVolume, hapticLevel: state.user.hapticLevel);
    }
      _saveAllToHive();
    }
  }

  List<Map<String, dynamic>> getStreakMilestones() {
    final user = state.user;
    return UserProfile.streakMilestones.map((day) => <String, dynamic>{
      'day': day,
      'coins': UserProfile.milestoneCoins[day],
      'claimed': user.hasClaimedMilestone(day),
    }).toList();
  }

  // ====== QUESTION DU SOIR ======

  bool canSubmitEveningEntry() {
    final today = DateTime.now();
    return !state.eveningLog.any((e) =>
      e.date.year == today.year &&
      e.date.month == today.month &&
      e.date.day == today.day);
  }

  void submitEveningEntry(String text, String mood) {
    if (!canSubmitEveningEntry()) return;
    const coinReward = 10;
    final entry = EveningEntry(date: DateTime.now(), text: text, mood: mood, coinReward: coinReward);
    state = state.copyWith(
      eveningLog: [...state.eveningLog, entry],
      user: state.user.copyWith(coins: state.user.coins + coinReward),
    );
    NotificationService.showFeedback("Bilan du soir !", "+$coinReward pièces pour votre journal 📝");
    _saveAllToHive();
  }

  void addFocusXp(int minutes) {
    final xpGain = minutes * 5;
    final newGlobalXp = state.user.globalXp + xpGain;
    
    final currentBadgeIds = List<String>.from(state.user.badgeIds);

    if (minutes >= 60) _unlockBadge(currentBadgeIds, 'focus_60', 'Concentration Absolue', prefix: 'Nouveau Badge Focus !');
    if (minutes >= 20) _unlockBadge(currentBadgeIds, 'focus_20', 'Maître Zen', prefix: 'Nouveau Badge Focus !');
    if (minutes >= 10) _unlockBadge(currentBadgeIds, 'focus_10', 'Esprit Calme', prefix: 'Nouveau Badge Focus !');
    if (minutes >= 5) _unlockBadge(currentBadgeIds, 'focus_5', 'Moine Novice', prefix: 'Nouveau Badge Focus !');

    state = state.copyWith(
      user: state.user.copyWith(
        globalXp: newGlobalXp,
        level: _calculateLevel(newGlobalXp),
        badgeIds: currentBadgeIds,
      ),
    );
    if (minutes > 0) _addWeeklyXp(xpGain);
    _checkCharacterPartUnlocks();
    _saveAllToHive();
  }

  void reorderQuests(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final items = List<Quest>.from(state.quests);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = state.copyWith(quests: items);
    _saveAllToHive();
  }

  void reorderSkills(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final items = List<Skill>.from(state.skills);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    final categories = items.map((s) => s.category).toList();
    state = state.copyWith(skills: items, categories: categories);
    _saveAllToHive();
  }

  void addBet(Bet bet) {
    state = state.copyWith(bets: [...state.bets, bet]);
    _saveAllToHive();
    NotificationService.scheduleQuestReminder(bet.id, "Pari: ${bet.title}", bet.deadline);
  }

  void checkBets() {
    final now = DateTime.now();
    final updatedBets = <Bet>[];
    int xpAdjustment = 0;

    for (final bet in state.bets) {
      if (bet.status == BetStatus.active && now.isAfter(bet.deadline)) {
        bool allCompleted = true;
        for (final qId in bet.linkedQuestIds) {
          final fallbackCategory = state.categories.isNotEmpty ? state.categories.first : SkillCategory(id: '0', label: 'Général');
          final quest = state.quests.firstWhere((q) => q.id == qId, orElse: () => Quest(id: '', title: '', description: '', difficulty: Difficulty.easy, category: fallbackCategory));
          if (quest.id.isEmpty || quest.status != QuestStatus.completed) {
            allCompleted = false;
            break;
          }
        }
        if (allCompleted) {
          updatedBets.add(bet.copyWith(status: BetStatus.won));
          xpAdjustment += bet.rewardXp;
        } else {
          updatedBets.add(bet.copyWith(status: BetStatus.lost));
          xpAdjustment -= bet.penaltyXp;
        }
      } else {
        updatedBets.add(bet);
      }
    }

    if (xpAdjustment != 0) {
      final newGlobalXp = max(0, state.user.globalXp + xpAdjustment);
      state = state.copyWith(
        user: state.user.copyWith(globalXp: newGlobalXp, level: _calculateLevel(newGlobalXp)),
        bets: updatedBets,
      );
      _saveAllToHive();
    } else if (_listsDiffer(updatedBets, state.bets)) {
      state = state.copyWith(bets: updatedBets);
      _saveAllToHive();
    }
  }

  void addCategory(String label, String iconName) {
    final newCategory = SkillCategory(id: DateTime.now().toString(), label: label, iconName: iconName);
    state = state.copyWith(
      categories: [...state.categories, newCategory],
      skills: [...state.skills, Skill(category: newCategory, xp: 0, level: 1, xpHistory: List.filled(7, 0))]
    );
    _saveAllToHive();
  }

  void deleteCategory(String categoryId) {
    state = state.copyWith(
      categories: state.categories.where((c) => c.id != categoryId).toList(),
      skills: state.skills.where((s) => s.category.id != categoryId).toList()
    );
    _saveAllToHive();
  }

  void renameCategory(String categoryId, String newLabel) {
    state = state.copyWith(
      categories: state.categories.map((c) => c.id == categoryId ? SkillCategory(id: c.id, label: newLabel, iconName: c.iconName) : c).toList(),
      skills: state.skills.map((s) {
        if (s.category.id == categoryId) {
          return Skill(
            category: SkillCategory(id: s.category.id, label: newLabel, iconName: s.category.iconName),
            xp: s.xp, level: s.level,
            xpHistory: List.from(s.xpHistory),
          );
        }
        return s;
      }).toList()
    );
    _saveAllToHive();
  }

  String exportData() => jsonEncode(OfflineManager.getData('game_data'));

  void importData(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      if (data is Map<String, dynamic>) {
        final parsedState = GameState.fromJson(data);
        OfflineManager.saveData('game_data', parsedState.toJson());
        state = parsedState;
      } else {
        debugPrint("Erreur d'importation : les données décodées ne sont pas une Map.");
      }
    } catch (e, stacktrace) {
      debugPrint("Erreur lors de l'importation des données : $e\n$stacktrace");
    }
  }

  void updatePseudo(String newPseudo) {
    state = state.copyWith(user: state.user.copyWith(pseudo: newPseudo));
    _saveAllToHive();
  }

  void toggleQuestStatus(String questId) {
    final questIndex = state.quests.indexWhere((q) => q.id == questId);
    if (questIndex == -1) return;

    final quest = state.quests[questIndex];
    final isNowCompleted = quest.status != QuestStatus.completed;

    if (isNowCompleted && DateTime.now().difference(quest.createdAt).inMinutes < 3) {
      NotificationService.showFeedback("Trop tôt !", "Cette quête a été créée il y a moins de 3 minutes.");
      return;
    }

    final updatedQuest = quest.copyWith(
      status: isNowCompleted ? QuestStatus.completed : QuestStatus.todo,
      lastCompletedDate: isNowCompleted ? DateTime.now() : null,
    );

    final updatedQuests = List<Quest>.from(state.quests);
    updatedQuests[questIndex] = updatedQuest;

    final xpAdjustment = isNowCompleted
        ? (quest.xpRewardValue * state.user.xpMultiplier).round()
        : -quest.xpRewardValue;
    final newGlobalXp = max(0, state.user.globalXp + xpAdjustment);

    final updatedSkills = List<Skill>.from(state.skills);
    final skillIndex = updatedSkills.indexWhere((s) => s.category.id == quest.category.id);
    if (skillIndex != -1) {
      final skill = updatedSkills[skillIndex];
      final newSkillXp = max(0, skill.xp + xpAdjustment);
      updatedSkills[skillIndex] = skill.copyWith(
        xp: newSkillXp,
        level: _calculateLevel(newSkillXp),
        xpHistory: _trimHistory(skill.xpHistory, xpAdjustment),
      );
    }

    if (isNowCompleted) {
      if (state.user.soundVolume > 0 || state.user.hapticLevel > 0) {
        AudioService.playSuccess(volume: state.user.soundVolume, hapticLevel: state.user.hapticLevel);
      }
      addCoins(quest.xpRewardValue ~/ 10 + 1);
      addLootBoxProgress();
      state = state.copyWith(celebrationPending: true);
      NotificationService.showFeedback("Bravo !", "Vous avez terminé : ${quest.title}. +$xpAdjustment XP !");
    }

    state = state.copyWith(
      user: state.user.copyWith(globalXp: newGlobalXp, level: _calculateLevel(newGlobalXp)),
      quests: updatedQuests,
      skills: updatedSkills,
    );
    if (xpAdjustment > 0) _addWeeklyXp(xpAdjustment);
    checkBets();
    checkBadges();
    _checkCharacterPartUnlocks();
    _saveAllToHive();
  }

  void deleteQuest(String questId) {
    state = state.copyWith(quests: state.quests.where((q) => q.id != questId).toList());
    _saveAllToHive();
  }

  void updateQuest(Quest updatedQuest) {
    final currentQuests = List<Quest>.from(state.quests);
    final questIndex = currentQuests.indexWhere((q) => q.id == updatedQuest.id);
    if (questIndex != -1) {
      currentQuests[questIndex] = updatedQuest;
      state = state.copyWith(quests: currentQuests);
      _saveAllToHive();
      NotificationService.cancelReminder(updatedQuest.id);
      if (updatedQuest.reminderDate != null) {
        NotificationService.scheduleQuestReminder(updatedQuest.id, updatedQuest.title, updatedQuest.reminderDate!);
      }
    }
  }

  void addQuest(Quest quest) {
    state = state.copyWith(quests: [quest, ...state.quests]);
    _saveAllToHive();
    if (quest.reminderDate != null) {
      NotificationService.scheduleQuestReminder(quest.id, quest.title, quest.reminderDate!);
    }
  }

  int _calculateLevel(int xp) => (sqrt(xp / 100)).floor() + 1;

  void joinGuild(String guildId) {
    NotificationService.showFeedback("Guilde", "Fonctionnalité disponible avec le serveur.");
  }

  void leaveGuild() {
    state = state.copyWith(currentGuild: null, guildMessages: []);
    _saveAllToHive();
  }

  void createGuild(String name, String description, String tag) {
    NotificationService.showFeedback("Guilde", "Fonctionnalité disponible avec le serveur.");
  }

  void addChatMessage(String senderName, String text) {
    final msg = ChatMessage(
      id: DateTime.now().toString(),
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(guildMessages: [...state.guildMessages, msg]);
    _saveAllToHive();
  }

  // ====== WEEKLY XP LOG ======

  List<int> getWeeklyXpLog() => List.from(state.weeklyXpLog);

  int get totalWeeklyXp => state.weeklyXpLog.fold(0, (a, b) => a + b);

  void _addWeeklyXp(int amount) {
    if (amount <= 0) return;
    final idx = DateTime.now().weekday - 1; // Monday=0 … Sunday=6
    var log = List<int>.from(state.weeklyXpLog);
    if (log.length != 7) log = List.filled(7, 0);
    log[idx] += amount;
    state = state.copyWith(weeklyXpLog: log);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
