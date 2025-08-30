#!/bin/bash

# 重複ファイル検出スクリプト - サイズ・ハッシュベース検出
# Usage: ./duplicate_detector.sh [directory]

set -euo pipefail

# 設定
PARTIAL_READ_SIZE=1048576  # 1MB
TARGET_DIR="${1:-.}"

# ハッシュコマンドの自動検出
if command -v sha256sum >/dev/null 2>&1; then
    HASH_CMD="sha256sum"
elif command -v md5sum >/dev/null 2>&1; then
    HASH_CMD="md5sum"
else
    echo "Error: Neither sha256sum nor md5sum found" >&2
    exit 1
fi

# ディレクトリの存在確認
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist" >&2
    exit 1
fi

echo "=== Duplicate File Detector (Size & Hash-based) ==="
echo "Target Directory: $TARGET_DIR"
echo "Hash Command: $HASH_CMD"
echo "Scanning for files with identical sizes..."
echo

# 一時ファイル
TEMP_FILE=$(mktemp)
HASH_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE" "$HASH_FILE"' EXIT

# ファイルサイズとパスの一覧を作成
find "$TARGET_DIR" -type f -exec stat -c "%s %n" {} \; | sort -n > "$TEMP_FILE"

# 同一サイズのファイルをグループ化
echo "Files with identical sizes:"
echo "=========================="

# 同一サイズファイルのハッシュ計算とタグ付け
awk -v hash_cmd="$HASH_CMD" -v partial_size="$PARTIAL_READ_SIZE" '
{
    size = $1
    file = substr($0, index($0, " ") + 1)
    files[size] = files[size] file "\n"
    count[size]++
}
END {
    for (size in count) {
        if (count[size] > 1 && size >= 1048576) {
            printf "\nSize: %d bytes (%d files)\n", size, count[size]
            
            # ファイルリストを作成してハッシュ計算
            split(files[size], file_list, "\n")
            file_hashes = ""
            file_names = ""
            
            for (i in file_list) {
                if (file_list[i] != "") {
                    # ハッシュ値計算
                    cmd = "head -c " partial_size " \"" file_list[i] "\" 2>/dev/null | " hash_cmd " | cut -d\" \" -f1"
                    cmd | getline hash_value
                    close(cmd)
                    if (hash_value == "") hash_value = "ERROR"
                    
                    file_hashes = file_hashes file_list[i] "|" hash_value "\n"
                    
                    # ファイル名のみ抽出
                    filename = file_list[i]
                    gsub(/.*\//, "", filename)
                    file_names = file_names filename "|"
                }
            }
            
            # ファイル毎にタグ付けして出力
            split(files[size], file_list, "\n")
            for (i in file_list) {
                if (file_list[i] != "") {
                    # このファイルのハッシュ値を取得
                    cmd = "head -c " partial_size " \"" file_list[i] "\" 2>/dev/null | " hash_cmd " | cut -d\" \" -f1"
                    cmd | getline current_hash
                    close(cmd)
                    if (current_hash == "") current_hash = "ERROR"
                    
                    tag = get_likelihood_tag(file_list[i], file_names, file_hashes, current_hash)
                    hash_short = substr(current_hash, 1, 8)
                    printf "%s [%s] Hash:%s\n", file_list[i], tag, hash_short
                }
            }
        }
    }
}

function get_likelihood_tag(filepath, all_names, all_hashes, current_hash) {
    # ファイル名のみ抽出
    filename = filepath
    gsub(/.*\//, "", filename)
    
    # ファイル名の一致をチェック
    split(all_names, names, "|")
    exact_name_match = 0
    partial_name_match = 0
    
    for (j in names) {
        if (names[j] != "" && names[j] != filename) {
            if (names[j] == filename) {
                exact_name_match = 1
            } else if (index(names[j], filename) > 0 || index(filename, names[j]) > 0) {
                partial_name_match = 1
            }
        }
    }
    
    # ハッシュの一致をチェック
    hash_match = 0
    split(all_hashes, hash_lines, "\n")
    for (k in hash_lines) {
        if (hash_lines[k] != "") {
            split(hash_lines[k], hash_parts, "|")
            if (hash_parts[1] != filepath && hash_parts[2] == current_hash && current_hash != "ERROR") {
                hash_match = 1
                break
            }
        }
    }
    
    # タグ決定
    if (hash_match && partial_name_match) {
        return "MOST-LIKELY"
    } else if (hash_match) {
        return "LIKELY"
    } else if (exact_name_match) {
        return "MOST-PROBABLY"
    } else if (partial_name_match) {
        return "PROBABLY"
    } else {
        return "POSSIBLE"
    }
}' "$TEMP_FILE"