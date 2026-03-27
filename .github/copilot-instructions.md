# オレオレ誰？ 開発ガイドライン（GitHub Copilot用）

## プロジェクト概要
高齢者向けオレオレ詐欺防止アプリ。家族が主導でインストール・設定・監視する。
高齢者側UIは極力シンプル（文字大、音声ガイド重視）。家族側UIは40-50代向け（デジタル慣れ層も初心者も使いやすい）。

## 必須参照ファイル
- PRODUCT.md（要件定義）
- ARCHITECTURE.md（技術スタック、Mermaid図、DB設計、API、ワイヤーフレーム）
- モックアップ画像（高齢者ホーム、設定、着信オーバーレイ、家族ダッシュボード）

## 技術スタック（厳守）
- Flutter 3.41以上 + Dart 3.x
- 状態管理：Riverpod 2.x（notifier + async）
- 通話制御：Android → CallScreeningService / iOS → CallKit
- 端末内AI：whisper.cpp / Gemma-2B Q4 / TFLite（後でプラグイン統合）
- バックエンド：Supabase
- UI原則：フォント最小18px（推奨24px）、タップ領域60px以上、コントラスト7:1、音声ガイド（flutter_tts）

## コーディングルール
- 常に高齢者UXを優先：大きなボタン、シンプルなナビゲーション
- ファイル構造はClean Architecture風（presentation / domain / data）
- コメントは日本語可（Copilotに指示を明確に）
- 1機能ずつ実装。大きな変更は「// TODO:」で区切ってからCopilotに聞く

Copilotに指示するときは「ARCHITECTURE.mdとPRODUCT.mdを参照して」と必ず入れる。
