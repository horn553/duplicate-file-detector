#!/bin/bash

# ファイル名重複検出スクリプト - サイズ違いファイル名重複検出
# Usage: ./filename_duplicate_detector.sh [directory]

set -euo pipefail

# 設定
TARGET_DIR="${1:-.}"

# ディレクトリの存在確認
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist" >&2
    exit 1
fi

echo "=== Filename Duplicate Detector (Different Sizes) ==="
echo "Target Directory: $TARGET_DIR"
echo "Scanning for files with duplicate names but different sizes..."
echo

# 一時ファイル
TEMP_FILE=$(mktemp)
BASENAME_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE" "$BASENAME_FILE"' EXIT

# ファイルサイズ、パス、ベースネームの一覧を作成
find "$TARGET_DIR" -type f -exec stat -c "%s %n" {} \; | \
    while IFS=' ' read -r size path; do
        basename=$(basename "$path")
        echo "$size|$path|$basename"
    done > "$TEMP_FILE"

# ベースネームでグループ化し、同名異サイズのファイルを検出
echo "Files with duplicate names but different sizes:"
echo "=============================================="

awk -F'|' '
{
    size = $1
    path = $2
    basename = $3
    
    # 拡張子を除いたベースネームも計算
    basename_no_ext = basename
    gsub(/\.[^.]*$/, "", basename_no_ext)
    
    # 完全なベースネーム別にファイル情報を蓄積
    files[basename] = files[basename] size ":" path ":" basename "\n"
    count[basename]++
    unique_sizes[basename ":" size] = 1
    
    # 拡張子を除いたベースネーム別にも蓄積
    if (basename_no_ext != basename) {
        files_no_ext[basename_no_ext] = files_no_ext[basename_no_ext] size ":" path ":" basename "\n"
        count_no_ext[basename_no_ext]++
        unique_sizes_no_ext[basename_no_ext ":" size] = 1
    }
}
END {
    # 完全一致ファイル名の処理
    for (basename in count) {
        if (count[basename] > 1) {
            size_count = 0
            for (key in unique_sizes) {
                if (index(key, basename ":") == 1) {
                    size_count++
                }
            }
            
            if (size_count > 1) {
                printf "\nFilename: %s (%d files, different sizes)\n", basename, count[basename]
                process_file_group(files[basename])
            }
        }
    }
    
    # 拡張子を除いた同名ファイルの処理
    for (basename_no_ext in count_no_ext) {
        if (count_no_ext[basename_no_ext] > 1) {
            size_count = 0
            for (key in unique_sizes_no_ext) {
                if (index(key, basename_no_ext ":") == 1) {
                    size_count++
                }
            }
            
            if (size_count > 1) {
                # 既に完全一致で処理されたファイルは除外
                already_processed = 0
                split(files_no_ext[basename_no_ext], check_list, "\n")
                for (j in check_list) {
                    if (check_list[j] != "") {
                        split(check_list[j], parts, ":")
                        check_basename = parts[3]
                        if (count[check_basename] > 1) {
                            temp_size_count = 0
                            for (key in unique_sizes) {
                                if (index(key, check_basename ":") == 1) {
                                    temp_size_count++
                                }
                            }
                            if (temp_size_count > 1) {
                                already_processed = 1
                                break
                            }
                        }
                    }
                }
                
                if (!already_processed) {
                    printf "\nFilename group: %s* (%d files, different sizes)\n", basename_no_ext, count_no_ext[basename_no_ext]
                    process_file_group(files_no_ext[basename_no_ext])
                }
            }
        }
    }
}

function process_file_group(file_data) {
    split(file_data, file_list, "\n")
    
    for (i in file_list) {
        if (file_list[i] != "") {
            split(file_list[i], file_parts, ":")
            file_size = file_parts[1]
            file_path = file_parts[2]
            file_basename = file_parts[3]
            
            # サイズを人間が読みやすい形式に変換
            if (file_size >= 1073741824) {
                size_display = sprintf("%.1fGB", file_size / 1073741824)
            } else if (file_size >= 1048576) {
                size_display = sprintf("%.1fMB", file_size / 1048576)
            } else if (file_size >= 1024) {
                size_display = sprintf("%.1fKB", file_size / 1024)
            } else {
                size_display = file_size "B"
            }
            
            # タグを決定
            tag = get_filename_tag(file_path, file_basename)
            
            printf "%s [%s] Size: %s\n", file_path, tag, size_display
        }
    }
}

function get_filename_tag(filepath, target_basename) {
    # ファイルパスからベースネームを抽出
    gsub(/.*\//, "", filepath)
    current_basename = filepath
    
    # 完全一致
    if (current_basename == target_basename) {
        return "EXACT-NAME"
    }
    
    # 拡張子を除いたベースネームで比較
    gsub(/\.[^.]*$/, "", current_basename)
    target_no_ext = target_basename
    gsub(/\.[^.]*$/, "", target_no_ext)
    
    if (current_basename == target_no_ext) {
        return "SAME-BASE"
    }
    
    # 部分一致チェック
    if (index(current_basename, target_no_ext) > 0 || index(target_no_ext, current_basename) > 0) {
        return "SIMILAR-NAME"
    }
    
    # その他の類似パターン
    return "VARIANT"
}' "$TEMP_FILE"