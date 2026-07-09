import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class Translations {
  final Map<String, String> _data;

  Translations(this._data);

  String get(String key) => _data[key] ?? key;

  // Profil
  String get profile => get('profile');
  String get level => get('level');
  String get streak => get('streak');
  String get globalXp => get('globalXp');
  
  // Navigation
  String get quests => get('quests');
  String get calendar => get('calendar');
  String get skills => get('skills');
  String get bets => get('bets');
  String get others => get('others');

  // Quests
  String get newQuest => get('newQuest');
  String get editQuest => get('editQuest');
  String get title => get('title');
  String get description => get('description');
  String get difficulty => get('difficulty');
  String get frequency => get('frequency');
  String get planningReminder => get('planningReminder');
  String get start => get('start');
  String get deadlineEnd => get('deadlineEnd');
  String get reminder => get('reminder');
  String get skill => get('skill');
  String get cancel => get('cancel');
  String get create => get('create');
  String get modify => get('modify');
  String get save => get('save');
  String get none => get('none');
  String get notDefined => get('notDefined');
  String get questJournal => get('questJournal');
  String get all => get('all');
  String get daily => get('daily');
  String get noQuestsInCategory => get('noQuestsInCategory');
  String get noDescription => get('noDescription');
  String get delete => get('delete');
  String get close => get('close');
  
  // Others
  String get focusMode => get('focusMode');
  String get focusModeDesc => get('focusModeDesc');
  String get backup => get('backup');
  String get backupDesc => get('backupDesc');
  String get settings => get('settings');
  String get settingsDesc => get('settingsDesc');
  String get export => get('export');
  String get import => get('import');
  
  // Settings
  String get appearance => get('appearance');
  String get theme => get('theme');
  String get language => get('language');
  String get system => get('system');
  String get light => get('light');
  String get dark => get('dark');
  String get chooseTheme => get('chooseTheme');
  String get chooseLanguage => get('chooseLanguage');

  // Calendar
  String get calendarPlanning => get('calendarPlanning');
  String get noEvents => get('noEvents');
  String get allDay => get('allDay');
  String get betLabel => get('betLabel');

  // Home
  String get heroProfile => get('heroProfile');
  String get changePseudo => get('changePseudo');
  String get newPseudo => get('newPseudo');
  String get myExpertBadges => get('myExpertBadges');
  String get noBadges => get('noBadges');
  String get progressionNextLevel => get('progressionNextLevel');
  String get levelPrefix => get('levelPrefix');

  // Categories (using labels as keys if they match exactly, or IDs)
  String translateCategory(String label) {
    final key = 'cat_$label';
    return _data[key] ?? label;
  }

  // Badges
  String translateBadgeTitle(String id) => get('badge_title_$id');
  String translateBadgeDesc(String id) => get('badge_desc_$id');

  // User Titles
  String translateUserTitle(String title) => get('title_$title');

  // Shop
  String get shop => get('shop');
  String get buy => get('buy');
  String get notEnoughCoins => get('notEnoughCoins');
  String get streakFreezeLabel => get('streakFreezeLabel');
  String get dailyReward => get('dailyReward');
  String get weeklySummary => get('weeklySummary');
  String get coinsLabel => get('coinsLabel');
  String get lootBox => get('lootBox');
  String get soundVolume => get('soundVolume');
  String get hapticLevel => get('hapticLevel');
  String get dayLabel => get('dayLabel');
  String get skins => get('skins');
  String get equipped => get('equipped');
  String get equip => get('equip');
  String get levelRequired => get('levelRequired');
  String get multiplier => get('multiplier');
  String get milestones => get('milestones');
  String get streakMilestones => get('streakMilestones');
  String get days => get('days');
  String get daysLeft => get('daysLeft');
  String get reward => get('reward');
  String get rewardClaimed => get('rewardClaimed');
  String get eveningEntryTitle => get('eveningEntryTitle');
  String get eveningEntrySubtitle => get('eveningEntrySubtitle');
  String get eveningSubmit => get('eveningSubmit');
  String get eveningDone => get('eveningDone');
  String get eveningAlreadyDone => get('eveningAlreadyDone');
  String get howAreYou => get('howAreYou');
  String get whatYouDid => get('whatYouDid');
  String get eveningHint => get('eveningHint');
  String get eveningHistoryTitle => get('eveningHistoryTitle');
  String get eveningHistoryEmpty => get('eveningHistoryEmpty');
  String get customize => get('customize');
  String get skinCategory => get('skinCategory');
  String get hairCategory => get('hairCategory');
  String get eyesCategory => get('eyesCategory');
  String get browCategory => get('browCategory');
  String get mouthCategory => get('mouthCategory');
  String get outfitCategory => get('outfitCategory');
  String get hatCategory => get('hatCategory');
  String get accCategory => get('accCategory');
}

