# 重複ファイル検出ツール

GB単位の大容量ファイルを含む環境で効率的に重複ファイルを検出し、削除候補を提示するBashスクリプトです。

## 特徴

- **軽量**: Bashで実装、依存関係なし
- **精密**: 2段階の検出（ファイルサイズ → 1MBハッシュ）+ ファイル名類似度分析
- **安全**: 削除候補を提示のみ、実際の削除は行わない
- **ポータブル**: POSIX準拠、Linux/macOS対応
- **スマートタグ付け**: 重複可能性を4段階で分類

## インストール

### 直接実行（推奨）

```bash
# GitHubから直接実行
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/duplicate_detector.sh | bash -s -- /path/to/directory

# カレントディレクトリを検索
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/duplicate_detector.sh | bash
```

### ローカル保存

```bash
# スクリプトダウンロード
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/duplicate_detector.sh -o duplicate_detector.sh

# 実行権限付与
chmod +x duplicate_detector.sh
```

## 使用方法

### 基本的な使用法

```bash
# カレントディレクトリを検索
./duplicate_detector.sh

# 特定のディレクトリを検索
./duplicate_detector.sh /home/user/Documents
```

## 出力例

```
=== Duplicate File Detector (Size & Hash-based) ===
Target Directory: ./test_files
Hash Command: sha256sum
Scanning for files with identical sizes...

Files with identical sizes:
==========================

Size: 1048576 bytes (3 files)
/path/to/photo_original.jpg [MOST-LIKELY] Hash:a1b2c3d4
/path/to/photo_copy.jpg [MOST-LIKELY] Hash:a1b2c3d4
/path/to/different_photo.jpg [PROBABLY] Hash:e5f6789a

Size: 2097152 bytes (2 files)
/path/to/document.pdf [LIKELY] Hash:b2c3d4e5
/path/to/backup/document.pdf [LIKELY] Hash:b2c3d4e5
```

## タグの意味

- **MOST-LIKELY**: ハッシュ一致 + ファイル名部分一致（ほぼ確実に重複）
- **LIKELY**: ハッシュ一致のみ（高い確率で重複）
- **MOST-PROBABLY**: ファイル名完全一致のみ（同名ファイル）
- **PROBABLY**: ファイル名部分一致のみ（類似ファイル名）

## アルゴリズム

1. **ファイル収集**: `find`で対象ディレクトリを再帰検索
2. **サイズグルーピング**: 同じサイズのファイルをグループ化
3. **部分ハッシュ**: 先頭1MBをハッシュ化（sha256sum/md5sum）
4. **ファイル名分析**: ベースネームの完全一致・部分一致を判定
5. **スマートタグ付け**: ハッシュ一致とファイル名類似度を組み合わせて4段階でタグ付け
6. **結果出力**: ファイルパス、タグ、ハッシュ値（先頭8文字）を表示

## 設定

スクリプト内で以下の設定が可能です：

- **PARTIAL_READ_SIZE**: 1048576 (1MB) - 部分ハッシュ計算のサイズ
- **HASH_CMD**: sha256sum/md5sum - 環境に応じて自動選択

## 動作要件

- Bash 4.0以上
- 標準的なUnixコマンド: `find`, `stat`, `sort`, `awk`
- ハッシュコマンド: `sha256sum` または `md5sum`

## 実際の削除

スクリプトは重複候補を提示するのみです。実際の削除は手動で行うことを推奨します：

```bash
# 出力をファイルに保存
./duplicate_detector.sh /path/to/check > duplicates.txt

# MOST-LIKELYタグのファイルを確認
grep "MOST-LIKELY" duplicates.txt

# 慎重に手動削除
rm "/path/to/duplicate/file"
```

**注意**: 削除前に必ずバックアップを取り、特にMOST-LIKELYタグのファイルから確認してください。

## 開発

設計書: [design.md](design.md)

## ライセンス

MIT License