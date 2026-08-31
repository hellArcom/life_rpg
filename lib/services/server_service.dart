import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/key_derivators/api.dart' as pc_kd_api;
import 'package:pointycastle/key_derivators/pbkdf2.dart' as pc_pbkdf2;
import 'package:pointycastle/digests/sha256.dart' as pc_digest;
import 'package:pointycastle/macs/hmac.dart' as pc_hmac;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/offline_manager.dart';
import '../models/game_models.dart';

/// Client HTTP silencieux vers le serveur Life RPG.
///
/// Toute erreur (hors-ligne, timeout, code != 2xx) renvoie `null` sans lever
/// d'exception : l'app ne doit JAMAIS afficher de message quand le serveur est
/// injoignable.
class ServerService {
  ServerService._();

  /// En debug : serveur local joignable via `adb reverse tcp:5000 tcp:5000`.
  /// En release : serveur de production (surchargeable via --dart-define=SERVER_URL=...).
  static const String _prodUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://arcom.cel20.online',
  );
  static const String _devUrl = 'http://127.0.0.1:5000';
  static String get baseUrl => kDebugMode ? _devUrl : _prodUrl;
  static const Duration _timeout = Duration(seconds: 8);

  static String? _deviceId;
  static bool? _registered;
  static const _secureStorage = FlutterSecureStorage();
  static const _passwordKey = 'user_password';
  static const _guildKeysPrefix = 'guild_key_';

  /// HTTP client used for all requests. Overridable in tests (e.g. with a
  /// MockClient) so the network layer can be verified without a live server.
  static http.Client httpClient = http.Client();

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

  /// Dérive une clé AES-256 à partir du mot de passe utilisateur via PBKDF2-SHA256.
  /// Le sel est généré aléatoirement côté serveur (600k itérations OWASP 2024).
  static Uint8List _deriveKey(String password, String salt) {
    final derivator = pc_pbkdf2.PBKDF2KeyDerivator(pc_hmac.HMac(pc_digest.SHA256Digest(), 64))
      ..init(pc_kd_api.Pbkdf2Parameters(Uint8List.fromList(salt.codeUnits), 600000, 32));
    return derivator.process(Uint8List.fromList(password.codeUnits));
  }

  /// Chiffre les données de sync avec la clé dérivée du mot de passe.
  /// Retourne un Map avec les données chiffrées (base64), l'IV (base64) et le sel (base64).
  static Map<String, String> _encryptSyncData(Map<String, dynamic> data, String password, {String? salt}) {
    final saltBytes = salt != null ? base64Decode(salt) : _generateRandomSalt();
    final finalSalt = base64Encode(saltBytes);
    final keyBytes = _deriveKey(password, finalSalt);
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    // Include AAD in plaintext for integrity (device_id + timestamp)
    final deviceId = _deviceId ?? 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final plaintext = jsonEncode({
      'data': data,
      'aad': 'user:$deviceId:ts:$timestamp',
    });
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return {
      'data': base64Encode(encrypted.bytes),
      'iv': base64Encode(iv.bytes),
      'salt': finalSalt,
    };
  }

  /// Déchiffre les données de sync avec la clé dérivée du mot de passe.
  static Map<String, dynamic>? _decryptSyncData(Map<String, dynamic> encData, String password) {
    try {
      final salt = encData['salt'] as String? ?? '';
      final keyBytes = _deriveKey(password, salt);
      final key = encrypt.Key(keyBytes);
      final iv = encrypt.IV(base64Decode(encData['iv'] as String));
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final decrypted = encrypter.decrypt(encrypt.Encrypted(base64Decode(encData['data'] as String)), iv: iv);
      final decoded = jsonDecode(decrypted) as Map<String, dynamic>;
      // Verify AAD
      final aad = decoded['aad'] as String?;
      final deviceId = _deviceId ?? 'unknown';
      if (aad != null && !aad.startsWith('user:$deviceId:ts:')) {
        debugPrint('ServerService: _decryptSyncData AAD mismatch');
        return null;
      }
      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ServerService: _decryptSyncData failed: $e');
      return null;
    }
  }

  static Uint8List _generateRandomSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  static Future<bool> isRegistered() async {
    _registered ??= OfflineManager.getData('server_registered') == true;
    return _registered!;
  }

  /// Sauvegarde le mot de passe utilisateur dans le stockage sécurisé.
  /// Appelé après linkAccount/registerAccount réussis.
  static Future<void> saveUserPassword(String password) async {
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  /// Récupère le mot de passe utilisateur depuis le stockage sécurisé.
  /// Retourne null si pas de mot de passe stocké.
  static Future<String?> getUserPassword() async {
    return await _secureStorage.read(key: _passwordKey);
  }

  /// Efface le mot de passe utilisateur (appelé au unlink).
  static Future<void> clearUserPassword() async {
    await _secureStorage.delete(key: _passwordKey);
  }

  /// Sauvegarde la clé de chiffrement d'une guilde dans le stockage sécurisé.
  static Future<void> saveGuildEncryptionKey(String guildId, String key) async {
    await _secureStorage.write(key: '$_guildKeysPrefix$guildId', value: key);
  }

  /// Récupère la clé de chiffrement d'une guilde depuis le stockage sécurisé.
  static Future<String?> getGuildEncryptionKey(String guildId) async {
    return await _secureStorage.read(key: '$_guildKeysPrefix$guildId');
  }

  /// Efface la clé de chiffrement d'une guilde (appelé au leave/kick).
  static Future<void> clearGuildEncryptionKey(String guildId) async {
    await _secureStorage.delete(key: '$_guildKeysPrefix$guildId');
  }

  static Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      final deviceId = await ensureDeviceId();
      final resp = await httpClient
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'X-Device-ID': deviceId,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      debugPrint('ServerService POST $path ${resp.statusCode}: ${resp.body}');
      return null;
    } catch (e) {
      debugPrint('ServerService POST $path : $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final deviceId = await ensureDeviceId();
      final resp = await httpClient.get(
        Uri.parse('$baseUrl$path'),
        headers: {'X-Device-ID': deviceId},
      ).timeout(_timeout);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      debugPrint('ServerService GET $path ${resp.statusCode}: ${resp.body}');
    } catch (e) {
      debugPrint('ServerService GET $path : $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _delete(String path) async {
    try {
      final deviceId = await ensureDeviceId();
      final resp = await httpClient.delete(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'X-Device-ID': deviceId,
        },
      ).timeout(_timeout);
      if (resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 204) {
        if (resp.body.isEmpty) return {'ok': true};
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      debugPrint('ServerService DELETE $path ${resp.statusCode}: ${resp.body}');
      return {'error': jsonDecode(resp.body)};
    } catch (e) {
      debugPrint('ServerService DELETE $path : $e');
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
    if (res != null && res['error'] == null) {
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

  // ====== GUILDES ======

  /// Liste toutes les guildes publiques
  static Future<List<Map<String, dynamic>>?> getGuilds() async {
    final res = await _get('/api/v1/guilds');
    if (res != null && res['guilds'] is List) {
      return (res['guilds'] as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Détail d'une guilde
  static Future<Map<String, dynamic>?> getGuildDetail(String guildId) async {
    return _get('/api/v1/guilds/$guildId');
  }

  /// Crée une guilde
  static Future<Map<String, dynamic>?> createGuild({
    required String name,
    required String description,
    required GuildJoinType joinType,
    required int minLevel,
    required int maxMembers,
    String? logoUrl,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'join_type': joinType.name,
      'min_level': minLevel,
      'max_members': maxMembers,
      if (logoUrl != null) 'logo_url': logoUrl,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/create', body);
  }

  /// Rejoint une guilde
  static Future<Map<String, dynamic>?> joinGuild(String guildId) async {
    final body = <String, dynamic>{
      'guild_id': guildId,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/join', body);
  }

  /// Quitte une guilde
  static Future<Map<String, dynamic>?> leaveGuild(String guildId, {bool showLog = true}) async {
    final body = <String, dynamic>{
      'guild_id': guildId,
      'show_log': showLog,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/$guildId/leave', body);
  }

  /// Exclut un membre
  static Future<Map<String, dynamic>?> kickMember(String guildId, String targetUid) async {
    final body = <String, dynamic>{
      'target_id': targetUid,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/$guildId/kick', body);
  }

  /// Promouvoir un membre en sous-chef
  static Future<Map<String, dynamic>?> promoteMember(String guildId, String targetUid) async {
    final body = <String, dynamic>{
      'target_id': targetUid,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/$guildId/promote', body);
  }

  /// Rétrograder un sous-chef en membre
  static Future<Map<String, dynamic>?> demoteMember(String guildId, String targetUid) async {
    final body = <String, dynamic>{
      'target_id': targetUid,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/$guildId/demote', body);
  }

  /// Transférer la direction de la guilde
  static Future<Map<String, dynamic>?> transferOwnership(String guildId, String targetUid) async {
    final body = <String, dynamic>{
      'target_id': targetUid,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/$guildId/transfer', body);
  }

  /// Mettre à jour les paramètres de la guilde
  static Future<Map<String, dynamic>?> updateGuild(String guildId, {
    String? name,
    String? description,
    String? logoUrl,
    GuildJoinType? joinType,
    int? minLevel,
    int? maxMembers,
  }) async {
    final body = <String, dynamic>{
      'device_id': await ensureDeviceId(),
    };
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (logoUrl != null) body['logo_url'] = logoUrl;
    if (joinType != null) body['join_type'] = joinType.name;
    if (minLevel != null) body['min_level'] = minLevel;
    if (maxMembers != null) body['max_members'] = maxMembers;
    return _post('/api/v1/guilds/$guildId/update', body);
  }

  /// Invite un utilisateur dans la guilde
  static Future<Map<String, dynamic>?> inviteToGuild(String guildId, String username) async {
    final body = <String, dynamic>{
      'username': username,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/$guildId/invite', body);
  }

  /// Mes guildes
  static Future<List<Map<String, dynamic>>?> getMyGuilds() async {
    final res = await _get('/api/v1/user/guilds');
    if (res != null && res['guilds'] is List) {
      return (res['guilds'] as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Détail de ma guilde (avec membres)
  static Future<Map<String, dynamic>?> getGuildMembers(String guildId) async {
    return _get('/api/v1/guilds/$guildId/members');
  }

  /// Logs de guilde
  static Future<List<Map<String, dynamic>>?> getGuildLogs(String guildId, {int page = 1}) async {
    final res = await _get('/api/v1/guilds/$guildId/logs?page=$page');
    if (res != null && res['logs'] is List) {
      return (res['logs'] as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Clé de chiffrement du chat guilde
  static Future<Map<String, dynamic>?> getGuildChatKey(String guildId) async {
    final body = <String, dynamic>{
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/$guildId/key', body);
  }

  /// Quêtes de guilde
  static Future<List<Map<String, dynamic>>?> getGuildQuests(String guildId) async {
    final res = await _get('/api/v1/guilds/$guildId/quests');
    if (res != null && res['quests'] is List) {
      return (res['quests'] as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Créer une quête de guilde
  static Future<Map<String, dynamic>?> createGuildQuest(String guildId, String title, String description, int xpReward, int coinReward) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'xp_reward': xpReward,
      'coin_reward': coinReward,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/$guildId/quests', body);
  }

  /// Compléter une quête de guilde
  static Future<Map<String, dynamic>?> completeGuildQuest(String guildId, String questId) async {
    final body = <String, dynamic>{
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/guilds/$guildId/quests/$questId/complete', body);
  }

  /// Annuler une quête de guilde
  static Future<Map<String, dynamic>?> deleteGuildQuest(String guildId, String questId) async {
    return _delete('/api/v1/guilds/$guildId/quests/$questId');
  }

  /// Classement des guildes
  static Future<List<Map<String, dynamic>>?> getGuildLeaderboard() async {
    final res = await _get('/api/v1/guilds/leaderboard');
    if (res != null && res['leaderboard'] is List) {
      return (res['leaderboard'] as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Mes invitations
  static Future<List<Map<String, dynamic>>?> getMyInvitations() async {
    final res = await _get('/api/v1/user/invitations');
    if (res != null && res['invitations'] is List) {
      return (res['invitations'] as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Répond à une invitation
  static Future<Map<String, dynamic>?> respondToInvitation(String invitationId, bool accept) async {
    final body = <String, dynamic>{
      'accept': accept,
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/invitations/$invitationId/respond', body);
  }

  /// Profil utilisateur par ID
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return _get('/api/v1/users/$uid/profile');
  }

  /// Profil utilisateur par pseudo (recherche dans le leaderboard puis profil)
  static Future<Map<String, dynamic>?> getUserProfileByPseudo(String pseudo) async {
    final leaderboard = await getLeaderboard();
    if (leaderboard == null) return null;
    final user = leaderboard.where((u) => u['username'] == pseudo).firstOrNull;
    if (user == null || user['user_id'] == null) return null;
    return getUserProfile(user['user_id'].toString());
  }

  /// Health check - ping le serveur pour vérifier la connectivité
  static Future<Map<String, dynamic>?> healthCheck() async {
    try {
      final deviceId = await ensureDeviceId();
      final url = '$baseUrl/api/v1/ping';
      debugPrint('ServerService healthCheck: POST $url');
      final resp = await httpClient
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'X-Device-ID': deviceId,
            },
            body: jsonEncode({'device_id': deviceId}),
          )
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ServerService healthCheck error: $e');
    }
    return null;
  }

  // ====== ACCOUNT LINKING & SYNC ======

  /// Lie le device à un compte existant (email + password)
  static Future<Map<String, dynamic>?> linkAccount({
    required String email,
    required String password,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'device_id': await ensureDeviceId(),
    };
    final res = await _post('/api/v1/account/link', body);
    if (res != null && res['message'] != null) {
      await saveUserPassword(password);
    }
    return res;
  }

  /// Crée un nouveau compte et le lie au device
  static Future<Map<String, dynamic>?> registerAccount({
    required String email,
    required String username,
    required String password,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'username': username,
      'password': password,
      'device_id': await ensureDeviceId(),
    };
    final res = await _post('/api/v1/account/register', body);
    if (res != null && res['message'] != null) {
      await saveUserPassword(password);
    }
    return res;
  }

  /// Délie le device du compte
  static Future<Map<String, dynamic>?> unlinkAccount() async {
    final body = <String, dynamic>{
      'device_id': await ensureDeviceId(),
    };
    final res = await _post('/api/v1/account/unlink', body);
    if (res != null && res['message'] != null) {
      await clearUserPassword();
    }
    return res;
  }

  /// Synchronise les données locale → serveur → retourne l'état serveur
  /// [mode] : 'merge' (défaut, somme), 'push' (local→serveur), 'pull' (serveur→local)
  /// [password] : si fourni, chiffre les données côté client avant envoi (E2E)
  static Future<Map<String, dynamic>?> syncData(Map<String, dynamic> localData, {String mode = 'merge', String? password}) async {
    final deviceId = await ensureDeviceId();
    final body = <String, dynamic>{
      'device_id': deviceId,
      'mode': mode,
    };
    
    if (password != null && password.isNotEmpty) {
      // Chiffrement côté client avec clé dérivée du mot de passe + salt aléatoire
      final enc = _encryptSyncData(localData, password);
      body['data'] = enc['data'];
      body['iv'] = enc['iv'];
      body['salt'] = enc['salt'];
      body['encrypted'] = true;
    } else {
      body['data'] = localData;
    }
    
    return _post('/api/v1/account/sync', body);
  }

  /// Déchiffre la réponse de sync si elle est chiffrée
  static Map<String, dynamic>? decryptSyncResponse(Map<String, dynamic> response, String password) {
    if (response['encrypted'] == true && response['data'] != null && response['iv'] != null && response['salt'] != null) {
      return _decryptSyncData({
        'data': response['data'],
        'iv': response['iv'],
        'salt': response['salt'],
      }, password);
    }
    // Réponse non chiffrée (ancien format ou mode sans mot de passe)
    return response['data'] as Map<String, dynamic>?;
  }

  /// Vérifie le statut de sync
  static Future<Map<String, dynamic>?> getSyncStatus() async {
    final body = <String, dynamic>{
      'device_id': await ensureDeviceId(),
    };
    return _post('/api/v1/account/sync/status', body);
  }

  /// Récupère le classement mondial des joueurs
  static Future<List<Map<String, dynamic>>?> getLeaderboard() async {
    final res = await _get('/api/v1/leaderboard');
    if (res != null && res['leaderboard'] is List) {
      return (res['leaderboard'] as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

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