final Map<String, Map<String, String>> _translationsData = {
  'fr': {
    'profile': 'Profil',
    'level': 'Niveau',
    'streak': 'Série',
    'globalXp': 'XP Globale',
    'quests': 'Quêtes',
    'calendar': 'Calendrier',
    'skills': 'Compétences',
    'bets': 'Paris',
    'others': 'Autre',
    'newQuest': 'Nouvelle Quête',
    'editQuest': 'Modifier Quête',
    'title': 'Titre',
    'description': 'Description',
    'difficulty': 'Difficulté',
    'frequency': 'Fréquence',
    'planningReminder': 'Planification & Rappel',
    'start': 'Début',
    'deadlineEnd': 'Échéance / Fin',
    'reminder': 'Rappel',
    'skill': 'Compétence',
    'cancel': 'Annuler',
    'create': 'Créer',
    'modify': 'Modifier',
    'save': 'Enregistrer',
    'none': 'Aucun',
    'notDefined': 'Non défini',
    'questJournal': 'JOURNAL DES QUÊTES',
    'all': 'TOUT',
    'daily': 'QUOTIDIEN',
    'noQuestsInCategory': 'Aucune quête dans cette catégorie',
    'noDescription': 'Aucune description.',
    'delete': 'Supprimer',
    'close': 'Fermer',
    'focusMode': 'MODE CONCENTRATION',
    'focusModeDesc': 'Gagnez de l\'XP en restant loin de votre écran.',
    'backup': 'SAUVEGARDE',
    'backupDesc': 'Importez ou exportez vos données de jeu.',
    'settings': 'RÉGLAGES',
    'settingsDesc': 'Configuration de l\'application (Thème, Langue)',
    'export': 'Exporter',
    'import': 'Importer',
    'appearance': 'APPARENCE',
    'theme': 'Thème',
    'language': 'Langue de l\'application',
    'system': 'Système',
    'light': 'Clair',
    'dark': 'Sombre',
    'chooseTheme': 'Choisir le thème',
    'chooseLanguage': 'Choisir la langue',
    'calendarPlanning': 'CALENDRIER & PLANNING',
    'noEvents': 'Aucun événement pour ce jour',
    'allDay': 'Toute la journée',
    'betLabel': 'PARI',
    'heroProfile': 'PROFIL DU HÉROS',
    'changePseudo': 'Changer de Pseudo',
    'newPseudo': 'Nouveau Pseudo',
    'myExpertBadges': 'MES BADGES D\'EXPERT',
    'noBadges': 'Aucun badge débloqué pour le moment.',
    'progressionNextLevel': 'Progression vers le niveau suivant',
    'levelPrefix': 'Niveau',
    // Categories
    'cat_Physique': 'Physique',
    'cat_Mental': 'Mental',
    'cat_Discipline': 'Discipline',
    'cat_Social': 'Social',
    'cat_Créativité': 'Créativité',
    // Titles
    'title_Novice': 'Novice',
    'title_Apprenti': 'Apprenti',
    'title_Éclaireur': 'Éclaireur',
    'title_Guerrier d\'Élite': 'Guerrier d\'Élite',
    'title_Grand Aventurier': 'Grand Aventurier',
    'title_Paladin de l\'Ordre': 'Paladin de l\'Ordre',
    'title_Seigneur de Discipline': 'Seigneur de Discipline',
    'title_Maître de l\'Existence': 'Maître de l\'Existence',
    'title_Légende Immortelle': 'Légende Immortelle',
    // Badges
    'badge_title_xp_1000': 'Apprenti motivé',
    'badge_desc_xp_1000': 'Atteindre 1000 XP globale',
    'badge_title_quest_10': 'Persévérant',
    'badge_desc_quest_10': 'Terminer 10 quêtes',
    'badge_title_streak_3': 'Régulier',
    'badge_desc_streak_3': 'Maintenir une série de 3 jours',
    'badge_title_level_10': 'Vétéran',
    'badge_desc_level_10': 'Atteindre le niveau 10',
    'badge_title_focus_5': 'Moine Novice',
    'badge_desc_focus_5': 'Rester concentré 5 min',
    'badge_title_focus_10': 'Esprit Calme',
    'badge_desc_focus_10': 'Rester concentré 10 min',
    'badge_title_focus_20': 'Maître Zen',
    'badge_desc_focus_20': 'Rester concentré 20 min',
    'badge_title_focus_60': 'Concentration Absolue',
    'badge_desc_focus_60': 'Rester concentré 1 heure',
    'badge_title_coins_500': 'Économiseur',
    'badge_desc_coins_500': 'Amasser 500 pièces',
    'shop': 'BOUTIQUE',
    'buy': 'Acheter',
    'notEnoughCoins': 'Pas assez de pièces !',
    'streakFreezeLabel': 'Gel de série',
    'dailyReward': 'Récompense quotidienne',
    'weeklySummary': 'Résumé hebdomadaire',
    'coinsLabel': 'Pièces',
    'lootBox': 'Coffre',
    'soundEnabled': 'Audio',
    'dayLabel': 'Jour',
    'skins': 'Skins',
    'equipped': 'Équipé',
    'equip': 'Équiper',
    'levelRequired': 'Niveau',
    'soundVolume': 'Volume sonore',
    'hapticLevel': 'Retour haptique',
    'multiplier': 'Multiplicateur',
    'milestones': 'Palier',
    'streakMilestones': 'Paliers de série',
    'days': 'jours',
    'daysLeft': 'j restants',
    'reward': 'Récompense',
    'rewardClaimed': 'Récompensé',
    'eveningEntryTitle': 'Bilan du soir',
    'eveningEntrySubtitle': 'Notez votre journée et gagnez 10 pièces',
    'eveningSubmit': 'Envoyer',
    'eveningDone': 'Fait ✓',
    'eveningAlreadyDone': 'Bilan du soir déjà envoyé aujourd\'hui !',
    'howAreYou': 'Comment te sens-tu ?',
    'whatYouDid': 'Qu\'as-tu fait aujourd\'hui ?',
    'eveningHint': 'Raconte ta journée…',
    'eveningHistoryTitle': 'Historique du soir',
    'eveningHistoryEmpty': 'Aucune entrée pour l\'instant',
    'customize': 'Personnaliser',
    'skinCategory': 'Peau',
    'hairCategory': 'Cheveux',
    'eyesCategory': 'Yeux',
    'browCategory': 'Sourcils',
    'mouthCategory': 'Bouche',
    'outfitCategory': 'Tenue',
    'hatCategory': 'Chapeau',
    'accCategory': 'Accessoire',
  },
  'en': {
    'profile': 'Profile',
    'level': 'Level',
    'streak': 'Streak',
    'globalXp': 'Global XP',
    'quests': 'Quests',
    'calendar': 'Calendar',
    'skills': 'Skills',
    'bets': 'Bets',
    'others': 'Other',
    'newQuest': 'New Quest',
    'editQuest': 'Edit Quest',
    'title': 'Title',
    'description': 'Description',
    'difficulty': 'Difficulty',
    'frequency': 'Frequency',
    'planningReminder': 'Planning & Reminder',
    'start': 'Start',
    'deadlineEnd': 'Deadline / End',
    'reminder': 'Reminder',
    'skill': 'Skill',
    'cancel': 'Cancel',
    'create': 'Create',
    'modify': 'Modify',
    'save': 'Save',
    'none': 'None',
    'notDefined': 'Not defined',
    'questJournal': 'QUEST LOG',
    'all': 'ALL',
    'daily': 'DAILY',
    'noQuestsInCategory': 'No quests in this category',
    'noDescription': 'No description.',
    'delete': 'Delete',
    'close': 'Close',
    'focusMode': 'FOCUS MODE',
    'focusModeDesc': 'Gain XP by staying away from your screen.',
    'backup': 'BACKUP',
    'backupDesc': 'Import or export your game data.',
    'settings': 'SETTINGS',
    'settingsDesc': 'App configuration (Theme, Language)',
    'export': 'Export',
    'import': 'Import',
    'appearance': 'APPEARANCE',
    'theme': 'Theme',
    'language': 'App Language',
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
    'chooseTheme': 'Choose theme',
    'chooseLanguage': 'Choose language',
    'calendarPlanning': 'CALENDAR & PLANNING',
    'noEvents': 'No events for this day',
    'allDay': 'All day',
    'betLabel': 'BET',
    'heroProfile': 'HERO PROFILE',
    'changePseudo': 'Change Pseudo',
    'newPseudo': 'New Pseudo',
    'myExpertBadges': 'MY EXPERT BADGES',
    'noBadges': 'No badges unlocked yet.',
    'progressionNextLevel': 'Progress to next level',
    'levelPrefix': 'Level',
    // Categories
    'cat_Physique': 'Physical',
    'cat_Mental': 'Mental',
    'cat_Discipline': 'Discipline',
    'cat_Social': 'Social',
    'cat_Créativité': 'Creativity',
    // Titles
    'title_Novice': 'Novice',
    'title_Apprenti': 'Apprentice',
    'title_Éclaireur': 'Scout',
    'title_Guerrier d\'Élite': 'Elite Warrior',
    'title_Grand Aventurier': 'Great Adventurer',
    'title_Paladin de l\'Ordre': 'Paladin of Order',
    'title_Seigneur de Discipline': 'Lord of Discipline',
    'title_Maître de l\'Existence': 'Master of Existence',
    'title_Légende Immortelle': 'Immortal Legend',
    // Badges
    'badge_title_xp_1000': 'Motivated Apprentice',
    'badge_desc_xp_1000': 'Reach 1000 global XP',
    'badge_title_quest_10': 'Persistent',
    'badge_desc_quest_10': 'Complete 10 quests',
    'badge_title_streak_3': 'Regular',
    'badge_desc_streak_3': 'Maintain a 3-day streak',
    'badge_title_level_10': 'Veteran',
    'badge_desc_level_10': 'Reach level 10',
    'badge_title_focus_5': 'Novice Monk',
    'badge_desc_focus_5': 'Stay focused for 5 min',
    'badge_title_focus_10': 'Calm Mind',
    'badge_desc_focus_10': 'Stay focused for 10 min',
    'badge_title_focus_20': 'Zen Master',
    'badge_desc_focus_20': 'Stay focused for 20 min',
    'badge_title_focus_60': 'Absolute Concentration',
    'badge_desc_focus_60': 'Stay focused for 1 hour',
    'badge_title_coins_500': 'Saver',
    'badge_desc_coins_500': 'Amass 500 coins',
    'shop': 'SHOP',
    'buy': 'Buy',
    'notEnoughCoins': 'Not enough coins!',
    'streakFreezeLabel': 'Streak Freeze',
    'dailyReward': 'Daily Reward',
    'weeklySummary': 'Weekly Summary',
    'coinsLabel': 'Coins',
    'lootBox': 'Chest',
    'soundEnabled': 'Audio',
    'dayLabel': 'Day',
    'skins': 'Skins',
    'equipped': 'Equipped',
    'equip': 'Equip',
    'levelRequired': 'Level',
    'soundVolume': 'Sound volume',
    'hapticLevel': 'Haptic feedback',
    'multiplier': 'Multiplier',
    'milestones': 'Milestone',
    'streakMilestones': 'Streak Milestones',
    'days': 'days',
    'daysLeft': 'd left',
    'reward': 'Reward',
    'rewardClaimed': 'Claimed',
    'eveningEntryTitle': 'Evening Log',
    'eveningEntrySubtitle': 'Log your day and earn 10 coins',
    'eveningSubmit': 'Submit',
    'eveningDone': 'Done ✓',
    'eveningAlreadyDone': 'Evening log already submitted today!',
    'howAreYou': 'How do you feel?',
    'whatYouDid': 'What did you do today?',
    'eveningHint': 'Tell me about your day…',
    'eveningHistoryTitle': 'Evening History',
    'eveningHistoryEmpty': 'No entries yet',
    'customize': 'Customize',
    'skinCategory': 'Skin',
    'hairCategory': 'Hair',
    'eyesCategory': 'Eyes',
    'browCategory': 'Brows',
    'mouthCategory': 'Mouth',
    'outfitCategory': 'Outfit',
    'hatCategory': 'Hat',
    'accCategory': 'Accessory',
  }
};

final translationsProvider = Provider<Translations>((ref) {
  final locale = ref.watch(settingsProvider).locale;
  return Translations(_translationsData[locale.languageCode] ?? _translationsData['en']!);
});
