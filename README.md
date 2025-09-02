# 重複ファイル検出ツール

GB単位の大容量ファイルを含む環境で効率的に重複ファイルを検出し、削除候補を提示するBashスクリプト集です。

## スクリプト一覧

### 1. duplicate_detector.sh - サイズ・ハッシュベース検出
同一サイズのファイルを検出し、ハッシュ値で重複を判定

### 2. filename_duplicate_detector.sh - ファイル名重複検出
ファイル名が同じまたは類似しているが、サイズが異なるファイルを検出

## 特徴

- **軽量**: Bashで実装、依存関係なし
- **精密**: 2段階の検出（ファイルサイズ → 1MBハッシュ）+ ファイル名類似度分析
- **安全**: 削除候補を提示のみ、実際の削除は行わない
- **ポータブル**: POSIX準拠、Linux/macOS対応
- **スマートタグ付け**: 重複可能性を4段階で分類

## インストール

### 直接実行（推奨）

```bash
# duplicate_detector.sh をGitHubから直接実行
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/duplicate_detector.sh | bash -s -- /path/to/directory

# filename_duplicate_detector.sh をGitHubから直接実行
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/filename_duplicate_detector.sh | bash -s -- /path/to/directory

# カレントディレクトリを検索
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/duplicate_detector.sh | bash
```

### ローカル保存

```bash
# スクリプトダウンロード
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/duplicate_detector.sh -o duplicate_detector.sh
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/filename_duplicate_detector.sh -o filename_duplicate_detector.sh

# 実行権限付与
chmod +x duplicate_detector.sh filename_duplicate_detector.sh
```

## 使用方法

### duplicate_detector.sh - サイズ・ハッシュベース検出

```bash
# カレントディレクトリを検索
./duplicate_detector.sh

# 特定のディレクトリを検索
./duplicate_detector.sh /home/user/Documents
```

### filename_duplicate_detector.sh - ファイル名重複検出

```bash
# カレントディレクトリを検索
./filename_duplicate_detector.sh

# 特定のディレクトリを検索
./filename_duplicate_detector.sh /home/user/Documents
```

## 出力例

### duplicate_detector.sh の出力

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

### filename_duplicate_detector.sh の出力

```
=== Filename Duplicate Detector (Different Sizes) ===
Target Directory: ./test_files
Scanning for files with duplicate names but different sizes...

Files with duplicate names but different sizes:
==============================================

Filename: document.pdf (2 files, different sizes)
./test_files/document.pdf [EXACT-NAME] Size: 6B
./test_files/subdir/document.pdf [EXACT-NAME] Size: 20B

Filename group: photo* (2 files, different sizes)
./test_files/photo.jpg [EXACT-NAME] Size: 6B
./test_files/photo.jpeg [EXACT-NAME] Size: 20B
```

## タグの意味

### duplicate_detector.sh のタグ

- **MOST-LIKELY**: ハッシュ一致 + ファイル名部分一致（ほぼ確実に重複）
- **LIKELY**: ハッシュ一致のみ（高い確率で重複）
- **MOST-PROBABLY**: ファイル名完全一致のみ（同名ファイル）
- **PROBABLY**: ファイル名部分一致のみ（類似ファイル名）

### filename_duplicate_detector.sh のタグ

- **EXACT-NAME**: 完全同一ファイル名
- **SAME-BASE**: 拡張子のみ異なる（例: photo.jpg と photo.png）
- **SIMILAR-NAME**: 部分的に類似するファイル名
- **VARIANT**: その他の類似パターン

## アルゴリズム

### duplicate_detector.sh のアルゴリズム

1. **ファイル収集**: `find`で対象ディレクトリを再帰検索
2. **サイズグルーピング**: 同じサイズのファイルをグループ化（1MB以上のファイルのみ）
3. **部分ハッシュ**: 先頭1MBをハッシュ化（sha256sum/md5sum）
4. **ファイル名分析**: ベースネームの完全一致・部分一致を判定
5. **スマートタグ付け**: ハッシュ一致とファイル名類似度を組み合わせて4段階でタグ付け
6. **結果出力**: ファイルパス、タグ、ハッシュ値（先頭8文字）を表示

### filename_duplicate_detector.sh のアルゴリズム

1. **ファイル収集**: `find`で対象ディレクトリを再帰検索
2. **ベースネームグルーピング**: 
   - 完全一致ファイル名でグループ化
   - 拡張子を除いたベースネームでもグループ化
3. **サイズ差分チェック**: 同グループ内で異なるサイズのファイルを特定
4. **タグ付け**: ファイル名の一致パターンに基づいて4段階でタグ付け
5. **結果出力**: ファイルパス、タグ、人間が読みやすいサイズ形式で表示

## 設定

スクリプト内で以下の設定が可能です：

- **PARTIAL_READ_SIZE**: 1048576 (1MB) - 部分ハッシュ計算のサイズ
- **HASH_CMD**: sha256sum/md5sum - 環境に応じて自動選択

## 動作要件

- Bash 4.0以上
- 標準的なUnixコマンド: `find`, `stat`, `sort`, `awk`
- ハッシュコマンド: `sha256sum` または `md5sum`

## 実際の削除

両スクリプトとも重複候補を提示するのみです。実際の削除は手動で行うことを推奨します：

### duplicate_detector.sh の場合

```bash
# 出力をファイルに保存
./duplicate_detector.sh /path/to/check > duplicates.txt

# MOST-LIKELYタグのファイルを確認
grep "MOST-LIKELY" duplicates.txt

# 慎重に手動削除
rm "/path/to/duplicate/file"
```

### filename_duplicate_detector.sh の場合

```bash
# 出力をファイルに保存
./filename_duplicate_detector.sh /path/to/check > filename_duplicates.txt

# 完全一致ファイル名の確認
grep "EXACT-NAME" filename_duplicates.txt

# サイズの大きいファイルのみ残すなど、慎重に削除
rm "/path/to/smaller/duplicate/file"
```

**注意**: 削除前に必ずバックアップを取り、ファイルの内容を確認してから削除してください。特に異なるサイズのファイルは内容が異なる可能性があります。

## 開発

設計書: [design.md](design.md)

## ライセンス

MIT License