import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

class WidgetService {
  static const _channel = MethodChannel('com.example.life_rpg/widget');

  static Future<void> updateWidget({
    required int level,
    required int streak,
    required int coins,
  }) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('updateWidget', {
        'level': 'Lv. $level',
        'streak': '${streak}j',
        'coins': '$coins💰',
      });
    } catch (e) {
      debugPrint('Widget update error: $e');
    }
  }

  static Future<void> updateProgressWidget({
    required int level,
    required int xp,
    required int xpForCurrent,
    required int xpForNext,
    required int streak,
    required int coins,
    required String title,
  }) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('updateProgressWidget', {
        'level': level.toString(),
        'xp': xp.toString(),
        'xpForCurrent': xpForCurrent.toString(),
        'xpForNext': xpForNext.toString(),
        'streak': streak.toString(),
        'coins': coins.toString(),
        'title': title,
      });
    } catch (e) {
      debugPrint('Progress widget update error: $e');
    }
  }

  static Future<void> updateDailyQuestsWidget(List<Quest> quests) async {
    if (kIsWeb) return;
    try {
      final questsJson = jsonEncode(quests.map((q) => {
        'id': q.id,
        'title': q.title,
        'status': q.status.name,
        'difficulty': q.difficulty.name,
        'categoryIcon': q.category.iconName,
      }).toList());
      await _channel.invokeMethod('updateDailyQuestsWidget', {
        'quests': questsJson,
      });
    } catch (e) {
      debugPrint('Daily quests widget update error: $e');
    }
  }

  static Future<void> updateCalendarWidget({
    required int year,
    required int month,
    required int todayDay,
    required List<Quest> quests,
  }) async {
    if (kIsWeb) return;
    try {
      final questsJson = jsonEncode(quests.map((q) => {
        'id': q.id,
        'title': q.title,
        'status': q.status.name,
        'difficulty': q.difficulty.name,
        'categoryIcon': q.category.iconName,
      }).toList());
      await _channel.invokeMethod('updateCalendarWidget', {
        'year': year.toString(),
        'month': month.toString(),
        'todayDay': todayDay.toString(),
        'quests': questsJson,
      });
    } catch (e) {
      debugPrint('Calendar widget update error: $e');
    }
  }
}
