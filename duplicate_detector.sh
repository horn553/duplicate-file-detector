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
            
            # ファイル名の類似度分析
            split(files[size], file_list, "\n")
            file_names = ""
            for (i in file_list) {
                if (file_list[i] != "") {
                    # ファイル名のみ抽出 (パスからベースネーム)
                    gsub(/.*\//, "", file_list[i])
                    file_names = file_names file_list[i] "|"
                }
            }
            
            # ファイル毎にタグ付けして出力
            split(files[size], file_list, "\n")
            for (i in file_list) {
                if (file_list[i] != "") {
                    tag = get_likelihood_tag(file_list[i], file_names)
                    printf "%s [%s]\n", file_list[i], tag
                }
            }
        }
    }
}

function get_likelihood_tag(filepath, all_names) {
    # ファイル名のみ抽出
    filename = filepath
    gsub(/.*\//, "", filename)
    
    # 他のファイル名との一致をチェック
    split(all_names, names, "|")
    exact_matches = 0
    partial_matches = 0
    
    for (j in names) {
        if (names[j] != "" && names[j] != filename) {
            if (names[j] == filename) {
                exact_matches++
            } else if (index(names[j], filename) > 0 || index(filename, names[j]) > 0) {
                partial_matches++
            }
        }
    }
    
    if (exact_matches > 0) {
        return "LIKELY"
    } else if (partial_matches > 0) {
        return "PROBABLY"
    } else {
        return "UNLIKELY"
    }
}' "$TEMP_FILE"