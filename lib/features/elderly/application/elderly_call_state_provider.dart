import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/elderly_call_state.dart';

/// 着信オーバーレイの状態管理。
/// 将来は通話制御サービスからこの provider を更新して、UI をリアルタイムに切り替える。
final elderlyCallStateProvider =
    NotifierProvider<ElderlyCallStateController, ElderlyCallState>(
      ElderlyCallStateController.new,
    );

class ElderlyCallStateController extends Notifier<ElderlyCallState> {
  @override
  ElderlyCallState build() {
    return const ElderlyCallState.aiAnswering();
  }

  /// AI が電話に出て解析している状態を表示する。
  void showAiAnswering({
    String callerLabel = 'たろうくん（孫）',
    String liveTranscript = '相手が名前を言っています',
  }) {
    state = ElderlyCallState.aiAnswering(
      callerLabel: callerLabel,
      liveTranscript: liveTranscript,
    );
  }

  /// 安全な家族からの電話として高齢者にパスする状態を表示する。
  void showSafeToPass({String callerLabel = 'たろうくん（孫）'}) {
    state = ElderlyCallState.safeToPass(callerLabel: callerLabel);
  }

  /// あやしい電話としてブロックした状態を表示する。
  void showBlocked({
    String callerLabel = '不明な番号',
    String blockedDetail = 'AIが「折り返します」と言って切りました。',
  }) {
    state = ElderlyCallState.blocked(
      callerLabel: callerLabel,
      blockedDetail: blockedDetail,
    );
  }

  /// 高齢者が自分で止めたいときの緊急ブロック。
  void emergencyBlock() {
    showBlocked(blockedDetail: 'AIが通話を止めて、すぐに切りました。');
  }
}
