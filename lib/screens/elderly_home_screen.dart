import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessibility/voice_guide_controller.dart';
import '../features/elderly/application/elderly_call_state_provider.dart';
import '../features/elderly/application/elderly_home_providers.dart';
import '../features/elderly/domain/elderly_call_state.dart';
import '../features/elderly/domain/elderly_home_summary.dart';
import '../theme/elderly_theme.dart';
import 'elderly_call_overlay_screen.dart';
import 'elderly_history_screen.dart';
import 'family_contact_screen.dart';

/// 高齢者側ホーム画面。
/// ARCHITECTURE.md の 5.1 をもとに、まずは見やすい骨組みを優先して実装する。
class ElderlyHomeScreen extends ConsumerStatefulWidget {
  const ElderlyHomeScreen({super.key});

  static const routeName = '/';

  @override
  ConsumerState<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends ConsumerState<ElderlyHomeScreen> {
  late final VoiceGuideController _voiceGuideController;

  @override
  void initState() {
    super.initState();
    _voiceGuideController = ref.read(voiceGuideControllerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final summary = ref.read(elderlyHomeSummaryProvider);
      unawaited(_voiceGuideController.announceHome(summary));
    });
  }

  @override
  void dispose() {
    unawaited(_voiceGuideController.stop());
    super.dispose();
  }

  Future<void> _openHistory() async {
    await _voiceGuideController.announceAction('履歴を開きます。');

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamed(ElderlyHistoryScreen.routeName);
  }

  Future<void> _contactFamily() async {
    await _voiceGuideController.announceAction('家族への連絡画面を開きます。');

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamed(FamilyContactScreen.routeName);
  }

  /// ホーム画面から着信オーバーレイを試せるようにする。
  /// 実際の着信連携前でも、3状態の見た目と読み上げを確認できるようにする。
  Future<void> _showIncomingCallDemo(ElderlyCallOverlayStatus status) async {
    final controller = ref.read(elderlyCallStateProvider.notifier);

    switch (status) {
      case ElderlyCallOverlayStatus.aiAnswering:
        controller.showAiAnswering();
      case ElderlyCallOverlayStatus.safeToPass:
        controller.showSafeToPass();
      case ElderlyCallOverlayStatus.blocked:
        controller.showBlocked();
    }

    if (!mounted) {
      return;
    }

    await showElderlyCallOverlay(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ref.watch(elderlyHomeSummaryProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFCF6), Color(0xFFF6FBF8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHeader(summary: summary),
                const SizedBox(height: 20),
                _GuardStatusCard(summary: summary),
                const SizedBox(height: 18),
                _TodaySummaryCard(summary: summary),
                const SizedBox(height: 24),
                _HomeActionButton(
                  icon: Icons.history_rounded,
                  label: '履歴を見る',
                  hint: 'これまでの着信履歴を確認できます',
                  onPressed: _openHistory,
                ),
                const SizedBox(height: 16),
                _HomeActionButton(
                  icon: Icons.call_rounded,
                  label: '家族に連絡する',
                  hint: '困ったときに家族へすぐ連絡できます',
                  onPressed: _contactFamily,
                  backgroundColor: ElderlyPalette.secondary,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: ElderlyPalette.subtleBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    summary.lastCallSummary,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 20),
                _IncomingCallTestPanel(onShowDemo: _showIncomingCallDemo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 画面の先頭に、アプリ名と現在の保護状態を大きく表示する。
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.summary});

  final ElderlyHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ElderlyPalette.accentSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: ElderlyPalette.subtleBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🛡️ オレオレ誰？ ガード中', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Text('知らない電話も、あわてずアプリが先に確認します。', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(summary.guardMessage, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

/// ガード状態を一目で分かるようにするカード。
class _GuardStatusCard extends StatelessWidget {
  const _GuardStatusCard({required this.summary});

  final ElderlyHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ElderlyPalette.cardSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ElderlyPalette.subtleBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: ElderlyPalette.primary,
              size: 40,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.guardLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'AI が電話を確認してから、大事な連絡だけをお知らせします。',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 今日の着信件数を大きな数字で表示するカード。
class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.summary});

  final ElderlyHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ElderlyPalette.subtleBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日の着信件数', style: theme.textTheme.titleMedium),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.totalCallsToday}',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('件', style: theme.textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CountBadge(
                  label: '安全',
                  count: summary.safeCalls,
                  backgroundColor: ElderlyPalette.accentSurface,
                  textColor: ElderlyPalette.primaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CountBadge(
                  label: 'ブロック',
                  count: summary.blockedCalls,
                  backgroundColor: ElderlyPalette.alertSurface,
                  textColor: ElderlyPalette.blocked,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 件数表示用の小カード。
class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    required this.count,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final int count;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: textColor),
          ),
          const SizedBox(height: 6),
          Text(
            '$count件',
            style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}

/// 高齢者が迷わず押せるように、全幅・大きめのボタンにする。
class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onPressed,
    this.backgroundColor = ElderlyPalette.primary,
  });

  final IconData icon;
  final String label;
  final String hint;
  final Future<void> Function() onPressed;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: label,
      hint: hint,
      child: SizedBox(
        height: 92,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: backgroundColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 実装確認用のテスト導線。
/// 後で実際の着信イベントがつながったら置き換える想定。
class _IncomingCallTestPanel extends StatelessWidget {
  const _IncomingCallTestPanel({required this.onShowDemo});

  final Future<void> Function(ElderlyCallOverlayStatus status) onShowDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ElderlyPalette.subtleBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('着信画面テスト', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('着信時オーバーレイの3つの状態を確認できます。', style: theme.textTheme.bodySmall),
          const SizedBox(height: 18),
          _DemoActionButton(
            label: 'AI応答中を試す',
            onPressed: () => onShowDemo(ElderlyCallOverlayStatus.aiAnswering),
          ),
          const SizedBox(height: 12),
          _DemoActionButton(
            label: '安全判定を試す',
            onPressed: () => onShowDemo(ElderlyCallOverlayStatus.safeToPass),
          ),
          const SizedBox(height: 12),
          _DemoActionButton(
            label: 'ブロック通知を試す',
            backgroundColor: ElderlyPalette.blockedBackground,
            onPressed: () => onShowDemo(ElderlyCallOverlayStatus.blocked),
          ),
        ],
      ),
    );
  }
}

class _DemoActionButton extends StatelessWidget {
  const _DemoActionButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor = ElderlyPalette.secondary,
  });

  final String label;
  final Future<void> Function() onPressed;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: backgroundColor),
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
