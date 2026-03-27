import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessibility/voice_guide_controller.dart';
import '../features/elderly/application/elderly_call_state_provider.dart';
import '../features/elderly/domain/elderly_call_state.dart';
import '../theme/elderly_theme.dart';

/// 着信時オーバーレイを全画面モーダルで表示する。
Future<void> showElderlyCallOverlay(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '着信オーバーレイ',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const ElderlyCallOverlayScreen();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 高齢者向けの着信オーバーレイ本体。
/// Riverpod の状態に応じて、AI応答中 / 安全 / ブロックの3状態を切り替える。
class ElderlyCallOverlayScreen extends ConsumerStatefulWidget {
  const ElderlyCallOverlayScreen({super.key});

  @override
  ConsumerState<ElderlyCallOverlayScreen> createState() =>
      _ElderlyCallOverlayScreenState();
}

class _ElderlyCallOverlayScreenState
    extends ConsumerState<ElderlyCallOverlayScreen> {
  late final VoiceGuideController _voiceGuideController;
  late final ProviderSubscription<ElderlyCallState> _callStateSubscription;

  @override
  void initState() {
    super.initState();
    _voiceGuideController = ref.read(voiceGuideControllerProvider);

    _callStateSubscription = ref.listenManual<ElderlyCallState>(
      elderlyCallStateProvider,
      (previous, next) {
        if (previous?.voiceGuideMessage == next.voiceGuideMessage) {
          return;
        }

        unawaited(_voiceGuideController.announceAction(next.voiceGuideMessage));
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _callStateSubscription.close();
    unawaited(_voiceGuideController.stop());
    super.dispose();
  }

  Future<void> _closeOverlay({String? voiceMessage}) async {
    if (voiceMessage != null) {
      await _voiceGuideController.announceAction(voiceMessage);
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(elderlyCallStateProvider);
    final isBlocked = state.status == ElderlyCallOverlayStatus.blocked;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isBlocked
                ? const [
                    ElderlyPalette.blockedBackground,
                    ElderlyPalette.blockedSurface,
                  ]
                : const [
                    ElderlyPalette.overlayScrim,
                    ElderlyPalette.background,
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _StatePanel(
                    key: ValueKey(state.status),
                    child: switch (state.status) {
                      ElderlyCallOverlayStatus.aiAnswering => _AiAnsweringView(
                        state: state,
                        onEmergencyBlock: () {
                          ref
                              .read(elderlyCallStateProvider.notifier)
                              .emergencyBlock();
                        },
                      ),
                      ElderlyCallOverlayStatus.safeToPass => _SafeToPassView(
                        state: state,
                        onAnswerNow: () => _closeOverlay(
                          voiceMessage: '${state.callerLabel}からの電話をつなぎます。',
                        ),
                        onDecline: () =>
                            _closeOverlay(voiceMessage: 'この電話には出ません。'),
                      ),
                      ElderlyCallOverlayStatus.blocked => _BlockedView(
                        state: state,
                        onBack: () =>
                            _closeOverlay(voiceMessage: 'ホーム画面にもどります。'),
                      ),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 状態ごとの中身を包む共通パネル。
class _StatePanel extends StatelessWidget {
  const _StatePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 状態1: AIが通話を解析している最中の表示。
class _AiAnsweringView extends StatelessWidget {
  const _AiAnsweringView({required this.state, required this.onEmergencyBlock});

  final ElderlyCallState state;
  final VoidCallback onEmergencyBlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '🤖 AIお孫さんが\nかわりに出ています',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: ElderlyPalette.accentSurface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      color: ElderlyPalette.secondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('解析中です', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 18),
              const LinearProgressIndicator(
                minHeight: 16,
                borderRadius: BorderRadius.all(Radius.circular(999)),
                color: ElderlyPalette.secondary,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ElderlyPalette.subtleBorder, width: 1.5),
          ),
          child: Text(
            '「${state.liveTranscript}」',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 92,
          child: ElevatedButton(
            onPressed: onEmergencyBlock,
            style: ElevatedButton.styleFrom(
              backgroundColor: ElderlyPalette.blockedBackground,
            ),
            child: Text(
              '📵 緊急ブロック',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 状態2: 安全な家族の電話を本人にパスするときの表示。
class _SafeToPassView extends StatelessWidget {
  const _SafeToPassView({
    required this.state,
    required this.onAnswerNow,
    required this.onDecline,
  });

  final ElderlyCallState state;
  final Future<void> Function() onAnswerNow;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 120,
          height: 120,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: const BoxDecoration(
            color: ElderlyPalette.successSurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 72,
            color: ElderlyPalette.primary,
          ),
        ),
        Text(
          state.safeHeadline,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Text(
          '安全な電話として確認できました。',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 96,
          child: ElevatedButton(
            onPressed: onAnswerNow,
            child: Text(
              '📞 今すぐ出る',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: OutlinedButton(onPressed: onDecline, child: const Text('出ない')),
        ),
      ],
    );
  }
}

/// 状態3: あやしい電話をブロックしたことを安心感を持って知らせる表示。
class _BlockedView extends StatelessWidget {
  const _BlockedView({required this.state, required this.onBack});

  final ElderlyCallState state;
  final Future<void> Function() onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ElderlyPalette.blockedBackground,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.block_rounded, size: 84, color: Colors.white),
            const SizedBox(height: 18),
            Text(
              '🚫 あやしい電話を\nブロックしました。\nご安心ください',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              state.blockedDetail,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 80,
              child: ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ElderlyPalette.blockedBackground,
                ),
                child: Text(
                  'もどる',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: ElderlyPalette.blockedBackground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
