import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hive/hive.dart';
import 'package:life_rpg_dev/models/game_models.dart';
import 'package:life_rpg_dev/services/server_service.dart';

// This test verifies the APP side of the contract: that ServerService builds
// exactly the requests the server expects (per SERVER_API.md) and parses the
// documented responses correctly. flutter test fakes all real HTTP, so we use
// a MockClient and assert on the captured requests/responses. The server's own
// logic is covered separately by the Python test_client suite
// (Life_RPG_serveur) plus live curl smoke tests.

void main() {
  late Box box;
  late Map<Uri, http.BaseRequest> captured;
  late List<http.BaseRequest> requests;
  late Future<http.Response> Function(http.BaseRequest) handler;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // FlutterSecureStorage has no test implementation; mock its method channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    // Init Hive manually (initFlutter needs path_provider, unavailable in tests)
    final dir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(dir.path);
    box = await Hive.openBox('game_data');
  });

  setUp(() {
    captured = {};
    requests = [];
    handler = (_) async => http.Response('{}', 200);
    ServerService.httpClient = MockClient((req) async {
      requests.add(req);
      captured[req.url] = req;
      return handler(req);
    });
  });

  Future<Map<String, dynamic>> _bodyOf(http.BaseRequest req) async {
    final r = req as http.Request;
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  test('register posts to /api/v1/register with device_id + X-Device-ID header', () async {
    handler = (_) async => http.Response(jsonEncode({
      'status': 'created',
      'user_id': 1,
      'referral_code': 'ABC234XY',
      'referrals_count': 0,
    }), 201);
    final res = await ServerService.register('');
    expect(res!['status'], 'created');
    expect(res['referral_code'], 'ABC234XY');

    final regReq = requests.where((r) => r.url.path == '/api/v1/register').first;
    expect(regReq.method, 'POST');
    final body = await _bodyOf(regReq);
    expect(body['device_id'], isA<String>());
    expect(regReq.headers['X-Device-ID'], body['device_id']);
  });

  test('ping returns pending_rewards list', () async {
    handler = (_) async => http.Response(jsonEncode({
      'status': 'ok',
      'last_active_at': '2026-08-10T00:00:00Z',
      'pending_rewards': [
        {'reward_id': 'rw_1', 'type': 'referral_referrer', 'coins': 250, 'freeze_days': 3, 'xp': 300}
      ],
    }), 200);
    final res = await ServerService.ping();
    expect(res!['status'], 'ok');
    expect((res['pending_rewards'] as List).first['coins'], 250);
    expect(requests.any((r) => r.url.path == '/api/v1/ping'), isTrue);
  });

  test('submitReferral returns status and sends code + device_id', () async {
    handler = (_) async => http.Response(jsonEncode({'status': 'ok'}), 200);
    final res = await ServerService.submitReferral('ABC234XY');
    expect(res!['status'], 'ok');
    final req = requests.where((r) => r.url.path == '/api/v1/referral/submit').first;
    final body = await _bodyOf(req);
    expect(body['code'], 'ABC234XY');
    expect(body['device_id'], isA<String>());
  });

  test('fetchUpdate returns version info (GET, no body)', () async {
    handler = (_) async => http.Response(jsonEncode({
      'version': '9.9.9',
      'download_url': 'https://example.com',
      'release_notes': 'n',
      'mandatory': false,
    }), 200);
    final res = await ServerService.fetchUpdate();
    expect(res!['version'], '9.9.9');
    final req = requests.where((r) => r.url.path == '/api/v1/update').first;
    expect(req.method, 'GET');
  });

  test('getGuilds parses {"guilds": [...]}', () async {
    handler = (_) async => http.Response(jsonEncode({
      'guilds': [
        {'id': 1, 'name': 'G', 'join_type': 'open'}
      ]
    }), 200);
    final res = await ServerService.getGuilds();
    expect(res, isNotNull);
    expect(res!.length, 1);
    expect(res.first['name'], 'G');
  });

  test('silent failure: non-2xx response returns null (no throw)', () async {
    handler = (_) async => http.Response(jsonEncode({'error': 'forbidden'}), 403);
    final res = await ServerService.createGuild(
      name: 'X',
      description: 'd',
      joinType: GuildJoinType.open,
      minLevel: 0,
      maxMembers: 50,
    );
    expect(res, isNull);
  });

  test('E2E client-side encrypted sync roundtrip (push -> pull -> decrypt)', () async {
    Map<String, dynamic>? pushed;
    handler = (req) async {
      if (req is http.Request && req.url.path == '/api/v1/account/sync') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        if (body['mode'] == 'push') {
          pushed = body;
          return http.Response(jsonEncode({'message': 'ok'}), 200);
        }
        if (body['mode'] == 'pull' && pushed != null) {
          return http.Response(jsonEncode({
            'message': 'ok',
            'data': pushed!['data'],
            'iv': pushed!['iv'],
            'salt': pushed!['salt'],
            'encrypted': true,
          }), 200);
        }
      }
      return http.Response('{}', 200);
    };

    final localData = {
      'level': 7,
      'globalXp': 1234,
      'coins': 50,
      'streak': 3,
      'badgeIds': ['a', 'b'],
      'total_quests_completed': 10,
    };
    await ServerService.syncData(localData, mode: 'push', password: 'pw123');

    // The request must have been encrypted (not sent in plaintext)
    expect(pushed, isNotNull);
    expect(pushed!['encrypted'], isTrue);
    expect(pushed!['data'], isNot(contains('level'))); // base64 blob

    final pull = await ServerService.syncData({}, mode: 'pull', password: 'pw123');
    expect(pull, isNotNull);
    expect(pull!['encrypted'], isTrue);
    final decrypted = ServerService.decryptSyncResponse(pull, 'pw123');
    expect(decrypted, isNotNull);
    expect(decrypted!['level'], 7);
    expect(decrypted['coins'], 50);
    expect(decrypted['badgeIds'], contains('a'));
  });

  test('account link posts email/password/device_id', () async {
    handler = (_) async => http.Response(jsonEncode({'message': 'Compte lié avec succès'}), 200);
    final res = await ServerService.linkAccount(email: 'a@b.com', password: 'password123');
    expect(res!['message'], contains('lié'));
    final req = requests.where((r) => r.url.path == '/api/v1/account/link').first;
    final body = await _bodyOf(req);
    expect(body['email'], 'a@b.com');
    expect(body['password'], 'password123');
    expect(body['device_id'], isA<String>());
  });
}
