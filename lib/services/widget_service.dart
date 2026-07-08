import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
}
