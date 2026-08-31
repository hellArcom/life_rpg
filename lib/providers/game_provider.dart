import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/game_models.dart'; 
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/server_service.dart';
import '../services/chat_service.dart';
import '../services/widget_service.dart';
import '../core/offline_manager.dart';
import '../core/data_migration.dart';
import '../core/utils.dart';

Object _unset = Object();

bool _chatSocketBound = false;
String? _activeGuildId;

ChatMessage _chatMessageFromSocket(Map<String, dynamic> data, String guildId) {
  DateTime ts;
  final raw = data['timestamp'] as String?;
  if (raw != null && RegExp(r'^\d{1,2}:\d{2}$').hasMatch(raw)) {
    final parts = raw.split(':');
    final now = DateTime.now();
    ts = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  } else {
    ts = DateTime.now();
  }
  return ChatMessage(
    id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    senderId: data['sender_id']?.toString() ?? '',
    senderName: data['sender_name'] as String? ?? '?',
    text: data['content'] as String? ?? '',
    timestamp: ts,
    room: data['room'] as String? ?? 'guild_$guildId',
    deleted: data['deleted'] as bool? ?? false,
  );
}

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
  final List<Guild> myGuilds;
  final List<Guild> guildLeaderboard;
  final List<GuildMember> guildMembers;
  final List<GuildInvitation> guildInvitations;
  final List<GuildQuest> guildQuests;
  final List<GuildLog> guildLogs;
  final List<ChatMessage> guildMessages;
  final List<LeaderboardEntry> leaderboard;
  final List<ShopItem> shopItems;
  final List<LootBox> lootBoxes;
  final int lootBoxProgress;
  final List<int> weeklyXpLog;
  final DateTime? lastWeeklyLogWeekStart;
  final DateTime? lastPenaltyDate;
  final bool celebrationPending;
  final List<EveningEntry> eveningLog;
  final int dataVersion;
  final bool isAccountLinked;
  final Map<String, String> guildEncryptionKeys;

  GameState({
    required this.user,
    required this.skills,
    required this.quests,
    required this.rewards,
    required this.categories,
    required this.bets,
    required this.availableBadges,
    currentGuild,
    this.availableGuilds = const [],
    this.myGuilds = const [],
    this.guildMembers = const [],
    this.guildInvitations = const [],
    this.guildQuests = const [],
    this.guildLogs = const [],
    this.guildMessages = const [],
    this.leaderboard = const [],
    this.shopItems = const [],
    this.lootBoxes = const [],
    this.lootBoxProgress = 0,
    this.weeklyXpLog = const [],
    this.lastWeeklyLogWeekStart,
    this.lastPenaltyDate,
    this.celebrationPending = false,
    this.eveningLog = const [],
    this.guildLeaderboard = const [],
    this.dataVersion = 0,
    this.isAccountLinked = false,
    this.guildEncryptionKeys = const {},
  }) : currentGuild = currentGuild;

