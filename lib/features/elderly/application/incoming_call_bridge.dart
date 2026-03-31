import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/incoming_call_event.dart';

abstract class IncomingCallBridge {
  Future<IncomingCallMonitoringState> initializeMonitoring();

  Stream<IncomingCallEvent> watchIncomingCalls();
}

/// Android 実機向けのネイティブブリッジ。
/// EventChannel で着信イベントを受け取り、最小構成の MVP に接続する。
class AndroidIncomingCallBridge implements IncomingCallBridge {
  static const _eventChannel = EventChannel('oreoredare/incoming_call_events');
  static const _methodChannel = MethodChannel(
    'oreoredare/incoming_call_bridge',
  );
  // resume ごとに同じ任意権限ダイアログを出し続けないよう、セッション中の再要求を抑える。
  static bool _hasAttemptedContactsPermissionRequest = false;

  @override
  Future<IncomingCallMonitoringState> initializeMonitoring() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const IncomingCallMonitoringState(
        permissionGranted: false,
        contactsPermissionGranted: false,
        monitoringActive: false,
        callScreeningRoleGranted: false,
        statusMessage: 'Android 以外では着信監視を開始しません。',
      );
    }

    try {
      final permissionStatus = await Permission.phone.request();

      if (!permissionStatus.isGranted) {
        return const IncomingCallMonitoringState(
          permissionGranted: false,
          contactsPermissionGranted: false,
          monitoringActive: false,
          callScreeningRoleGranted: false,
          statusMessage: '電話権限が未許可のため、着信監視を開始できません。',
        );
      }

      final contactsPermissionStatus = await _ensureContactsPermission();

      final response =
          await _methodChannel.invokeMapMethod<String, dynamic>(
            'initializeMonitoring',
          ) ??
          const <String, dynamic>{};

      final state = IncomingCallMonitoringState.fromMap(
        response,
      ).copyWith(contactsPermissionGranted: contactsPermissionStatus.isGranted);

      if (state.shouldRequestCallScreeningRole) {
        final roleResponse =
            await _methodChannel.invokeMapMethod<String, dynamic>(
              'requestCallScreeningRoleIfNeeded',
            ) ??
            const <String, dynamic>{};

        final roleRequestLaunched = roleResponse['roleRequestLaunched'] == true;
        final roleMessage =
            '${roleResponse['message'] ?? 'Call Screening role の状態を確認しました。'}';

        developer.log(
          roleMessage,
          name: 'IncomingCallBridge',
          error: roleRequestLaunched ? null : 'roleRequestLaunched=false',
        );

        return state.copyWith(
          callScreeningRoleRequested: roleRequestLaunched,
          statusMessage: '${state.statusMessage} $roleMessage',
        );
      }

      developer.log(
        state.statusMessage,
        name: 'IncomingCallBridge',
        error: state.monitoringActive
            ? null
            : 'monitoringActive=${state.monitoringActive}',
      );

      return state;
    } on MissingPluginException {
      return const IncomingCallMonitoringState(
        permissionGranted: false,
        contactsPermissionGranted: false,
        monitoringActive: false,
        callScreeningRoleGranted: false,
        statusMessage: 'ネイティブ着信監視プラグインが見つかりませんでした。',
      );
    } on PlatformException catch (error, stackTrace) {
      developer.log(
        '着信監視の初期化に失敗しました。',
        name: 'IncomingCallBridge',
        error: error,
        stackTrace: stackTrace,
      );

      return IncomingCallMonitoringState(
        permissionGranted: false,
        contactsPermissionGranted: false,
        monitoringActive: false,
        callScreeningRoleGranted: false,
        statusMessage: '着信監視の初期化に失敗しました: ${error.message}',
      );
    }
  }

  Future<PermissionStatus> _ensureContactsPermission() async {
    final currentStatus = await Permission.contacts.status;

    if (currentStatus.isGranted ||
        currentStatus.isPermanentlyDenied ||
        currentStatus.isRestricted ||
        currentStatus.isLimited) {
      return currentStatus;
    }

    if (_hasAttemptedContactsPermissionRequest) {
      return currentStatus;
    }

    _hasAttemptedContactsPermissionRequest = true;
    return Permission.contacts.request();
  }

  @override
  Stream<IncomingCallEvent> watchIncomingCalls() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const Stream<IncomingCallEvent>.empty();
    }

    return _eventChannel
        .receiveBroadcastStream()
        .map(
          (event) => IncomingCallEvent.fromMap(event as Map<Object?, Object?>),
        )
        .handleError((Object error, StackTrace stackTrace) {
          developer.log(
            '着信イベントの受信中にエラーが発生しました。',
            name: 'IncomingCallBridge',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }
}

class IncomingCallMonitoringState {
  const IncomingCallMonitoringState({
    required this.permissionGranted,
    required this.contactsPermissionGranted,
    required this.monitoringActive,
    required this.callScreeningRoleGranted,
    this.callScreeningRoleRequested = false,
    this.shouldRequestCallScreeningRole = false,
    this.source = 'unknown',
    required this.statusMessage,
  });

  final bool permissionGranted;
  final bool contactsPermissionGranted;
  final bool monitoringActive;
  final bool callScreeningRoleGranted;
  final bool callScreeningRoleRequested;
  final bool shouldRequestCallScreeningRole;
  final String source;
  final String statusMessage;

  factory IncomingCallMonitoringState.fromMap(Map<String, dynamic> raw) {
    return IncomingCallMonitoringState(
      permissionGranted: raw['permissionGranted'] == true,
      contactsPermissionGranted: raw['contactsPermissionGranted'] == true,
      monitoringActive: raw['monitoringActive'] == true,
      callScreeningRoleGranted: raw['callScreeningRoleGranted'] == true,
      shouldRequestCallScreeningRole:
          raw['shouldRequestCallScreeningRole'] == true,
      source: '${raw['source'] ?? 'unknown'}',
      statusMessage: '${raw['message'] ?? '着信監視の状態を取得しました。'}',
    );
  }

  IncomingCallMonitoringState copyWith({
    bool? permissionGranted,
    bool? contactsPermissionGranted,
    bool? monitoringActive,
    bool? callScreeningRoleGranted,
    bool? callScreeningRoleRequested,
    bool? shouldRequestCallScreeningRole,
    String? source,
    String? statusMessage,
  }) {
    return IncomingCallMonitoringState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      contactsPermissionGranted:
          contactsPermissionGranted ?? this.contactsPermissionGranted,
      monitoringActive: monitoringActive ?? this.monitoringActive,
      callScreeningRoleGranted:
          callScreeningRoleGranted ?? this.callScreeningRoleGranted,
      callScreeningRoleRequested:
          callScreeningRoleRequested ?? this.callScreeningRoleRequested,
      shouldRequestCallScreeningRole:
          shouldRequestCallScreeningRole ?? this.shouldRequestCallScreeningRole,
      source: source ?? this.source,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

final incomingCallBridgeProvider = Provider<IncomingCallBridge>((ref) {
  return AndroidIncomingCallBridge();
});
