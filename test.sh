#!/usr/bin/env bash
set -e

PASS=0
FAIL=0

# Create clean temp directories
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/workspace" "$TEST_DIR/claude"
trap 'rm -rf "$TEST_DIR"' EXIT

export WORKSPACE="$TEST_DIR/workspace"
export CLAUDE_CONFIG_DIR="$TEST_DIR/claude"
export CLAUDE_CREDENTIALS_FILE="${CLAUDE_CREDENTIALS_FILE:-$HOME/.claude/.credentials.json}"

run_test() {
  local name="$1"
  shift
  printf "  %-40s" "$name"
  if output=$("$@" 2>&1); then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    echo "    $output" | head -5
    FAIL=$((FAIL + 1))
  fi
}

run_test "claude --version" \
  docker compose -f compose.example.yml run --rm -T claude --version

run_test "claude completes a prompt" \
  docker compose -f compose.example.yml run --rm -T claude -p "Reply with exactly: hello"

run_test "cannot write to root filesystem" \
  bash -c '! docker compose -f compose.example.yml run --rm -T --entrypoint "" claude bash -c "touch /usr/local/hack"'

run_test "cannot escalate privileges" \
  bash -c '! docker compose -f compose.example.yml run --rm -T --entrypoint "" claude bash -c "sudo echo test"'

echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
