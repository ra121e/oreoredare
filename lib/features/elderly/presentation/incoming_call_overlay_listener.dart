import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/elderly_call_state_provider.dart';
import '../application/incoming_call_bridge.dart';
import '../domain/incoming_call_event.dart';
import '../../../screens/elderly_call_overlay_screen.dart';

/// Android ネイティブの着信イベントを既存の Flutter オーバーレイに橋渡しする。
/// 初回 MVP では「着信したら AI 応答中状態を表示する」ことに絞る。
class IncomingCallOverlayListener extends ConsumerStatefulWidget {
  const IncomingCallOverlayListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  ConsumerState<IncomingCallOverlayListener> createState() =>
      _IncomingCallOverlayListenerState();
}

class _IncomingCallOverlayListenerState
    extends ConsumerState<IncomingCallOverlayListener>
    with WidgetsBindingObserver {
  StreamSubscription<IncomingCallEvent>? _subscription;
  IncomingCallEvent? _pendingRingingEvent;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  bool _isOverlayVisible = false;
  bool _isInitializingMonitoring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeMonitoring(reason: 'initial'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      /*
       * Call Screening role の許可画面から戻ってきた直後は、
       * 初回起動時の状態が古いまま残ることがある。
       * そのため、復帰時に監視状態を再評価して
       * Service 経由の経路へ切り替わったかを確認する。
       */
      unawaited(_initializeMonitoring(reason: 'resume'));
      unawaited(_presentPendingOverlayIfNeeded());
    }
  }

  Future<void> _initializeMonitoring({required String reason}) async {
    if (_isInitializingMonitoring) {
      return;
    }

    _isInitializingMonitoring = true;
    final bridge = ref.read(incomingCallBridgeProvider);
    try {
      final monitoringState = await bridge.initializeMonitoring();

      debugPrint(
        'IncomingCallOverlayListener[$reason]: '
        '${monitoringState.statusMessage}',
      );
      debugPrint(
        'IncomingCallOverlayListener[$reason]: source=${monitoringState.source}'
        ' callScreeningRoleGranted=${monitoringState.callScreeningRoleGranted}'
        ' contactsPermissionGranted=${monitoringState.contactsPermissionGranted}'
        ' callScreeningRoleRequested=${monitoringState.callScreeningRoleRequested}',
      );

      await _subscription?.cancel();
      _subscription = null;

      if (!monitoringState.monitoringActive) {
        return;
      }

      _subscription = bridge.watchIncomingCalls().listen(
        _handleIncomingCallEvent,
      );
    } finally {
      _isInitializingMonitoring = false;
    }
  }

  void _handleIncomingCallEvent(IncomingCallEvent event) {
    debugPrint(
      'IncomingCallOverlayListener: ${event.eventType.name}'
      ' source=${event.source} state=${event.callState}'
      ' phone=${event.phoneNumber ?? 'unknown'}',
    );

    if (event.isIncomingCall) {
      _pendingRingingEvent = event;
      unawaited(_presentPendingOverlayIfNeeded());
      return;
    }

    if (event.endsOverlay) {
      unawaited(_dismissOverlayIfNeeded());
    }
  }

  Future<void> _presentPendingOverlayIfNeeded() async {
    if (!mounted || _isOverlayVisible) {
      return;
    }

    if (_appLifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final event = _pendingRingingEvent;
    if (event == null) {
      return;
    }

    _pendingRingingEvent = null;

    /*
     * 通話判定ロジックはまだ入っていないため、
     * 実着信を受けたらまずは AI 応答中状態だけを表示して
     * Flutter 側までイベントが届いたことを確認しやすくする。
     */
    ref
        .read(elderlyCallStateProvider.notifier)
        .showAiAnswering(
          callerLabel: event.callerLabel,
          liveTranscript: '着信を確認しています。少しお待ちください。',
        );

    _isOverlayVisible = true;

    try {
      final overlayContext = widget.navigatorKey.currentState?.overlay?.context;
      if (overlayContext == null) {
        return;
      }

      await showElderlyCallOverlay(overlayContext);
    } finally {
      _isOverlayVisible = false;
    }
  }

  Future<void> _dismissOverlayIfNeeded() async {
    if (!mounted || !_isOverlayVisible) {
      return;
    }

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) {
      return;
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
