#!/bin/bash

# 重複ファイル検出スクリプト
# 使用方法: ./detector.sh [TARGET_DIR]

set -euo pipefail

# 設定
PARTIAL_READ_SIZE=${PARTIAL_READ_SIZE:-1048576}  # 1MB
TARGET_DIR="${1:-.}"
TEMP_DIR="/tmp/duplicate_detector_$$"

# 利用可能なハッシュコマンドを検出
detect_hash_command() {
    if command -v sha256sum >/dev/null 2>&1; then
        HASH_CMD="sha256sum"
    elif command -v md5sum >/dev/null 2>&1; then
        HASH_CMD="md5sum"
    else
        echo "Error: sha256sum も md5sum も見つかりません" >&2
        exit 1
    fi
}

# 使用方法
usage() {
    cat << 'EOF'
使用方法: ./detector.sh [TARGET_DIR]

重複ファイル検出・削除候補提示ツール

引数:
    TARGET_DIR    検索対象ディレクトリ（デフォルト: カレントディレクトリ）

環境変数:
    PARTIAL_READ_SIZE    部分ハッシュ計算サイズ（デフォルト: 1MB = 1048576）

例:
    ./detector.sh /home/user/Documents
    PARTIAL_READ_SIZE=2097152 ./detector.sh /var/data

出力: テキスト形式で重複グループと削除候補を表示

GitHubから直接実行:
    curl -sSL https://raw.githubusercontent.com/user/repo/main/detector.sh | bash -s -- /path/to/dir
EOF
}

# 一時ディレクトリ作成とクリーンアップ
setup_temp() {
    mkdir -p "$TEMP_DIR"
    trap "rm -rf '$TEMP_DIR'" EXIT INT TERM
}

# 部分ハッシュ計算
calculate_partial_hash() {
    local filepath="$1"
    if [[ -r "$filepath" ]]; then
        head -c "$PARTIAL_READ_SIZE" "$filepath" 2>/dev/null | $HASH_CMD | cut -d' ' -f1
    fi
}

# 全体ハッシュ計算
calculate_full_hash() {
    local filepath="$1"
    if [[ -r "$filepath" ]]; then
        $HASH_CMD "$filepath" 2>/dev/null | cut -d' ' -f1
    fi
}

# ファイル情報を人間が読める形式に変換
format_size() {
    local size="$1"
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "${size} bytes"
    else
        echo "${size} bytes"
    fi
}

format_date() {
    local timestamp="$1"
    date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || \
    date -r "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || \
    echo "不明"
}

