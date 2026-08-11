import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

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
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }
    try {
      await Vibration.cancel();
      switch (level) {
        case 1:
          await Vibration.vibrate(duration: 60);
          break;
        case 2:
          await Vibration.vibrate(duration: 150);
          break;
        case 3:
          await Vibration.vibrate(pattern: [0, 250, 100, 250]);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }
}
