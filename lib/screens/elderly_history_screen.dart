import 'package:flutter/material.dart';

/// 着信履歴画面の仮実装。
/// まずはホーム画面から迷わず遷移できることを優先する。
class ElderlyHistoryScreen extends StatelessWidget {
  const ElderlyHistoryScreen({super.key});

  static const routeName = '/history';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('履歴を見る')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('着信履歴', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(
                '次の段階で、ここに安全な着信とブロックした着信を大きく見やすく並べます。',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ホームにもどる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
