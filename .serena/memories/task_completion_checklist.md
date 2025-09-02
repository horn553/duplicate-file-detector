# タスク完了時のチェックリスト

## スクリプト開発完了時の確認項目

### 1. シンタックス検証
```bash
bash -n duplicate_detector.sh
bash -n filename_duplicate_detector.sh
```

### 2. 実行権限確認
```bash
chmod +x duplicate_detector.sh filename_duplicate_detector.sh
```

### 3. 基本動作テスト
```bash
# 両スクリプトをカレントディレクトリでテスト
./duplicate_detector.sh
./filename_duplicate_detector.sh

# 引数ありでのテスト
./duplicate_detector.sh /test/directory
./filename_duplicate_detector.sh /test/directory
```

### 4. エラーケーステスト
- 存在しないディレクトリの指定
- 権限のないディレクトリへのアクセス
- 空のディレクトリでの実行

### 5. 機能別テスト

#### duplicate_detector.sh
- 同一サイズファイルの検出
- ハッシュ値計算の動作
- タグ付けの正確性
- 1MB未満ファイルの除外

#### filename_duplicate_detector.sh  
- 完全一致ファイル名の検出
- 拡張子違いファイルの検出
- サイズ形式表示の確認
- タグ付けの正確性

### 6. POSIX準拠確認
- Bashism の回避
- 標準コマンドのみ使用
- ポータビリティの確保

### 7. ドキュメント更新
- README.md の更新（必要に応じて）
- コメントの適切性確認
- 使用例の動作確認

## 品質基準
- エラーハンドリングの実装
- 一時ファイルのクリーンアップ
- 適切な出力フォーマット
- セキュリティ（パスインジェクション対策）
- 両スクリプトの独立性維持