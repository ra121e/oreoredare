import 'package:flutter/material.dart';

/// 家族へ連絡するための仮画面。
/// 将来はワンタップで電話やメッセージ送信ができる形に広げる。
class FamilyContactScreen extends StatelessWidget {
  const FamilyContactScreen({super.key});

  static const routeName = '/family-contact';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('家族に連絡する')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('家族に連絡する', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(
                '困ったときに、よく連絡する家族を大きなボタンで並べる予定です。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F5EE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '登録中の連絡先\n孫 太郎 さん',
                  style: theme.textTheme.titleMedium,
                ),
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
