import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/add_quest_dialog.dart';
import '../../models/game_models.dart';
import '../../core/translations.dart';
import '../../providers/game_provider.dart';
import '../../services/update_service.dart';
import '../../services/notification_service.dart';
import 'home_screen.dart';
import 'quests_screen.dart';
import 'calendar_screen.dart';
import 'skills_screen.dart';
import 'bets_screen.dart';
import 'others_screen.dart';
import 'shop_screen.dart';
import 'weekly_summary_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  static const platform = MethodChannel('com.arcom.life_rpg/widget');
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _setupWidgetListener();
    _checkInitialAction();
    _onAppReady();
  }

  void _onAppReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).checkDailyPenalties();
      NotificationService.scheduleDailyProactiveReminder();
      NotificationService.scheduleEveningEntryReminder();
      ref.read(gameProvider.notifier).syncWithServer();
      if (context.mounted) {
        UpdateService.checkForUpdate(context);
      }
    });
  }

  void _setupWidgetListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == "triggerAction") {
        final action = call.arguments as String? ?? '';
        if (action == "com.arcom.life_rpg.ADD_QUEST") {
          _handleQuickAdd(null);
        } else if (action.startsWith("com.arcom.life_rpg.QUICK_ADD_")) {
          final diff = action.split("QUICK_ADD_").last;
          final difficulty = Difficulty.values.firstWhere(
            (d) => d.name.toUpperCase() == diff,
            orElse: () => Difficulty.easy,
          );
          _handleQuickAdd(difficulty);
        } else if (action.startsWith("TOGGLE_QUEST:")) {
          final questId = action.split("TOGGLE_QUEST:").last;
          if (questId.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(gameProvider.notifier).toggleQuestStatus(questId);
            });
          }
        }
      }
    });
  }

  Future<void> _checkInitialAction() async {
    try {
      final String? action = await platform.invokeMethod('getInitialAction');
      if (action == "com.arcom.life_rpg.ADD_QUEST") {
        _handleQuickAdd(null);
      } else if (action != null && action.startsWith("com.arcom.life_rpg.QUICK_ADD_")) {
        final diff = action.split("QUICK_ADD_").last;
        final difficulty = Difficulty.values.firstWhere(
          (d) => d.name.toUpperCase() == diff,
          orElse: () => Difficulty.easy,
        );
        _handleQuickAdd(difficulty);
      }
    } on PlatformException catch (e) {
      debugPrint("Erreur lors de la récupération de l'action initiale: ${e.message}");
    }
  }

  void _handleQuickAdd(Difficulty? difficulty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showAddQuestDialog(context, ref, initialDifficulty: difficulty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    final coins = ref.watch(gameProvider.select((s) => s.user.coins));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life RPG'),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklySummaryScreen())),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.bar_chart),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 2),
                  Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: const [
        HomeScreen(),
        QuestsScreen(),
        CalendarScreen(),
        SkillsScreen(),
        BetsScreen(),
        OthersScreen(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: t.profile),
          BottomNavigationBarItem(icon: const Icon(Icons.assignment), label: t.quests),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_month), label: t.calendar),
          BottomNavigationBarItem(icon: const Icon(Icons.trending_up), label: t.skills),
          BottomNavigationBarItem(icon: const Icon(Icons.casino), label: t.bets),
          BottomNavigationBarItem(icon: const Icon(Icons.more_horiz), label: t.others),
        ],
      ),
    );
  }
}
