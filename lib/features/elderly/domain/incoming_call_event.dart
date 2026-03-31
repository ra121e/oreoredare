enum IncomingCallEventType { incomingCall, callConnected, callEnded, unknown }

/// Android ネイティブから Flutter に渡される着信イベント。
/// 今回の MVP では「着信を検知して既存オーバーレイを表示する」ことに絞る。
class IncomingCallEvent {
  const IncomingCallEvent({
    required this.eventType,
    required this.timestamp,
    required this.phoneNumber,
    required this.source,
    required this.callState,
  });

  final IncomingCallEventType eventType;
  final DateTime timestamp;
  final String? phoneNumber;
  final String source;
  final String callState;

  bool get isIncomingCall => eventType == IncomingCallEventType.incomingCall;

  bool get endsOverlay =>
      eventType == IncomingCallEventType.callConnected ||
      eventType == IncomingCallEventType.callEnded;

  String get callerLabel => phoneNumber == null ? '着信を確認しています' : phoneNumber!;

  factory IncomingCallEvent.fromMap(Map<Object?, Object?> raw) {
    final eventTypeName = '${raw['eventType'] ?? 'unknown'}';
    final timestampValue = raw['timestamp'];
    final timestampMilliseconds = timestampValue is num
        ? timestampValue.toInt()
        : int.tryParse('$timestampValue') ?? 0;

    return IncomingCallEvent(
      eventType: _parseEventType(eventTypeName),
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMilliseconds),
      phoneNumber: raw['phoneNumber'] as String?,
      source: '${raw['source'] ?? 'unknown'}',
      callState: '${raw['callState'] ?? 'CALL_STATE_UNKNOWN'}',
    );
  }

  static IncomingCallEventType _parseEventType(String value) {
    switch (value) {
      case 'incoming_call':
      case 'ringing':
        return IncomingCallEventType.incomingCall;
      case 'call_connected':
      case 'offhook':
        return IncomingCallEventType.callConnected;
      case 'call_ended':
      case 'idle':
        return IncomingCallEventType.callEnded;
      default:
        return IncomingCallEventType.unknown;
    }
  }
}
