import 'package:flutter/material.dart';

import '../screens/elderly_history_screen.dart';
import '../screens/elderly_home_screen.dart';
import '../screens/family_contact_screen.dart';
import '../theme/elderly_theme.dart';

/// アプリ全体のルート。
/// 高齢者側の操作を最優先にしたシンプルなナビゲーションだけを先に用意する。
class OreOreApp extends StatelessWidget {
  const OreOreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'オレオレ誰？',
      debugShowCheckedModeBanner: false,
      theme: ElderlyTheme.light(),
      initialRoute: ElderlyHomeScreen.routeName,
      routes: {
        ElderlyHomeScreen.routeName: (context) => const ElderlyHomeScreen(),
        ElderlyHistoryScreen.routeName: (context) =>
            const ElderlyHistoryScreen(),
        FamilyContactScreen.routeName: (context) => const FamilyContactScreen(),
      },
    );
  }
}
