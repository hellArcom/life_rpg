import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import '../core/offline_manager.dart';

/// Client HTTP silencieux vers le serveur Life RPG.
///
/// Toute erreur (hors-ligne, timeout, code != 2xx) renvoie `null` sans lever
/// d'exception : l'app ne doit JAMAIS afficher de message quand le serveur est
/// injoignable.
class ServerService {
  ServerService._();

  static const String baseUrl = 'https://arcom.cel20.online';
  static const Duration _timeout = Duration(seconds: 8);

  static String? _deviceId;
  static bool? _registered;

  /// Identifiant unique d'installation (32 hex). Créé une fois, persisté.
  static Future<String> ensureDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final saved = OfflineManager.getData('device_id');
    if (saved is String && saved.isNotEmpty) {
      _deviceId = saved;
    } else {
      final rnd = Random.secure();
      _deviceId = List.generate(32, (_) => rnd.nextInt(16).toRadixString(16)).join();
      await OfflineManager.saveData('device_id', _deviceId!);
    }
    return _deviceId!;
  }

  static Future<bool> isRegistered() async {
    _registered ??= OfflineManager.getData('server_registered') == true;
    return _registered!;
  }

  static Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ServerService POST $path : $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl$path')).timeout(_timeout);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ServerService GET $path : $e');
    }
    return null;
  }

  /// Enregistre l'installation (idempotent côté serveur).
  static Future<Map<String, dynamic>?> register(String referralCode) async {
    final body = <String, dynamic>{
      'device_id': await ensureDeviceId(),
      'platform': _platform(),
      'app_version': await _appVersion(),
      if (referralCode.isNotEmpty) 'referral_code': referralCode,
    };
    final res = await _post('/api/v1/register', body);
    if (res != null) {
      _registered = true;
      await OfflineManager.saveData('server_registered', true);
    }
    return res;
  }

  /// Signal de lancement : active le comptage utilisateurs + reçoit les
  /// récompenses de parrainage en attente.
  static Future<Map<String, dynamic>?> ping() async {
    return _post('/api/v1/ping', <String, dynamic>{
      'device_id': await ensureDeviceId(),
      'app_version': await _appVersion(),
      'platform': _platform(),
    });
  }

  /// Soumet le code de parrainage saisi par l'utilisateur.
  static Future<Map<String, dynamic>?> submitReferral(String code) async {
    return _post('/api/v1/referral/submit', <String, dynamic>{
      'device_id': await ensureDeviceId(),
      'code': code,
    });
  }

  /// Récupère les infos de mise à jour depuis le serveur.
  static Future<Map<String, dynamic>?> fetchUpdate() => _get('/api/v1/update');

  static String _platform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.macOS:
        return 'macos';
      default:
        return kIsWeb ? 'web' : 'unknown';
    }
  }

  static Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '0.0.0';
    }
  }
}