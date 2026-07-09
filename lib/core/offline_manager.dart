import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineManager {
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('game_data')) {
      await Hive.openBox('game_data');
    }
  }

  static Future<void> saveData(String key, dynamic value) async {
    try {
      final box = Hive.box('game_data');
      final jsonString = jsonEncode(value);
      await box.put(key, jsonString);
      await box.flush();
    } catch (e) {
      debugPrint("Erreur sauvegarde Hive ($key): $e");
    }
  }

  static Future<void> flush() async {
    final box = Hive.box('game_data');
    await box.flush();
  }

  static dynamic getData(String key) {
    if (!Hive.isBoxOpen('game_data')) return null;
    final box = Hive.box('game_data');
    final data = box.get(key);
    if (data == null) return null;
    
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (e) {
        return null;
      }
    }
    return data; 
  }

  static Future<bool> isConnected() async {
    final results = await (Connectivity().checkConnectivity());
    return results.any((r) => r != ConnectivityResult.none);
  }
}
