import 'package:flutter/material.dart';

/// 家族側ダッシュボードのプレースホルダー画面。
/// ルーティング準備：後で家族向けウィジェット（認証・デバイス一覧など）を実装可能。

class FamilyDashboard extends StatelessWidget {
  const FamilyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('オレオレ誰？ — 家族ダッシュボード')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '家族ダッシュボード',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'ここに家族が管理する端末一覧、アラート、ログの概要を表示します。',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('登録端末 1'),
                subtitle: const Text('高齢者A（最近の着信: 14:38）'),
                trailing: ElevatedButton(
                  onPressed: () {},
                  child: const Text('詳細'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
