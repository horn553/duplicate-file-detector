# 推奨コマンド集

## 開発・実行コマンド

### duplicate_detector.sh - サイズ・ハッシュベース検出
```bash
# カレントディレクトリを検索
./duplicate_detector.sh

# 特定ディレクトリを検索
./duplicate_detector.sh /path/to/directory

# 実行権限付与
chmod +x duplicate_detector.sh
```

### filename_duplicate_detector.sh - ファイル名重複検出
```bash
# カレントディレクトリを検索
./filename_duplicate_detector.sh

# 特定ディレクトリを検索
./filename_duplicate_detector.sh /path/to/directory

# 実行権限付与
chmod +x filename_duplicate_detector.sh
```

### テスト・検証
```bash
# 両スクリプトのシンタックスチェック
bash -n duplicate_detector.sh
bash -n filename_duplicate_detector.sh

# テストディレクトリでの動作確認
mkdir -p test_files
./duplicate_detector.sh test_files
./filename_duplicate_detector.sh test_files
```

### 出力管理
```bash
# 結果をファイルに保存
./duplicate_detector.sh /path/to/check > duplicates.txt
./filename_duplicate_detector.sh /path/to/check > filename_duplicates.txt

# 特定タグのみフィルタ
grep "MOST-LIKELY" duplicates.txt
grep "EXACT-NAME" filename_duplicates.txt
```

## GitHubからの直接実行
```bash
# duplicate_detector.sh
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/duplicate_detector.sh | bash -s -- /path/to/directory

# filename_duplicate_detector.sh
curl -sSL https://raw.githubusercontent.com/horn553/duplicate-file-detector/main/filename_duplicate_detector.sh | bash -s -- /path/to/directory
```

## システムコマンド（Linux）
- `find` - ファイル検索
- `stat -c "%s %n"` - ファイルサイズ取得
- `head -c SIZE` - 部分読み取り
- `sha256sum` / `md5sum` - ハッシュ計算
- `mktemp` - 一時ファイル作成
- `sort -n` - 数値ソート
- `basename` - ベースネーム抽出

## Git操作
```bash
git add .
git commit -m "commit message"
git status
```