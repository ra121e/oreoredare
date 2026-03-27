import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../features/elderly/domain/elderly_home_summary.dart';

/// TTS 実体の provider。
/// 画面ごとに作り直さず、Riverpod から共通利用できる形にしておく。
final flutterTtsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();

  ref.onDispose(() {
    unawaited(tts.stop());
  });

  return tts;
});

/// 音声ガイド制御の provider。
final voiceGuideControllerProvider = Provider<VoiceGuideController>((ref) {
  return VoiceGuideController(ref.watch(flutterTtsProvider));
});

/// 高齢者向けのゆっくりした読み上げを担当するクラス。
class VoiceGuideController {
  VoiceGuideController(this._tts);

  final FlutterTts _tts;
  bool _isPrepared = false;
  bool _isAvailable = true;

  Future<void> prepare() async {
    if (_isPrepared || !_isAvailable) {
      return;
    }

    try {
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.4);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      _isPrepared = true;
    } catch (_) {
      // テスト環境や未対応端末では TTS が使えないため、読み上げを静かに無効化する。
      _isAvailable = false;
    }
  }

  Future<void> announceHome(ElderlyHomeSummary summary) async {
    await speak(summary.voiceGuideMessage);
  }

  Future<void> announceAction(String message) async {
    await speak(message);
  }

  Future<void> speak(String message) async {
    if (!_isAvailable) {
      return;
    }

    await prepare();

    if (!_isAvailable) {
      return;
    }

    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {
      _isAvailable = false;
    }
  }

  Future<void> stop() async {
    if (!_isAvailable) {
      return;
    }

    try {
      await _tts.stop();
    } catch (_) {
      _isAvailable = false;
    }
  }
}
