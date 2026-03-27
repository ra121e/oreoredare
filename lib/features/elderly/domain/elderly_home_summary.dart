/// 高齢者側ホーム画面の表示用データ。
/// 今はモック値だが、将来は着信ログや判定結果から差し替える想定。
class ElderlyHomeSummary {
  const ElderlyHomeSummary({
    required this.isGuarding,
    required this.guardMessage,
    required this.totalCallsToday,
    required this.safeCalls,
    required this.blockedCalls,
    required this.lastCallSummary,
  });

  final bool isGuarding;
  final String guardMessage;
  final int totalCallsToday;
  final int safeCalls;
  final int blockedCalls;
  final String lastCallSummary;

  String get guardLabel => isGuarding ? 'ガード中' : '確認が必要です';

  String get voiceGuideMessage {
    return 'オレオレ誰？が$guardLabelです。'
        '今日の着信は$totalCallsToday件、'
        '安全が$safeCalls件、'
        'ブロックが$blockedCalls件です。';
  }
}
