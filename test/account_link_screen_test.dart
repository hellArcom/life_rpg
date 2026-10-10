import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:life_rpg_dev/core/offline_manager.dart';
import 'package:life_rpg_dev/core/translations.dart';
import 'package:life_rpg_dev/providers/game_provider.dart';
import 'package:life_rpg_dev/services/server_service.dart';
import 'package:life_rpg_dev/ui/screens/account_link_screen.dart';

/// Reproduces the real link-account flow: the success path closes the link
/// dialog and then opens the merge dialog while the first dialog route is
/// still being removed from the tree.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('account_link_hive');
    Hive.init(dir.path);
    await Hive.openBox('game_data');
  });

  setUp(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.arcom.life_rpg/widget'),
      (call) async => true,
    );

    await OfflineManager.saveData('settings', {
      'onlineServicesEnabled': true,
      'serverUrl': 'https://example.test',
    });
    await OfflineManager.deleteData('game_data');

    var linked = false;
    ServerService.httpClient = MockClient((req) async {
      switch (req.url.path) {
        case '/api/v1/account/link':
          linked = true;
          return http.Response(
            jsonEncode({'message': 'Compte lié avec succès'}),
            200,
          );
        case '/api/v1/account/sync/status':
          return http.Response(
            jsonEncode({'linked': linked, 'last_sync_at': null}),
            200,
          );
        default:
          return http.Response('{}', 200);
      }
    });
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccountLinkScreen()),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      // ignore: avoid_print
      print('DEBUG pump $i spinners=${find.byType(CircularProgressIndicator).evaluate().length}');
    }
    // ignore: avoid_print
    print('DEBUG spinners=${find.byType(CircularProgressIndicator).evaluate().length} '
        'hasScheduledFrame=${tester.binding.hasScheduledFrame} '
        'texts=${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList()}');
    return container;
  }

  Future<void> submitLinkForm(WidgetTester tester, Translations t) async {
    await tester.tap(find.text(t.linkMyAccount));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, t.link));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'linking an account with local data shows the merge dialog without error',
    (tester) async {
      var preDone = false;
      ServerService.getSyncStatus().then((v) {
        preDone = true;
        // ignore: avoid_print
        print('DEBUG pre=$v');
      });
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // ignore: avoid_print
      print('DEBUG preDone=$preDone');
      final container = await pumpScreen(tester);
      final t = container.read(translationsProvider);

      container.read(gameProvider.notifier).importData(jsonEncode({
            'user': {
              'uid': '1',
              'pseudo': 'Héros',
              'title': 'Novice',
              'globalXp': 5000,
              'level': 3,
              'streak': 2,
              'coins': 100,
            },
            'dataVersion': 1,
          }));
      await tester.pumpAndSettle();

      await submitLinkForm(tester, t);

      expect(tester.takeException(), isNull);
      expect(find.text(t.localDataDetected), findsOneWidget);

      // Flush the debounced Hive save timer scheduled by checkAccountLinkStatus.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'linking an account without local data updates the status without error',
    (tester) async {
      final container = await pumpScreen(tester);
      final t = container.read(translationsProvider);

      await submitLinkForm(tester, t);

      expect(tester.takeException(), isNull);
      expect(find.text(t.localDataDetected), findsNothing);
      expect(find.text(t.accountLinked), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );
}
