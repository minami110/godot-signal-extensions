#!/bin/bash

# gdUnit4 Test Wrapper Script
# Suppresses Godot logs and displays only failed tests

set -e

# スクリプトのディレクトリを取得してプロジェクトルートに移動
# これにより、どのディレクトリから実行されても正しく動作する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../../../"

# Godot 実行ファイルのパス（環境変数で上書き可能）
GODOT_CMD="${GODOT_PATH:-godot}"

# ヘルプメッセージを表示する関数
show_help() {
  cat << 'EOF'
Usage: ./run_test.sh [OPTIONS] [TARGET...]

OPTIONS:
  -v, --verbose    Show all Godot logs (default: suppress Godot logs)
  -h, --help       Show this help message

ARGUMENTS:
  TARGET...        Test file(s) or directory(ies) to run (default: tests/)
                   Multiple targets can be specified
                   Examples: tests/test_foo.gd, tests/application/

ENVIRONMENT VARIABLES:
  GODOT_PATH       Path to Godot executable (default: godot)
                   Example: GODOT_PATH=/usr/local/bin/godot ./run_test.sh

EXAMPLES:
  ./run_test.sh                              # Run all tests (quiet)
  ./run_test.sh tests/test_foo.gd            # Run specific test file
  ./run_test.sh tests/foo.gd tests/bar.gd    # Run multiple test files
  ./run_test.sh -v                           # Run all tests with verbose output
  ./run_test.sh -v tests/application/        # Run directory tests (verbose)
  ./run_test.sh tests/domain/ tests/app.gd   # Run directory and file
  GODOT_PATH=/custom/godot ./run_test.sh     # Use custom Godot path

EXIT CODES:
  0    All tests passed
  1    Some tests failed
  2    Error (e.g., report file not found)
EOF
}

# 引数解析
VERBOSE=false
TARGETS=()

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
      TARGETS+=("$1")
      shift
      ;;
  esac
done

# ターゲットが指定されていない場合のデフォルト
if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=("tests/")
fi

# テスト実行
echo "Running tests..."
echo ""

# 複数のターゲットを -a オプションとして追加
TARGET_ARGS=()
for target in "${TARGETS[@]}"; do
  TARGET_ARGS+=("-a" "$target")
done

# Godot を実行してテストを実行
set +e
if [ "$VERBOSE" = true ]; then
  # Verbose モード: すべてのログを表示
  $GODOT_CMD --headless -s -d addons/gdUnit4/bin/GdUnitCmdTool.gd \
    "${TARGET_ARGS[@]}" --ignoreHeadlessMode -c
  GODOT_EXIT_CODE=$?
else
  # 通常モード: Godot のログを抑制
  $GODOT_CMD --headless -s -d addons/gdUnit4/bin/GdUnitCmdTool.gd \
    "${TARGET_ARGS[@]}" --ignoreHeadlessMode -c > /dev/null 2>&1
  GODOT_EXIT_CODE=$?
fi
set -e

# 最新のレポートファイルを取得
LATEST_REPORT=$(ls -t reports/*/results.xml 2>/dev/null | head -1)

if [ -z "$LATEST_REPORT" ]; then
  echo "Error: Test report not found"
  exit 2
fi

# XML から情報を抽出
TOTAL_TESTS=$(grep -oP '<testsuites[^>]*tests="\K[0-9]+' "$LATEST_REPORT" || echo "0")
TOTAL_FAILURES=$(grep -oP '<testsuites[^>]*failures="\K[0-9]+' "$LATEST_REPORT" || echo "0")

# 結果を表示
echo "================================================="
if [ "$TOTAL_FAILURES" -eq 0 ]; then
  echo "ALL TESTS PASSED ($TOTAL_TESTS tests)"
  echo "================================================="
  echo ""
  exit 0
else
  echo "TEST FAILURES ($TOTAL_FAILURES of $TOTAL_TESTS tests failed)"
  echo "================================================="
  echo ""

  # 失敗したテストの詳細を抽出して表示
  FAILURE_COUNT=0

  # XML を行ごとに処理
  IN_FAILURE=false
  CURRENT_TESTCASE=""
  CURRENT_CLASSNAME=""
  CURRENT_MESSAGE=""
  CURRENT_CONTENT=""

  while IFS= read -r line; do
    # testcase タグの開始を検出
    if echo "$line" | grep -q '<testcase.*name='; then
      CURRENT_TESTCASE=$(echo "$line" | grep -oP 'name="\K[^"]+' || echo "")
      CURRENT_CLASSNAME=$(echo "$line" | grep -oP 'classname="\K[^"]+' || echo "")
    fi

    # failure タグの開始を検出
    if echo "$line" | grep -q '<failure'; then
      IN_FAILURE=true
      CURRENT_MESSAGE=$(echo "$line" | grep -oP 'message="\K[^"]+' || echo "")
    fi

    # failure の内容を収集
    if [ "$IN_FAILURE" = true ]; then
      CURRENT_CONTENT+="$line"

      # failure タグの終了を検出
      if echo "$line" | grep -q '</failure>'; then
        IN_FAILURE=false
        FAILURE_COUNT=$((FAILURE_COUNT + 1))

        # ファイルパスと行番号を抽出
        FILE_INFO=$(echo "$CURRENT_MESSAGE" | sed 's/FAILED: //' || echo "")

        # CDATA から期待値と実際の値を抽出
        EXPECTED=$(echo "$CURRENT_CONTENT" | grep -oP "Expecting:\s*'\K[^']*" || echo "")
        ACTUAL=$(echo "$CURRENT_CONTENT" | grep -oP "but was\s*'\K[^']*" || echo "")

        # 結果を表示
        echo "[$FAILURE_COUNT] $CURRENT_CLASSNAME :: $CURRENT_TESTCASE"
        if [ -n "$FILE_INFO" ]; then
          echo "    File: $FILE_INFO"
        fi
        if [ -n "$EXPECTED" ]; then
          echo "    Expected: '$EXPECTED'"
        fi
        if [ -n "$ACTUAL" ]; then
          echo "    Actual:   '$ACTUAL'"
        fi
        echo ""

        # リセット
        CURRENT_CONTENT=""
      fi
    fi
  done < "$LATEST_REPORT"

  echo "================================================="
  echo ""
  exit 1
fi
