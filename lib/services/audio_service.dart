import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSuccess({double volume = 0.7, int hapticLevel = 2}) async {
    if (kIsWeb) return;
    try {
      if (volume > 0) {
        await _player.stop();
        await _player.play(AssetSource('sounds/success.mp3'), volume: volume);
      }
      if (hapticLevel > 0) {
        await _hapticFeedback(hapticLevel);
      }
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  static Future<void> playLevelUp({double volume = 0.7, int hapticLevel = 2}) async {
    if (kIsWeb) return;
    try {
      if (volume > 0) {
        await _player.stop();
        await _player.play(AssetSource('sounds/levelup.mp3'), volume: volume);
      }
      if (hapticLevel > 0) {
        await _hapticFeedback(hapticLevel);
      }
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  static Future<void> _hapticFeedback(int level) async {
    switch (level) {
      case 1:
        await HapticFeedback.lightImpact();
      case 2:
        await HapticFeedback.mediumImpact();
      case 3:
        await HapticFeedback.heavyImpact();
    }
  }
}
