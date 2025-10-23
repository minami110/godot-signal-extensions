#!/bin/bash

# Godot Language Server Refresh Script
# Run after creating/editing new GDScript classes to update project cache

set -e

# Godot 実行ファイルのパス（環境変数で上書き可能）
GODOT_CMD="${GODOT_PATH:-godot}"

# ヘルプメッセージを表示する関数
show_help() {
  cat << 'EOF'
Usage: ./refresh_godot_lsp.sh [OPTIONS]

OPTIONS:
  -v, --verbose    Show all Godot logs (default: suppress most logs)
  -h, --help       Show this help message

DESCRIPTION:
  This script updates Godot's project cache
  (.godot/global_script_class_cache.cfg) after creating/editing new
  GDScript classes. This allows the language server (LSP) to recognize
  new classes.

ENVIRONMENT VARIABLES:
  GODOT_PATH       Path to Godot executable (default: godot)
                   Example: GODOT_PATH=/usr/local/bin/godot ./refresh_godot_lsp.sh

EXAMPLES:
  ./refresh_godot_lsp.sh              # Update cache (quiet)
  ./refresh_godot_lsp.sh -v           # Update cache (verbose logs)

TYPICAL WORKFLOW:
  # 1. Create/edit new classes
  # 2. Update cache
  ./refresh_godot_lsp.sh
  # 3. Check diagnostics (automatically run in IDEs like VSCode)

EXIT CODES:
  0    Success
  1    Error

TROUBLESHOOTING:
  After running this script, diagnostics may show errors:

  A. Real errors - Fix them:
     - UNUSED_PARAMETER: Add '_' prefix to parameter name
     - TYPE_MISMATCH, syntax errors: Fix your code

  B. False positives - Can ignore:
     If all are true: (1) code is correct, (2) error after changing method
     signatures, (3) error like "wrong argument count"

     Cause: VSCode LSP may not reload Godot cache immediately.
     Solution: Ignore (resolves after IDE restart) or manually restart LSP
     via Command Palette: "Godot Tools: Stop/Start Language Server"
EOF
}

# 引数解析
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information."
      exit 1
      ;;
  esac
done

echo "Refreshing Godot language server cache..."
echo ""

# キャッシュファイルのパス
CACHE_FILE=".godot/global_script_class_cache.cfg"

# 既存のキャッシュファイルを削除
if [ -f "$CACHE_FILE" ]; then
  if [ "$VERBOSE" = true ]; then
    echo "Removing existing cache file: $CACHE_FILE"
  fi
  rm -f "$CACHE_FILE"
fi

# Godot を実行してプロジェクトキャッシュを更新
set +e
if [ "$VERBOSE" = true ]; then
  # Verbose モード: すべてのログを表示
  $GODOT_CMD --headless --import --quit
  GODOT_EXIT_CODE=$?
else
  # 通常モード: 重要なメッセージのみ表示（エラーとクラス登録）
  $GODOT_CMD --headless --import --quit 2>&1 | grep -E "(ERROR|SCRIPT ERROR|update_scripts_classes|TestLsp)"
  GODOT_EXIT_CODE=$?
fi
set -e

echo ""
echo "================================================="
echo "Language server cache refreshed successfully!"
echo "================================================="
echo ""

exit 0
