/// 着信オーバーレイの表示状態。
enum ElderlyCallOverlayStatus { aiAnswering, safeToPass, blocked }

/// 高齢者向け着信オーバーレイの表示用データ。
/// 実際の通話制御とつながるまでは、まずはモック値で状態切り替えだけを成立させる。
class ElderlyCallState {
  const ElderlyCallState({
    required this.status,
    required this.callerLabel,
    required this.liveTranscript,
    required this.blockedDetail,
  });

  final ElderlyCallOverlayStatus status;
  final String callerLabel;
  final String liveTranscript;
  final String blockedDetail;

  const ElderlyCallState.aiAnswering({
    this.callerLabel = 'たろうくん（孫）',
    this.liveTranscript = '相手が名前を言っています',
  }) : status = ElderlyCallOverlayStatus.aiAnswering,
       blockedDetail = 'AIが確認を続けています。';

  const ElderlyCallState.safeToPass({this.callerLabel = 'たろうくん（孫）'})
    : status = ElderlyCallOverlayStatus.safeToPass,
      liveTranscript = '安全な相手として確認できました。',
      blockedDetail = '問題ありません。';

  const ElderlyCallState.blocked({
    this.callerLabel = '不明な番号',
    this.blockedDetail = 'AIが「折り返します」と言って切りました。',
  }) : status = ElderlyCallOverlayStatus.blocked,
       liveTranscript = 'あやしい言い回しを検知しました。';

  String get safeHeadline => '✅ $callerLabelからです！';

  String get voiceGuideMessage {
    switch (status) {
      case ElderlyCallOverlayStatus.aiAnswering:
        return 'AIお孫さんが、かわりに出ています。解析中です。';
      case ElderlyCallOverlayStatus.safeToPass:
        return '$callerLabelからの安全な電話です。今すぐ出るボタンを押せます。';
      case ElderlyCallOverlayStatus.blocked:
        return 'あやしい電話をブロックしました。ご安心ください。';
    }
  }
}