# メイン処理
main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi
    
    if [[ ! -d "$TARGET_DIR" ]]; then
        echo "❌ ディレクトリが存在しません: '$TARGET_DIR'" >&2
        exit 1
    fi
    
    detect_hash_command
    setup_temp
    
    echo "🚀 重複ファイル検出開始" >&2
    echo "📂 対象ディレクトリ: $TARGET_DIR" >&2
    echo "🔐 ハッシュアルゴリズム: $HASH_CMD" >&2
    echo "📏 部分読み込みサイズ: $(format_size $PARTIAL_READ_SIZE)" >&2
    echo "" >&2
    
    # ステップ1: ファイル収集・サイズ計算
    echo "📁 ファイル収集中..." >&2
    find "$TARGET_DIR" -type f -exec stat -c '%s %Y %n' {} \; 2>/dev/null | \
        sort -n > "$TEMP_DIR/file_list" || {
        # macOS対応
        find "$TARGET_DIR" -type f -exec stat -f '%z %m %N' {} \; 2>/dev/null | \
            sort -n > "$TEMP_DIR/file_list"
    }
    
    # ステップ2: サイズ重複チェック
    echo "📊 サイズ重複チェック中..." >&2
    awk '{size[$1]++; files[$1] = files[$1] $0 "\n"} 
         END {for(s in size) if(size[s]>1) print files[s]}' \
        "$TEMP_DIR/file_list" > "$TEMP_DIR/size_duplicates"
    
    if [[ ! -s "$TEMP_DIR/size_duplicates" ]]; then
        echo "" >&2
        echo "✅ 検出完了" >&2
        echo ""
        echo "✨ 重複ファイルは見つかりませんでした。"
        return
    fi
    
    # ステップ3: 部分ハッシュ計算
    echo "🔍 部分ハッシュ計算中..." >&2
    while read -r line; do
        [[ -n "$line" ]] || continue
        read -r size mtime filepath <<< "$line"
        
        if [[ -r "$filepath" ]]; then
            local partial_hash
            if partial_hash=$(calculate_partial_hash "$filepath"); then
                echo "$size $partial_hash $mtime $filepath" >> "$TEMP_DIR/partial_hashes"
            fi
        fi
    done < "$TEMP_DIR/size_duplicates"
    
    # 部分ハッシュでグルーピング
    sort "$TEMP_DIR/partial_hashes" | \
        awk '{key=$1"_"$2; count[key]++; data[key] = data[key] $0 "\n"} 
             END {for(k in count) if(count[k]>1) print data[k]}' > "$TEMP_DIR/partial_groups"
    
    if [[ ! -s "$TEMP_DIR/partial_groups" ]]; then
        echo "" >&2
        echo "✅ 検出完了" >&2
        echo ""
        echo "✨ 重複ファイルは見つかりませんでした。"
        return
    fi
    
    # ステップ4: フルハッシュ計算
    echo "🎯 フルハッシュ計算中..." >&2
    while read -r line; do
        [[ -n "$line" ]] || continue
        read -r size partial_hash mtime filepath <<< "$line"
        
        if [[ -r "$filepath" ]]; then
            local full_hash
            if full_hash=$(calculate_full_hash "$filepath"); then
                echo "$full_hash $size $mtime $filepath" >> "$TEMP_DIR/full_hashes"
            fi
        fi
    done < "$TEMP_DIR/partial_groups"
    
    # フルハッシュでグルーピング
    sort "$TEMP_DIR/full_hashes" | \
        awk '{count[$1]++; data[$1] = data[$1] $0 "\n"} 
             END {for(h in count) if(count[h]>1) print data[h]}' > "$TEMP_DIR/final_groups"
    
    # ステップ5: 結果出力
    echo "📋 結果生成中..." >&2
    
    local group_count=0
    local total_duplicates=0
    local total_waste=0
    
    while read -r group_data; do
        [[ -n "$group_data" ]] || continue
        
        local files=()
        local mtimes=()
        local hash=""
        local size=0
        
        # グループ内の各ファイルを解析
        while read -r line; do
            [[ -n "$line" ]] || continue
            read -r file_hash file_size mtime filepath <<< "$line"
            
            files+=("$filepath")
            mtimes+=("$mtime")
            
            if [[ -z "$hash" ]]; then
                hash="$file_hash"
                size="$file_size"
            fi
        done <<< "$group_data"
        
        # 2つ以上のファイルがある場合のみ処理
        if [[ ${#files[@]} -gt 1 ]]; then
            ((group_count++))
            total_duplicates=$((total_duplicates + ${#files[@]} - 1))
            total_waste=$((total_waste + size * (${#files[@]} - 1)))
            
            # 最新ファイルを特定
            local newest_idx=0
            local newest_mtime="${mtimes[0]}"
            
            for ((i=1; i<${#mtimes[@]}; i++)); do
                if [[ "${mtimes[i]}" > "$newest_mtime" ]]; then
                    newest_mtime="${mtimes[i]}"
                    newest_idx=$i
                fi
            done
            
            echo ""
            echo "━━━ 重複グループ $group_count ━━━"
            echo "ファイルサイズ: $(format_size $size)"
            echo "ハッシュ: $hash"
            echo ""
            
            echo "📂 重複ファイル一覧:"
            for ((i=0; i<${#files[@]}; i++)); do
                local date_str
                date_str=$(format_date "${mtimes[i]}")
                
                if [[ $i -eq $newest_idx ]]; then
                    echo "  ✅ [保持] ${files[i]} ($date_str)"
                else
                    echo "  ❌ [削除候補] ${files[i]} ($date_str)"
                fi
            done
            
            echo ""
            echo "🗑️  削除コマンド例:"
            for ((i=0; i<${#files[@]}; i++)); do
                if [[ $i -ne $newest_idx ]]; then
                    echo "rm \"${files[i]}\""
                fi
            done
        fi
    done < <(awk 'BEGIN{RS="\n\n"} NF>0' "$TEMP_DIR/final_groups")
    
    echo ""
    echo "📊 検出結果サマリー:"
    echo "  重複グループ数: $group_count"
    echo "  削除可能ファイル数: $total_duplicates"
    echo "  節約可能容量: $(format_size $total_waste)"
    
    echo "" >&2
    echo "✅ 検出完了" >&2
}

main "$@"