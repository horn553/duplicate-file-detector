# 重複ファイル検出ツール

GB単位の大容量ファイルを含む環境で効率的に重複ファイルを検出し、削除候補を提示するBashスクリプトです。

## 特徴

- **軽量**: Bashで実装、依存関係なし
- **効率的**: 3段階の検出（サイズ → 部分ハッシュ → フルハッシュ）
- **安全**: 削除候補を提示のみ、実際の削除は行わない
- **ポータブル**: POSIX準拠、Linux/macOS対応
- **並列処理**: マルチコア環境で高速処理

## インストール

### 直接実行（推奨）

```bash
# GitHubから直接実行
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/detector.sh | bash -s -- /path/to/directory

# カレントディレクトリを検索
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/detector.sh | bash
```

### ローカル保存

```bash
# スクリプトダウンロード
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/detector.sh -o detector.sh

# 実行権限付与
chmod +x detector.sh
```

## 使用方法

### 基本的な使用法

```bash
# カレントディレクトリを検索
./detector.sh

# 特定のディレクトリを検索
./detector.sh /home/user/Documents

# ヘルプ表示
./detector.sh --help
```

### 環境変数での設定

```bash
# 部分ハッシュサイズを2MBに設定
PARTIAL_READ_SIZE=2097152 ./detector.sh /var/data
```

## 出力例

```json
{
  "groups": [
    {
      "hash": "a1b2c3d4e5f6789...",
      "size": 1048576,
      "files": [
        "/path/to/file1.jpg",
        "/path/to/file2.jpg",
        "/path/to/file3.jpg"
      ],
      "keep": "/path/to/file1.jpg",
      "delete_candidates": [
        "/path/to/file2.jpg",
        "/path/to/file3.jpg"
      ]
    }
  ]
}
```

## アルゴリズム

1. **ファイル収集**: `find`で対象ディレクトリを再帰検索
2. **サイズグルーピング**: 同じサイズのファイルをグループ化
3. **部分ハッシュ**: 先頭1MB（デフォルト）をハッシュ化して候補を絞る
4. **フルハッシュ**: 部分ハッシュが一致したファイルの全体をハッシュ化
5. **重複グループ化**: 完全に一致したファイルをグループ化
6. **削除候補選定**: 最新の更新日時のファイルを保持、それ以外を削除候補とする

## 設定

| 環境変数 | デフォルト | 説明 |
|---------|-----------|------|
| `PARTIAL_READ_SIZE` | 1048576 (1MB) | 部分ハッシュ計算のサイズ |

## 動作要件

- Bash 4.0以上
- 標準的なUnixコマンド: `find`, `stat`, `sort`, `awk`
- ハッシュコマンド: `sha256sum` または `md5sum`

## 実際の削除

スクリプトは削除候補を提示するのみです。実際の削除は以下のような方法で行います：

```bash
# 出力をファイルに保存
./detector.sh /path/to/check > duplicates.json

# jqで削除候補を抽出して削除
cat duplicates.json | jq -r '.groups[].delete_candidates[]' | while read file; do
    echo "削除: $file"
    rm "$file"
done
```

**注意**: 削除前に必ずバックアップを取り、結果を十分に確認してください。

## 開発

設計書: [design.md](design.md)

## ライセンス

MIT License