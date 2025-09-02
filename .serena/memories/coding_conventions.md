# コーディング規約と設計パターン

## Bashスクリプト規約
- `#!/bin/bash` shebang使用
- `set -euo pipefail` でエラーハンドリング強化
- 変数は大文字で定義 (例: `PARTIAL_READ_SIZE`, `TARGET_DIR`)
- 一時ファイルは`mktemp`で作成、`trap`でクリーンアップ

## 設計パターン
### エラーハンドリング
```bash
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist" >&2
    exit 1
fi
```

### 自動検出パターン
```bash
if command -v sha256sum >/dev/null 2>&1; then
    HASH_CMD="sha256sum"
elif command -v md5sum >/dev/null 2>&1; then
    HASH_CMD="md5sum"
fi
```

### AWKとBashの連携
- 複雑なデータ処理はAWKで実装
- ファイル操作は Bash で実行
- パイプラインで連携

## 出力フォーマット
- セクション区切り: `===` と `====`
- タグ形式: `[TAG-NAME]`
- ハッシュ表示: 先頭8文字のみ

## 命名規約
- スクリプト名: `action_target_detector.sh`
- 関数名: `snake_case`
- タグ名: `UPPER-CASE` (ハイフン区切り)