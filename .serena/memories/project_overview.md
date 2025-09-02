# 重複ファイル検出ツール - プロジェクト概要

## プロジェクトの目的
GB単位の大容量ファイルを含む環境で効率的に重複ファイルを検出し、削除候補を提示するBashスクリプト集。

## 技術スタック
- **言語**: Bash (POSIX準拠)
- **依存関係**: 標準Unixコマンドのみ
  - `find`, `stat`, `sort`, `awk`
  - ハッシュコマンド: `sha256sum` または `md5sum`
- **要件**: Bash 4.0以上

## スクリプト一覧
### 1. duplicate_detector.sh - サイズ・ハッシュベース検出
- 同一サイズのファイルを検出（1MB以上のファイルのみ）
- 1MB部分ハッシュによる重複検出
- ファイル名類似度分析
- 4段階のタグ付けシステム (MOST-LIKELY, LIKELY, MOST-PROBABLY, PROBABLY)

### 2. filename_duplicate_detector.sh - ファイル名重複検出
- ファイル名が同じまたは類似しているが、サイズが異なるファイルを検出
- 完全一致ファイル名検出
- 拡張子を除いたベースネーム検出
- 4段階のタグ付けシステム (EXACT-NAME, SAME-BASE, SIMILAR-NAME, VARIANT)

## コードベース構造
```
.
├── duplicate_detector.sh          # サイズ・ハッシュベース検出
├── filename_duplicate_detector.sh # ファイル名重複検出
├── README.md                      # ドキュメント
├── .claude/                       # Claude設定
├── .serena/                       # Serena設定
└── .mcp.json                     # MCP設定
```

## 設計原則
- 軽量・ポータブル
- 安全性重視（削除は提示のみ）
- 段階的検出アルゴリズム
- スマートタグ付けシステム
- 独立したスクリプト設計