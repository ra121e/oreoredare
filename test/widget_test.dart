// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreoredare/app/oreore_app.dart';

void main() {
  testWidgets('ホーム画面の主要情報が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OreOreApp()));

    expect(find.text('🛡️ オレオレ誰？ ガード中'), findsOneWidget);
    expect(find.text('今日の着信件数'), findsOneWidget);
    expect(find.text('履歴を見る'), findsOneWidget);
    expect(find.text('家族に連絡する'), findsOneWidget);
    expect(find.text('着信画面テスト'), findsOneWidget);
  });

  testWidgets('ホーム画面からAI応答中オーバーレイを開ける', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OreOreApp()));

    await tester.ensureVisible(find.text('AI応答中を試す'));
    await tester.pump();
    await tester.tap(find.text('AI応答中を試す'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('AIお孫さんが'), findsOneWidget);
    expect(find.text('📵 緊急ブロック'), findsOneWidget);
  });
}
