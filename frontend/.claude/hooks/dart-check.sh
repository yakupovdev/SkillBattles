#!/usr/bin/env bash
# PostToolUse hook: formats and analyzes a .dart file right after Claude edits it.
# Exit code 2 sends the analyzer output back to Claude so it fixes the issues itself.

FILE=$(jq -r '.tool_input.file_path // empty')

# Only existing .dart files
[[ "$FILE" == *.dart && -f "$FILE" ]] || exit 0

# Skip generated code (owned by generators, see code_style.md)
case "$FILE" in
  *.g.dart|*.freezed.dart|*.gr.dart|*.config.dart|*.mocks.dart) exit 0 ;;
esac

dart format "$FILE" > /dev/null 2>&1

if ! OUTPUT=$(dart analyze "$FILE" 2>&1); then
  echo "dart analyze reported issues in $FILE:" >&2
  echo "$OUTPUT" >&2
  exit 2
fi

exit 0