GameState copyWith({
    UserProfile? user,
    List<Skill>? skills,
    List<Quest>? quests,
    List<Reward>? rewards,
    List<SkillCategory>? categories,
    List<Bet>? bets,
    List<GameBadge>? availableBadges,
    Guild? currentGuild,
    bool? clearCurrentGuild,
    List<Guild>? availableGuilds,
    List<Guild>? myGuilds,
    List<Guild>? guildLeaderboard,
    List<GuildMember>? guildMembers,
    List<GuildInvitation>? guildInvitations,
    List<GuildQuest>? guildQuests,
    List<GuildLog>? guildLogs,
    List<ChatMessage>? guildMessages,
    List<LeaderboardEntry>? leaderboard,
    List<ShopItem>? shopItems,
    List<LootBox>? lootBoxes,
    int? lootBoxProgress,
    List<int>? weeklyXpLog,
    DateTime? lastWeeklyLogWeekStart,
    DateTime? lastPenaltyDate,
    bool? celebrationPending,
    List<EveningEntry>? eveningLog,
    int? dataVersion,
    bool? isAccountLinked,
    Map<String, String>? guildEncryptionKeys,
  }) {
    return GameState(
      user: user ?? this.user,
      skills: skills ?? this.skills,
      quests: quests ?? this.quests,
      rewards: rewards ?? this.rewards,
      categories: categories ?? this.categories,
      bets: bets ?? this.bets,
      availableBadges: availableBadges ?? this.availableBadges,
      currentGuild: clearCurrentGuild == true ? null : (currentGuild ?? (this.currentGuild == _unset ? null : this.currentGuild)),
      availableGuilds: availableGuilds ?? this.availableGuilds,
      myGuilds: myGuilds ?? this.myGuilds,
      guildLeaderboard: guildLeaderboard ?? this.guildLeaderboard,
      guildMembers: guildMembers ?? this.guildMembers,
      guildInvitations: guildInvitations ?? this.guildInvitations,
      guildQuests: guildQuests ?? this.guildQuests,
      guildLogs: guildLogs ?? this.guildLogs,
      guildMessages: guildMessages ?? this.guildMessages,
      leaderboard: leaderboard ?? this.leaderboard,
      shopItems: shopItems ?? this.shopItems,
      lootBoxes: lootBoxes ?? this.lootBoxes,
      lootBoxProgress: lootBoxProgress ?? this.lootBoxProgress,
      weeklyXpLog: weeklyXpLog ?? this.weeklyXpLog,
      lastWeeklyLogWeekStart: lastWeeklyLogWeekStart ?? this.lastWeeklyLogWeekStart,
      lastPenaltyDate: lastPenaltyDate ?? this.lastPenaltyDate,
      celebrationPending: celebrationPending ?? this.celebrationPending,
      eveningLog: eveningLog ?? this.eveningLog,
      dataVersion: dataVersion ?? this.dataVersion,
      isAccountLinked: isAccountLinked ?? this.isAccountLinked,
      guildEncryptionKeys: guildEncryptionKeys ?? this.guildEncryptionKeys,
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
    'lastWeeklyLogWeekStart': lastWeeklyLogWeekStart?.toIso8601String(),
    'lastPenaltyDate': lastPenaltyDate?.toIso8601String(),
    'celebrationPending': false,
    'eveningLog': eveningLog.map((e) => e.toJson()).toList(),
    'dataVersion': dataVersion,
    'isAccountLinked': isAccountLinked,
    'currentGuild': currentGuild?.toJson(),
    'availableGuilds': availableGuilds.map((g) => g.toJson()).toList(),
    'myGuilds': myGuilds.map((g) => g.toJson()).toList(),
    'guildLeaderboard': guildLeaderboard.map((g) => g.toJson()).toList(),
    'guildMembers': guildMembers.map((m) => m.toJson()).toList(),
    'guildInvitations': guildInvitations.map((i) => i.toJson()).toList(),
    'guildQuests': guildQuests.map((q) => q.toJson()).toList(),
    'guildLogs': guildLogs.map((l) => l.toJson()).toList(),
    'guildMessages': guildMessages.map((m) => m.toJson()).toList(),
    'leaderboard': leaderboard.map((l) => l.toJson()).toList(),
    'guildEncryptionKeys': guildEncryptionKeys,
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
      lootBoxProgress: max(0, json['lootBoxProgress'] ?? 0),
      weeklyXpLog: _parseWeeklyXpLog(json['weeklyXpLog']),
      lastWeeklyLogWeekStart: json['lastWeeklyLogWeekStart'] != null ? DateTime.parse(json['lastWeeklyLogWeekStart']) : null,
      lastPenaltyDate: json['lastPenaltyDate'] != null ? DateTime.parse(json['lastPenaltyDate']) : null,
      celebrationPending: false,
      eveningLog: (json['eveningLog'] as List<dynamic>?)?.map((e) => EveningEntry.fromJson(e)).toList() ?? [],
      dataVersion: json['dataVersion'] ?? 0,
      isAccountLinked: json['isAccountLinked'] ?? false,
      currentGuild: json['currentGuild'] != null ? Guild.fromJson(json['currentGuild']) : null,
      availableGuilds: (json['availableGuilds'] as List<dynamic>?)?.map((g) => Guild.fromJson(g)).toList() ?? [],
      myGuilds: (json['myGuilds'] as List<dynamic>?)?.map((g) => Guild.fromJson(g)).toList() ?? [],
      guildLeaderboard: (json['guildLeaderboard'] as List<dynamic>?)?.map((g) => Guild.fromJson(g)).toList() ?? [],
      guildMembers: (json['guildMembers'] as List<dynamic>?)?.map((m) => GuildMember.fromJson(m)).toList() ?? [],
      guildInvitations: (json['guildInvitations'] as List<dynamic>?)?.map((i) => GuildInvitation.fromJson(i)).toList() ?? [],
      guildQuests: (json['guildQuests'] as List<dynamic>?)?.map((q) => GuildQuest.fromJson(q)).toList() ?? [],
      guildLogs: (json['guildLogs'] as List<dynamic>?)?.map((l) => GuildLog.fromJson(l)).toList() ?? [],
      guildMessages: (json['guildMessages'] as List<dynamic>?)?.map((m) => ChatMessage.fromJson(m)).toList() ?? [],
      leaderboard: (json['leaderboard'] as List<dynamic>?)?.map((l) => LeaderboardEntry.fromJson(l)).toList() ?? [],
      guildEncryptionKeys: (json['guildEncryptionKeys'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
    );
  }

  static List<int> _parseWeeklyXpLog(dynamic raw) {
    final list = List<int>.from(raw ?? []);
    if (list.length != 7) return List.filled(7, 0);
    return list;
  }
}

class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() {
    try {
      final savedData = OfflineManager.getData('game_data');
      if (savedData != null && savedData is Map<String, dynamic>) {
        final rawVersion = savedData['dataVersion'];
        final needsMigration = rawVersion is! int || rawVersion < currentDataVersion;
        if (needsMigration) {
          final existingBackup = OfflineManager.getData('game_data_backup');
          if (existingBackup == null) {
            OfflineManager.saveData('game_data_backup', savedData);
          }
        }
        final migrated = migrateData(savedData);
        final loaded = GameState.fromJson(migrated);
        if (needsMigration) {
          OfflineManager.saveData('game_data', migrated);
        }
        Future.microtask(() { try { checkBadges(); } catch (_) {} });
        return loaded;
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
    ShopItem(id: 'hat_4', name: 'Salière Aventurier', description: 'Une salière pratique', icon: '🧢', cost: 100, type: 'character_part', value: 'hat_4'),
    ShopItem(id: 'hat_5', name: 'Chapeau Magique', description: 'Un chapeau de mage étoilé', icon: '🎩', cost: 120, type: 'character_part', value: 'hat_5'),
    ShopItem(id: 'acc_4', name: 'Breloques d\'Or', description: 'Breloques chatoyantes', icon: '🔮', cost: 90, type: 'character_part', value: 'acc_4'),
    ShopItem(id: 'hair_6', name: 'Cheveux Indigo', description: 'Des cheveux teints en indigo', icon: '💜', cost: 40, type: 'character_part', value: 'hair_6'),
    ShopItem(id: 'hair_7', name: 'Cheveux Roux', description: 'Une teinte rousse flamboyante', icon: '🟠', cost: 60, type: 'character_part', value: 'hair_7'),
    ShopItem(id: 'outfit_6', name: 'Tenue de Ranger', description: 'Tenue d\'aventurier des forêts', icon: '🏹', cost: 60, type: 'character_part', value: 'outfit_6'),
    ShopItem(id: 'outfit_7', name: 'Tenue d\'Écuyer', description: 'Une armure légère d\'écuyer', icon: '🛡️', cost: 80, type: 'character_part', value: 'outfit_7'),
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

  Timer? _saveTimer;
  int _saveCounter = 0;

  void _saveAllToHive({bool force = false}) {
    _saveCounter++;
    _saveTimer?.cancel();
    // Debounce: save after 500ms of no mutations, or immediately if forced
    final delay = force ? Duration.zero : const Duration(milliseconds: 500);
    _saveTimer = Timer(delay, () {
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

        final now = DateTime.now();
        final todayQuests = state.quests.where((q) {
          if (q.frequency == QuestFrequency.daily) return true;
          if (q.dueDate != null &&
              q.dueDate!.year == now.year &&
              q.dueDate!.month == now.month &&
              q.dueDate!.day == now.day) {
            return true;
          }
          return false;
        }).toList();
        final dailyQuests = todayQuests.where((q) => q.frequency == QuestFrequency.daily).take(5).toList();
        WidgetService.updateDailyQuestsWidget(dailyQuests);
        WidgetService.updateCalendarWidget(
          year: now.year,
          month: now.month,
          todayDay: now.day,
          quests: todayQuests,
        );

        // Periodic Hive compaction (every 50 saves)
        if (_saveCounter % 50 == 0) {
          _compactHive();
        }
      } catch (e) {
        debugPrint("Erreur lors de la sauvegarde Hive: $e");
      }
    });
  }

  Future<void> _compactHive() async {
    try {
      final box = Hive.box('game_data');
      await box.compact();
      debugPrint('Hive compaction completed');
    } catch (e) {
      debugPrint('Hive compaction failed: $e');
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

  void addCoins(int amount, {bool save = true}) {
    state = state.copyWith(user: state.user.copyWith(coins: max(0, state.user.coins + amount)));
    if (save) _saveAllToHive();
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

    if (!spendCoins(item.cost)) {
      NotificationService.showFeedback("Pas assez de pièces !", "Vous n'avez pas assez de pièces pour cet achat.");
      return false;
    }
    
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
    
    if (lastReward != null && isSameDay(lastReward, now)) return;
    
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

  // ====== PÉNALITÉ QUOTIDIENNE ======

  void checkDailyPenalties() {
    final now = DateTime.now();
    if (state.lastPenaltyDate != null && isSameDay(state.lastPenaltyDate!, now)) return;

    final resetQuests = state.quests.map((q) {
      if (q.frequency == QuestFrequency.daily &&
          q.status == QuestStatus.completed &&
          q.lastCompletedDate != null &&
          !isSameDay(q.lastCompletedDate!, now)) {
        return q.copyWith(status: QuestStatus.todo, lastCompletedDate: null);
      }
      return q;
    }).toList();

    final dailyQuests = resetQuests.where((q) => q.frequency == QuestFrequency.daily).toList();
    int penalty = 0;
    int streakFreezeLeft = state.user.streakFreezeDaysLeft;
    bool usedFreeze = false;

    for (final quest in dailyQuests) {
      if (quest.lastCompletedDate == null || !isSameDay(quest.lastCompletedDate!, now)) {
        if (streakFreezeLeft > 0) {
          streakFreezeLeft--;
          usedFreeze = true;
        } else {
          penalty += quest.xpRewardValue ~/ 2;
        }
      }
    }

    final user = state.user;
    int? newGlobalXp;
    int? newCoins;
    double? newXpMultiplier;

    if (penalty > 0) {
      newGlobalXp = max(0, user.globalXp - penalty);
      newCoins = max(0, user.coins - (penalty ~/ 10));
      newXpMultiplier = 1.0;
    }

    state = state.copyWith(
      quests: resetQuests,
      user: user.copyWith(
        globalXp: newGlobalXp ?? user.globalXp,
        level: newGlobalXp != null ? _calculateLevel(newGlobalXp) : user.level,
        coins: newCoins ?? user.coins,
        xpMultiplier: newXpMultiplier ?? user.xpMultiplier,
        streakFreezeDaysLeft: streakFreezeLeft,
      ),
      lastPenaltyDate: now,
    );

    if (usedFreeze) {
      NotificationService.showFeedback("Gel de série utilisé !", "Votre série est protégée pour aujourd'hui.");
    }
    if (penalty > 0) {
      NotificationService.showFeedback("Pénalité !", "Quêtes quotidiennes non faites : -$penalty XP, -${penalty ~/ 10} pièces. Multiplicateur réinitialisé.");
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

  void addLootBoxProgress({bool save = true}) {
    state = state.copyWith(lootBoxProgress: state.lootBoxProgress + 1);
    if (save) _saveAllToHive();
  }

  void removeLootBoxProgress({bool save = true}) {
    state = state.copyWith(lootBoxProgress: max(0, state.lootBoxProgress - 1));
    if (save) _saveAllToHive();
  }

  String? openLootBox() {
    if (state.lootBoxes.isEmpty) return null;
    final eligible = state.lootBoxes.where((b) => state.lootBoxProgress >= b.questsRequired).toList();
    if (eligible.isEmpty) return null;

    final box = eligible.first;
    final coinReward = 20 + Random().nextInt(80);

    bool gotBadge = false;
    List<String>? currentBadgeIds;
    if (Random().nextDouble() < 0.3) {
      currentBadgeIds = List<String>.from(state.user.badgeIds);
      _unlockBadge(currentBadgeIds, 'loot_found', 'Chercheur de Trésor 🎲', prefix: 'Badge spécial coffre !');
      gotBadge = true;
    }

    state = state.copyWith(
      user: state.user.copyWith(
        coins: max(0, state.user.coins + coinReward),
        badgeIds: currentBadgeIds ?? state.user.badgeIds,
      ),
      lootBoxProgress: state.lootBoxProgress - box.questsRequired,
    );
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

  void updateEveningEntry(String id, String text, String mood) {
    final updatedLog = state.eveningLog.map((e) {
      if (e.id == id) {
        return e.copyWith(text: text, mood: mood);
      }
      return e;
    }).toList();
    state = state.copyWith(eveningLog: updatedLog);
    _saveAllToHive();
  }

  void deleteEveningEntry(String id) {
    final entry = state.eveningLog.where((e) => e.id == id).firstOrNull;
    if (entry == null) return;
    state = state.copyWith(
      eveningLog: state.eveningLog.where((e) => e.id != id).toList(),
      user: state.user.copyWith(coins: max(0, state.user.coins - entry.coinReward)),
    );
    NotificationService.showFeedback("Bilan supprimé", entry.coinReward > 0 ? '-${entry.coinReward}💰 retirées' : 'Entrée retirée de votre journal');
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

  void reorderQuests(String questId, String? beforeQuestId) {
    final items = List<Quest>.from(state.quests);
    final oldIndex = items.indexWhere((q) => q.id == questId);
    if (oldIndex == -1) return;
    final item = items.removeAt(oldIndex);

    final newIndex = beforeQuestId != null
        ? items.indexWhere((q) => q.id == beforeQuestId)
        : items.length;
    if (newIndex == -1) {
      items.add(item);
    } else {
      items.insert(newIndex, item);
    }
    state = state.copyWith(quests: items);
    _saveAllToHive();
  }

  void reorderSkills(int oldIndex, int newIndex) {
    final items = List<Skill>.from(state.skills);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    final categories = items.map((s) => s.category).toList();
    state = state.copyWith(skills: items, categories: categories);
    _saveAllToHive();
  }

  /// XP/coins reward cap for a bet, based on the linked quests' base difficulty.
  /// Prevents betting millions of XP on a single easy quest: max reward = 3x
  /// the sum of the linked quests' difficulty xpBase.
  static const int betXpMultiplier = 3;

  int maxBetRewardXp(List<String> linkedQuestIds) {
    if (linkedQuestIds.isEmpty) return 300;
    final linked = state.quests.where((q) => linkedQuestIds.contains(q.id));
    if (linked.isEmpty) return 300;
    return linked.fold(0, (sum, q) => sum + q.difficulty.xpBase * betXpMultiplier);
  }

  void addBet(Bet bet) {
    final cap = maxBetRewardXp(bet.linkedQuestIds);
    final clamped = bet.copyWith(
      rewardXp: bet.rewardXp.clamp(0, cap),
      penaltyXp: bet.penaltyXp.clamp(0, cap),
    );
    state = state.copyWith(bets: [...state.bets, clamped]);
    _saveAllToHive();
    NotificationService.scheduleQuestReminder(bet.id, "Pari: ${bet.title}", bet.deadline);
  }

  void checkBets() {
    final now = DateTime.now();
    final updatedBets = <Bet>[];
    int xpAdjustment = 0;

    for (final bet in state.bets) {
      if (bet.status == BetStatus.active && now.isAfter(bet.deadline)) {
        if (bet.linkedQuestIds.isEmpty) {
          updatedBets.add(bet);
          continue;
        }
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

  String exportData() {
    final raw = OfflineManager.getData('game_data');
    if (raw is Map<String, dynamic>) {
      return jsonEncode(migrateData(raw));
    }
    return jsonEncode(raw);
  }

  void importData(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      if (data is Map<String, dynamic>) {
        final migrated = migrateData(data);
        final parsedState = GameState.fromJson(migrated);
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

  // ====== PARRAINAGE & SERVEUR ======

  static const int referrerRewardCoins = 250;
  static const int referrerRewardFreezeDays = 3;
  static const int referrerRewardXp = 300;
  static const int refereeRewardCoins = 100;
  static const int refereeRewardXp = 100;

  static const String _codeCharset = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Garantit que l'utilisateur possède un code de parrainage unique.
  String ensureReferralCode() {
    var code = state.user.referralCode;
    if (code.isEmpty) {
      final rnd = Random();
      code = List.generate(
        8,
        (_) => _codeCharset[rnd.nextInt(_codeCharset.length)],
      ).join();
      state = state.copyWith(user: state.user.copyWith(referralCode: code));
      _saveAllToHive();
    }
    return code;
  }

  Future<void> checkAccountLinkStatus() async {
    final status = await ServerService.getSyncStatus();
    if (status != null) {
      final linked = status['linked'] == true;
      if (state.isAccountLinked != linked) {
        state = state.copyWith(isAccountLinked: linked);
        _saveAllToHive();
      }
    }
  }

  /// Synchronisation au lancement : enregistre l'app + ping + applique les
  /// récompenses de parrainage en attente + synchronise les données de compte.
  Future<void> syncWithServer({String mode = 'merge'}) async {
    try {
      final code = ensureReferralCode();
      if (!await ServerService.isRegistered()) {
        final reg = await ServerService.register(code);
        if (reg == null) {
          await NotificationService.showFeedback('Sync', 'Échec de l\'enregistrement : serveur inaccessible');
          return;
        }
        _adoptServerReferralCode(reg['referral_code']);
      }
      final res = await ServerService.ping();
      if (res == null) {
        await NotificationService.showFeedback('Sync', 'Serveur inaccessible (ping échoué)');
        return;
      }
      _adoptServerReferralCode(res['referral_code']);
      final rewards = res['pending_rewards'];
      if (rewards is List && rewards.isNotEmpty) {
        await _applyServerRewards(rewards);
      }
      await checkAccountLinkStatus();
      
      // Récupérer le mot de passe stocké pour le chiffrement E2E
      final password = await ServerService.getUserPassword();
      await _syncAccountData(mode, password: password);
    } catch (e) {
      debugPrint('syncWithServer : $e');
      await NotificationService.showFeedback('Sync', 'Erreur de synchronisation');
    }
  }

  Future<void> _syncAccountData(String mode, {String? password}) async {
    try {
      final localData = {
        'level': state.user.level,
        'globalXp': state.user.globalXp,
        'coins': state.user.coins,
        'streak': state.user.streak,
        'badgeIds': state.user.badgeIds,
        'total_quests_completed': state.quests.where((q) => q.status == QuestStatus.completed).length,
      };
      final res = await ServerService.syncData(localData, mode: mode, password: password);
      if (res == null) {
        await NotificationService.showFeedback('Sync', 'Échec sync : serveur inaccessible');
        return;
      }
      // Déchiffrer la réponse si chiffrement E2E utilisé
      Map<String, dynamic>? data;
      if (password != null && password.isNotEmpty) {
        final serverData = ServerService.decryptSyncResponse(res, password);
        if (serverData != null) {
          data = serverData;
        } else {
          // Decryption failed - password may have changed on web
          debugPrint('_syncAccountData: decryption failed, password may have changed on web');
          await NotificationService.showFeedback('Sync', 'Mot de passe modifié sur le web ? Réinitialisez votre mot de passe dans les paramètres.');
          return;
        }
      } else if (res['data'] != null) {
        // Non-encrypted fallback
        data = res['data'] as Map<String, dynamic>;
      }
      
      if (data != null) {
        // Max-merge : garder le maximum entre local et serveur
        final newLevel = data['level'] != null ? (state.user.level > (data['level'] as int) ? state.user.level : (data['level'] as int)) : state.user.level;
        final newGlobalXp = data['globalXp'] != null ? (state.user.globalXp > (data['globalXp'] as int) ? state.user.globalXp : (data['globalXp'] as int)) : state.user.globalXp;
        final newCoins = data['coins'] != null ? (state.user.coins > (data['coins'] as int) ? state.user.coins : (data['coins'] as int)) : state.user.coins;
        final newStreak = data['streak'] != null ? (state.user.streak > (data['streak'] as int) ? state.user.streak : (data['streak'] as int)) : state.user.streak;
        
        state = state.copyWith(user: state.user.copyWith(
          level: newLevel,
          globalXp: newGlobalXp,
          coins: newCoins,
          streak: newStreak,
        ));
        _saveAllToHive();
      } else {
        // Ni données chiffrées ni fallback : réponse inattendue / erreur
        await NotificationService.showFeedback('Sync', 'Réponse serveur invalide');
      }
    } catch (e) {
      debugPrint('_syncAccountData : $e');
      await NotificationService.showFeedback('Sync', 'Erreur sync données');
    }
  }

  /// Le code affiché doit toujours correspondre à celui connu du serveur,
  /// sinon les amis qui le saisissent recevraient « invalid ».
  void _adoptServerReferralCode(dynamic serverCode) {
    if (serverCode is String &&
        serverCode.isNotEmpty &&
        serverCode != state.user.referralCode) {
      state = state.copyWith(
        user: state.user.copyWith(referralCode: serverCode),
      );
      _saveAllToHive();
    }
  }

  /// Soumet le code d'un ami. Renvoie un statut pour l'écran :
  /// 'ok' | 'self' | 'already' | 'invalid' | 'offline'.
  Future<String> submitReferral(String entered) async {
    final user = state.user;
    final myCode = ensureReferralCode();
    final code = entered.trim().toUpperCase();
    if (code.isEmpty) return 'invalid';
    if (code == myCode) return 'self';
    if (user.referralSubmitted) return 'already';

    try {
      final res = await ServerService.submitReferral(code);
      if (res == null) return 'offline';
      final status = res['status'];
      if (status == 'ok') {
        final newXp = state.user.globalXp + refereeRewardXp;
        state = state.copyWith(
          user: state.user.copyWith(
            coins: state.user.coins + refereeRewardCoins,
            globalXp: newXp,
            level: _calculateLevel(newXp),
            referredBy: code,
            referralSubmitted: true,
          ),
        );
        NotificationService.showFeedback(
          "Parrainage réussi !",
          "+$refereeRewardCoins pièces et +$refereeRewardXp XP pour votre parrainage 🌟",
        );
        _saveAllToHive();
        return 'ok';
      }
      return status is String ? status : 'invalid';
    } catch (e) {
      debugPrint('submitReferral : $e');
      return 'offline';
    }
  }

  Future<void> _applyServerRewards(List<dynamic> rewards) async {
    final applied = _appliedRewardIds();
    var coins = state.user.coins;
    var freeze = state.user.streakFreezeDaysLeft;
    var xp = state.user.globalXp;
    final newlyApplied = <String>[];
    var rewarded = false;

    for (final raw in rewards) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['reward_id'] ?? raw['id'];
      if (id == null || applied.contains(id)) continue;

      final coinsGain = (raw['coins'] ?? 0) as int;
      final freezeGain = (raw['freeze_days'] ?? 0) as int;
      final xpGain = (raw['xp'] ?? 0) as int;

      coins = max(0, coins + coinsGain);
      freeze += freezeGain;
      xp = max(0, xp + xpGain);
      newlyApplied.add(id);
      rewarded = true;
    }

    if (!rewarded) return;

    state = state.copyWith(
      user: state.user.copyWith(
        coins: coins,
        streakFreezeDaysLeft: freeze,
        globalXp: xp,
        level: _calculateLevel(xp),
      ),
    );
    NotificationService.showFeedback(
      "Récompense de parrainage reçue !",
      "+$referrerRewardCoins pièces, gel de série +$referrerRewardFreezeDays jours et +$referrerRewardXp XP 🎉",
    );
    await OfflineManager.saveData('applied_server_rewards', [...applied, ...newlyApplied]);
    _saveAllToHive();
  }

  List<String> _appliedRewardIds() {
    final saved = OfflineManager.getData('applied_server_rewards');
    if (saved is List) {
      return saved.map((e) => e.toString()).toList();
    }
    return const [];
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
        : -(quest.xpRewardValue * state.user.xpMultiplier).round();
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
      addCoins(quest.xpRewardValue ~/ 10 + 1, save: false);
      addLootBoxProgress(save: false);
      state = state.copyWith(celebrationPending: true);
      NotificationService.showFeedback("Bravo !", "Vous avez terminé : ${quest.title}. +$xpAdjustment XP !");
      // Cancel scheduled reminder for this quest
      NotificationService.cancelReminder(questId);
    } else {
      final coinsReward = quest.xpRewardValue ~/ 10 + 1;
      addCoins(-coinsReward, save: false);
      removeLootBoxProgress(save: false);
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
    NotificationService.cancelReminder(questId);
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

  Future<void> joinGuild(String guildId) async {
    final res = await ServerService.joinGuild(guildId);
    if (res == null) {
      NotificationService.showFeedback("Erreur", "Impossible de rejoindre la guilde");
      return;
    }
    final errorMsg = res['error'] is Map ? res['error']['message'] : res['error'];
    if (errorMsg != null) {
      NotificationService.showFeedback("Erreur", errorMsg.toString());
      return;
    }
    final message = res['message'] as String? ?? '';
    if (message.contains('rejoint') || message.contains('Candidature')) {
      await _refreshMyGuilds();
      NotificationService.showFeedback("Succès", message);
    } else {
      NotificationService.showFeedback("Info", message.isNotEmpty ? message : 'Action effectuée');
    }
  }

  Future<void> leaveGuild({bool showLog = true}) async {
    final guild = state.currentGuild;
    if (guild == null) return;
    final res = await ServerService.leaveGuild(guild.id, showLog: showLog);
    if (res == null) {
      NotificationService.showFeedback("Erreur", "Impossible de quitter la guilde");
      return;
    }
    // Handle encryption key rotation from server
    final guildId = state.currentGuild?.id;
    final newKey = res['encryption_key'] as String?;
    if (newKey != null && guildId != null) {
      await ServerService.saveGuildEncryptionKey(guildId, newKey);
      debugPrint('leaveGuild: encryption key rotated and cached in secure storage');
    }
    // Clear the guild key from secure storage when leaving
    if (guildId != null) {
      await ServerService.clearGuildEncryptionKey(guildId);
      debugPrint('leaveGuild: encryption key cleared from secure storage');
    }
    state = state.copyWith(clearCurrentGuild: true, guildMembers: [], guildMessages: [], myGuilds: []);
    ChatService.leaveCurrentRoom();
    _saveAllToHive();
    NotificationService.showFeedback("Guilde", "Vous avez quitté la guilde");
  }

  Future<void> createGuild(String name, String description, String tag, {
    GuildJoinType joinType = GuildJoinType.open,
    int minLevel = 0,
    int maxMembers = 50,
    String? logoUrl,
  }) async {
    final res = await ServerService.createGuild(
      name: name,
      description: description,
      joinType: joinType,
      minLevel: minLevel,
      maxMembers: maxMembers,
      logoUrl: logoUrl,
    );
    if (res == null) {
      NotificationService.showFeedback("Erreur", "Impossible de créer la guilde");
      return;
    }
    final errorMsg = res['error'] is Map ? res['error']['message'] : res['error'];
    if (errorMsg != null) {
      NotificationService.showFeedback("Erreur", errorMsg.toString());
      return;
    }
    await _refreshMyGuilds();
    NotificationService.showFeedback("Succès", "Guilde créée");
  }

  // ====== GUILDES - RAFRAÎCHISSEMENT ======

  Future<void> loadMyGuilds() async {
    await _refreshMyGuilds();
  }

  Future<void> loadAvailableGuilds() async {
    final availableGuilds = await ServerService.getGuilds();
    if (availableGuilds != null) {
      final guilds = availableGuilds.map((g) => Guild.fromJson(g)).toList();
      state = state.copyWith(availableGuilds: guilds);
    }
  }

  void selectGuild(String guildId) {
    final guild = state.myGuilds.where((g) => g.id == guildId).firstOrNull;
    if (guild != null) {
      state = state.copyWith(currentGuild: guild, guildMessages: []);
      _saveAllToHive();
      _refreshGuildData(guildId);
      _connectChat(guild);
    }
  }

  Future<void> _connectChat(Guild guild) async {
    try {
      debugPrint('_connectChat: START guild=${guild.name} (id=${guild.id})');
      _activeGuildId = guild.id;
      debugPrint('_connectChat: calling getGuildChatKey for guild ${guild.id}');
      var res = await ServerService.getGuildChatKey(guild.id);
      var key = res?['key'] as String?;
      
      // Retry once if key fetch failed
      if (key == null) {
        debugPrint('_connectChat: getGuildChatKey returned null, retrying once...');
        final retryRes = await ServerService.getGuildChatKey(guild.id);
        key = retryRes?['key'] as String?;
        debugPrint('_connectChat: retry getGuildChatKey result: $key');
      }
      
      // Fallback: use secure storage cached encryption key if server fetch failed
      if (key == null) {
        key = await ServerService.getGuildEncryptionKey(guild.id);
        if (key != null) {
          debugPrint('_connectChat: using secure storage cached encryption key for guild ${guild.id}');
        } else {
          debugPrint('_connectChat: WARNING - no encryption key available (server fetch failed and no secure storage cache)');
        }
      } else {
        // Successfully fetched key from server, cache it in secure storage
        await ServerService.saveGuildEncryptionKey(guild.id, key);
        debugPrint('_connectChat: encryption key cached in secure storage for guild ${guild.id}');
      }
      
      debugPrint('_connectChat: encryption key = ${key != null ? "SET (${key.length} chars)" : "NULL"}');
      debugPrint('_connectChat: calling ChatService.connect()');
      await ChatService.connect();
      debugPrint('_connectChat: ChatService.connect() returned');
      debugPrint('_connectChat: calling joinGuildRoom');
      ChatService.joinGuildRoom(guild.id, encryptionKey: key);
      debugPrint('_connectChat: joinGuildRoom returned');

      // Bind socket reception handlers once (they are static and accumulate)
      if (!_chatSocketBound) {
        debugPrint('_connectChat: _chatSocketBound=false, registering callbacks');
        _chatSocketBound = true;

        ChatService.onHistory((data) {
          debugPrint('_connectChat: onHistory callback fired, data keys: ${data.keys.toList()}');
          final list = (data['messages'] as List<dynamic>?) ?? [];
          debugPrint('_connectChat: onHistory received ${list.length} raw messages');
          final messages = list
              .whereType<Map>()
              .map((m) => _chatMessageFromSocket(Map<String, dynamic>.from(m), _activeGuildId ?? guild.id))
              .toList();
          debugPrint('_connectChat: onHistory parsed ${messages.length} ChatMessages');
          state = state.copyWith(guildMessages: messages);
          _saveAllToHive();
          debugPrint('_connectChat: onHistory state updated with ${messages.length} messages, saved to Hive');
        });

        ChatService.onMessage((data) {
          debugPrint('_connectChat: onMessage callback fired, sender=${data['sender_name']}');
          final msg = _chatMessageFromSocket(data, _activeGuildId ?? guild.id);
          if (msg.room != 'guild_$_activeGuildId') {
            debugPrint('_connectChat: onMessage room mismatch (msg.room=${msg.room}, expected=guild_$_activeGuildId), ignoring');
            return;
          }
          
          // Deduplication: if this message matches a temp message (same text & room), replace it
          // No timestamp comparison because server returns HH:mm (seconds=0) while temp has real seconds
          final messages = List<ChatMessage>.from(state.guildMessages);
          final tempIndex = messages.indexWhere((m) => 
            m.id.startsWith('temp_') && 
            m.text == msg.text &&
            m.room == msg.room
          );
          
          if (tempIndex != -1) {
            // Replace temp message with server message (which has the real ID and correct sender_name)
            messages[tempIndex] = msg;
            state = state.copyWith(guildMessages: messages);
            debugPrint('_connectChat: onMessage deduplicated temp message');
          } else {
            state = state.copyWith(guildMessages: [...messages, msg]);
            debugPrint('_connectChat: onMessage added new message, total=${messages.length + 1}');
            // Show notification if message is from another user (not self)
            if (msg.senderId != state.user.uid) {
              NotificationService.showGuildMessageNotification(
                guildName: state.currentGuild?.name ?? 'Guilde',
                senderName: msg.senderName,
                message: msg.text,
                guildId: state.currentGuild?.id ?? '',
              );
            }
          }
        });

        // Handle message deletion
        ChatService.onDeleteMessage((data) {
          debugPrint('_connectChat: onDeleteMessage callback fired');
          if (data['id'] != null && data['sender_name'] != null) {
            final deletedId = data['id'].toString();
            final senderName = data['sender_name'] as String;
            final messages = List<ChatMessage>.from(state.guildMessages);
            final index = messages.indexWhere((m) => m.id == deletedId);
            if (index != -1) {
              // Replace with "deleted by mod" message
              messages[index] = ChatMessage(
                id: messages[index].id,
                senderId: messages[index].senderId,
                senderName: '$senderName (modéré)',
                text: 'Ce message a été supprimé par un modérateur',
                timestamp: messages[index].timestamp,
                deleted: true,
              );
              state = state.copyWith(guildMessages: messages);
            }
          }
        });

        ChatService.onChatError((msg) {
          debugPrint('_connectChat: onChatError: $msg');
          NotificationService.showFeedback("Chat", msg);
        });

        // Handle decryption failure - re-fetch guild encryption key and re-join
        ChatService.onDecryptionFailure(() {
          debugPrint('_connectChat: decryption failure detected, re-fetching guild key');
          _refreshGuildEncryptionKey(guild.id);
        });
      } else {
        // Re-attach to the freshly selected guild's room
        debugPrint('_connectChat: _chatSocketBound=true, clearing guildMessages and re-attaching');
        state = state.copyWith(guildMessages: []);
      }
      debugPrint('_connectChat: END');
    } catch (e, stack) {
      debugPrint('Failed to connect chat: $e\n$stack');
    }
  }

  /// Re-fetch guild encryption key from server and update chat service
  Future<void> _refreshGuildEncryptionKey(String guildId) async {
    debugPrint('_refreshGuildEncryptionKey: START guild=$guildId');
    try {
      final res = await ServerService.getGuildChatKey(guildId);
      final key = res?['key'] as String?;
      if (key != null) {
        // Cache in secure storage
        await ServerService.saveGuildEncryptionKey(guildId, key);
        debugPrint('_refreshGuildEncryptionKey: key refreshed and cached in secure storage');
        ChatService.joinGuildRoom(guildId, encryptionKey: key);
      } else {
        debugPrint('_refreshGuildEncryptionKey: failed to fetch key from server');
      }
    } catch (e, stack) {
      debugPrint('_refreshGuildEncryptionKey: error $e\n$stack');
    }
  }

  Future<void> loadGuildMembers(String guildId) async {
    try {
      final membersData = await ServerService.getGuildMembers(guildId);
      if (membersData != null) {
        final membersJson = membersData['members'] as List<dynamic>?;
        if (membersJson != null) {
          final members = membersJson.map((m) => GuildMember.fromJson(m as Map<String, dynamic>)).toList();
          state = state.copyWith(guildMembers: members);
        }
      }
    } catch (e) {
      debugPrint('loadGuildMembers error: $e');
      NotificationService.showFeedback("Erreur", "Impossible de charger les membres");
    }
  }

  Future<void> _refreshMyGuilds() async {
    final myGuilds = await ServerService.getMyGuilds();
    if (myGuilds != null) {
      final guilds = myGuilds.map((g) => Guild.fromJson(g)).toList();
      state = state.copyWith(myGuilds: guilds);
      if (guilds.isNotEmpty) {
        // Use existing currentGuild if set, otherwise auto-select first guild
        final guild = state.currentGuild ?? guilds.first;
        if (state.currentGuild == null) {
          state = state.copyWith(currentGuild: guild);
        }
        // Always (re)connect chat when we have guilds and chat is not connected
        if (!ChatService.isConnected) {
          _connectChat(guild);
        }
      }
    }
    final availableGuilds = await ServerService.getGuilds();
    if (availableGuilds != null) {
      final guilds = availableGuilds.map((g) => Guild.fromJson(g)).toList();
      state = state.copyWith(availableGuilds: guilds);
    }
    final invitations = await ServerService.getMyInvitations();
    if (invitations != null) {
      final invs = invitations.map((i) => GuildInvitation.fromJson(i)).toList();
      state = state.copyWith(guildInvitations: invs);
    }
    _saveAllToHive();
  }

  Future<void> _refreshGuildData(String guildId) async {
    final detail = await ServerService.getGuildDetail(guildId);
    if (detail != null) {
      final guild = Guild.fromJson(detail);
      state = state.copyWith(
        currentGuild: guild,
        guildMembers: guild.members,
      );
      final updatedMyGuilds = state.myGuilds.map((g) => g.id == guildId ? guild : g).toList();
      state = state.copyWith(myGuilds: updatedMyGuilds);
      _saveAllToHive();
    }
  }

  // ====== GUILDES - GESTION MEMBRES ======

  String? _serverErrorMessage(Map<String, dynamic>? res) {
    if (res == null) return null;
    final e = res['error'];
    if (e is Map) return e['message']?.toString();
    if (e is String) return e;
    return null;
  }

  /// Affiche un retour utilisateur basé sur la réponse serveur et retourne
  /// true si l'opération a réussi (pas d'erreur), false sinon.
  Future<bool> _notifyServerResult(Map<String, dynamic>? res, String defaultError) async {
    if (res == null) {
      NotificationService.showFeedback("Erreur", defaultError);
      return false;
    }
    final err = _serverErrorMessage(res);
    if (err != null) {
      NotificationService.showFeedback("Erreur", err);
      return false;
    }
    if (res['message'] != null) NotificationService.showFeedback("Succès", res['message']);
    return true;
  }

  Future<void> kickMember(String guildId, String targetUid) async {
    final res = await ServerService.kickMember(guildId, targetUid);
    if (res != null && await _notifyServerResult(res, "Impossible d'exclure le membre")) {
      // Handle encryption key rotation from server
      final newKey = res['encryption_key'] as String?;
      if (newKey != null) {
        await ServerService.saveGuildEncryptionKey(guildId, newKey);
        // Re-join chat room with new key
        ChatService.joinGuildRoom(guildId, encryptionKey: newKey);
        debugPrint('kickMember: encryption key rotated and cached in secure storage');
      }
      await _refreshGuildData(guildId);
    }
  }

  Future<void> promoteMember(String guildId, String targetUid) async {
    final res = await ServerService.promoteMember(guildId, targetUid);
    if (res != null && await _notifyServerResult(res, "Impossible de promouvoir")) {
      // Handle encryption key rotation from server
      final newKey = res['encryption_key'] as String?;
      if (newKey != null) {
        await ServerService.saveGuildEncryptionKey(guildId, newKey);
        ChatService.joinGuildRoom(guildId, encryptionKey: newKey);
        debugPrint('promoteMember: encryption key rotated and cached in secure storage');
      }
      await _refreshGuildData(guildId);
    }
  }

  Future<void> demoteMember(String guildId, String targetUid) async {
    final res = await ServerService.demoteMember(guildId, targetUid);
    if (res != null && await _notifyServerResult(res, "Impossible de rétrograder")) {
      // Handle encryption key rotation from server
      final newKey = res['encryption_key'] as String?;
      if (newKey != null) {
        await ServerService.saveGuildEncryptionKey(guildId, newKey);
        ChatService.joinGuildRoom(guildId, encryptionKey: newKey);
        debugPrint('demoteMember: encryption key rotated and cached in secure storage');
      }
      await _refreshGuildData(guildId);
    }
  }

  Future<void> transferOwnership(String guildId, String targetUid) async {
    final res = await ServerService.transferOwnership(guildId, targetUid);
    if (res != null && await _notifyServerResult(res, "Impossible de transférer")) {
      // Handle encryption key rotation from server
      final newKey = res['encryption_key'] as String?;
      if (newKey != null) {
        await ServerService.saveGuildEncryptionKey(guildId, newKey);
        ChatService.joinGuildRoom(guildId, encryptionKey: newKey);
        debugPrint('transferOwnership: encryption key rotated and cached in secure storage');
      }
      await _refreshGuildData(guildId);
    }
  }

  Future<void> updateGuildSettings(String guildId, {
    String? name,
    String? description,
    String? logoUrl,
    GuildJoinType? joinType,
    int? minLevel,
    int? maxMembers,
  }) async {
    final res = await ServerService.updateGuild(guildId,
      name: name,
      description: description,
      logoUrl: logoUrl,
      joinType: joinType,
      minLevel: minLevel,
      maxMembers: maxMembers,
    );
    if (await _notifyServerResult(res, "Impossible de mettre à jour")) {
      await _refreshMyGuilds();
    }
  }

  // ====== INVITATIONS ======

  Future<void> inviteToGuild(String guildId, String username) async {
    final res = await ServerService.inviteToGuild(guildId, username);
    await _notifyServerResult(res, "Impossible d'inviter");
  }

  Future<void> respondToInvitation(String invitationId, bool accept) async {
    final res = await ServerService.respondToInvitation(invitationId, accept);
    if (await _notifyServerResult(res, "Impossible de répondre")) {
      await _refreshMyGuilds();
    }
  }

  Future<void> loadGuildInvitations() async {
    final invitations = await ServerService.getMyInvitations();
    if (invitations != null) {
      final invs = invitations.map((i) => GuildInvitation.fromJson(i)).toList();
      state = state.copyWith(guildInvitations: invs);
    }
  }

  // ====== QUÊTES DE GUILDE ======

  Future<void> loadGuildQuests(String guildId) async {
    final quests = await ServerService.getGuildQuests(guildId);
    if (quests != null) {
      final q = quests.map((q) => GuildQuest.fromJson(q)).toList();
      state = state.copyWith(guildQuests: q);
    }
  }

  Future<void> createGuildQuest(String guildId, {
    required String title,
    required String description,
    required int xpReward,
    required int coinReward,
  }) async {
    final res = await ServerService.createGuildQuest(guildId, title, description, xpReward, coinReward);
    if (await _notifyServerResult(res, "Impossible de créer la quête")) {
      await loadGuildQuests(guildId);
      NotificationService.showFeedback("Succès", "Quête créée");
    }
  }

  Future<void> completeGuildQuest(String guildId, String questId) async {
    final res = await ServerService.completeGuildQuest(guildId, questId);
    if (await _notifyServerResult(res, "Impossible de compléter")) {
      await loadGuildQuests(guildId);
      NotificationService.showFeedback("Succès", "Quête complétée");
    }
  }

  Future<void> deleteGuildQuest(String guildId, String questId) async {
    final res = await ServerService.deleteGuildQuest(guildId, questId);
    if (await _notifyServerResult(res, "Impossible d'annuler")) {
      await loadGuildQuests(guildId);
      NotificationService.showFeedback("Succès", "Quête annulée");
    }
  }

  // ====== LOGS ======

  Future<void> loadGuildLogs(String guildId) async {
    final logs = await ServerService.getGuildLogs(guildId);
    if (logs != null) {
      final l = logs.map((l) => GuildLog.fromJson(l)).toList();
      state = state.copyWith(guildLogs: l);
    }
  }

  // ====== LEADERBOARD GUILDES ======

  Future<void> loadGuildLeaderboard() async {
    final leaderboard = await ServerService.getGuildLeaderboard();
    if (leaderboard != null) {
      final g = leaderboard.map((g) => Guild.fromJson(g)).toList();
      state = state.copyWith(guildLeaderboard: g);
    }
  }

  // ====== LEADERBOARD MONDIAL ======

  Future<void> loadLeaderboard() async {
    // Synchronise d'abord les progrès locaux pour que le classement reflète
    // la vraie progression du joueur (le serveur n'est mis à jour que lors
    // d'une sync).
    try {
      await syncWithServer(mode: 'merge');
    } catch (_) {}
    final data = await ServerService.getLeaderboard();
    if (data != null) {
      final entries = data.map((e) => LeaderboardEntry(
        pseudo: e['username'] ?? '',
        level: e['level'] ?? 1,
        totalXp: e['xp'] ?? 0,
        streak: e['streak'] ?? 0,
      )).toList();
      state = state.copyWith(leaderboard: entries);
    }
  }

  // ====== PROFIL PUBLIC ======

  Future<void> loadUserProfile(String uid) async {
    final profile = await ServerService.getUserProfile(uid);
    if (profile != null) {
      // Could store in state or return directly
    }
  }

  // ====== CHAT GUILDE ======

  Future<String?> getGuildChatKey(String guildId) async {
    final res = await ServerService.getGuildChatKey(guildId);
    if (res != null && res['key'] != null) {
      return res['key'] as String;
    }
    return null;
  }

  Future<void> addChatMessage(String senderId, String text) async {
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderId,
      text: text,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      guildMessages: [...state.guildMessages, msg],
    );
  }

  Future<void> sendGuildMessage(String text) async {
    if (state.currentGuild == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final guildId = state.currentGuild!.id;
    final room = 'guild_$guildId';

    // Optimistic insertion: add message immediately with temp ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final user = state.user;
    final tempMsg = ChatMessage(
      id: tempId,
      senderName: user.pseudo,
      senderId: user.uid,
      text: trimmed,
      timestamp: DateTime.now(),
      room: room,
    );

    state = state.copyWith(guildMessages: [...state.guildMessages, tempMsg]);

    // Send with retry logic (max 2 attempts: initial + 1 retry with key refresh)
    const maxAttempts = 2;
    bool success = false;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      success = ChatService.sendMessage(trimmed);
      if (success) break;
      
      if (attempt < maxAttempts) {
        debugPrint('sendGuildMessage: attempt $attempt failed, refreshing key and retrying...');
        // Re-fetch encryption key and re-join room
        await _refreshGuildEncryptionKey(guildId);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (!success) {
      // Remove temp message on failure and show error
      state = state.copyWith(
        guildMessages: state.guildMessages.where((m) => m.id != tempId).toList(),
      );
      debugPrint('sendGuildMessage: failed after $maxAttempts attempts, temp message removed');
      NotificationService.showFeedback('Chat', 'Échec envoi message (réseau)');
    }
  }

  // ====== WEEKLY XP LOG ======

  List<int> getWeeklyXpLog() => List.from(state.weeklyXpLog);

  int get totalWeeklyXp => state.weeklyXpLog.fold(0, (a, b) => a + b);

  void _addWeeklyXp(int amount) {
    if (amount <= 0) return;
    final now = DateTime.now();
    final thisMonday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final lastWeekStart = state.lastWeeklyLogWeekStart;

    bool newWeek = lastWeekStart == null || !isSameDay(lastWeekStart, thisMonday);
    if (newWeek) {
      state = state.copyWith(weeklyXpLog: List.filled(7, 0), lastWeeklyLogWeekStart: thisMonday);
    }

    final idx = now.weekday - 1; // Monday=0 … Sunday=6
    var log = List<int>.from(state.weeklyXpLog);
    if (log.length != 7) log = List.filled(7, 0);
    log[idx] += amount;
    state = state.copyWith(weeklyXpLog: log);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

enum ServerStatus {
  unknown,
  connected,
  warning,
  disconnected,
}

class ServerStatusNotifier extends Notifier<ServerStatus> {
  Timer? _timer;

  @override
  ServerStatus build() {
    _startPeriodicCheck();
    // Initial check
    _checkServer();
    return ServerStatus.unknown;
  }

  void _startPeriodicCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkServer());
  }

  Future<void> _checkServer() async {
    try {
      final res = await ServerService.healthCheck();
      if (!ref.mounted) return;
      if (res != null) {
        final status = res['status'] as String?;
        if (status == 'ok' || status == 'registered' || status == 'existing' || status == 'created') {
          state = ServerStatus.connected;
        } else {
          state = ServerStatus.warning;
        }
      } else {
        state = ServerStatus.disconnected;
      }
    } catch (e) {
      if (ref.mounted) state = ServerStatus.disconnected;
    }
  }
}

final serverStatusProvider = NotifierProvider<ServerStatusNotifier, ServerStatus>(ServerStatusNotifier.new);
