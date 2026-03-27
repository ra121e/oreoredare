import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/elderly_home_summary.dart';

/// ホーム画面の初期モック。
/// MVP の最初の段階では、ここを静的データにして UI の骨組みを固める。
final elderlyHomeSummaryProvider = Provider<ElderlyHomeSummary>((ref) {
  return const ElderlyHomeSummary(
    isGuarding: true,
    guardMessage: '今日も守っています！',
    totalCallsToday: 3,
    safeCalls: 2,
    blockedCalls: 1,
    lastCallSummary: '最後の着信: 10分前（ブロック済み）',
  );
});
