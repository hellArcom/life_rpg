import 'package:flutter_test/flutter_test.dart';

import 'package:life_rpg/main.dart';

void main() {
  testWidgets('App builds correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeRPGApp());
    expect(find.byType(LifeRPGApp), findsOneWidget);
  });
}
