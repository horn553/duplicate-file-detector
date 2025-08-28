#!/bin/bash

# 重複ファイル検出スクリプト - 第1段階：同一サイズファイル検出
# Usage: ./duplicate_detector.sh [directory]

set -euo pipefail

# デフォルトディレクトリは現在のディレクトリ
TARGET_DIR="${1:-.}"

# ディレクトリの存在確認
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist" >&2
    exit 1
fi

echo "=== Duplicate File Detector (Size-based) ==="
echo "Target Directory: $TARGET_DIR"
echo "Scanning for files with identical sizes..."
echo

# 一時ファイル
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

# ファイルサイズとパスの一覧を作成
find "$TARGET_DIR" -type f -exec stat -c "%s %n" {} \; | sort -n > "$TEMP_FILE"

# 同一サイズのファイルをグループ化
echo "Files with identical sizes:"
echo "=========================="

awk '
{
    size = $1
    file = substr($0, index($0, " ") + 1)
    files[size] = files[size] file "\n"
    count[size]++
}
END {
    for (size in count) {
        if (count[size] > 1) {
            printf "\nSize: %d bytes (%d files)\n", size, count[size]
            printf "%s", files[size]
        }
    }
}' "$TEMP_FILE"