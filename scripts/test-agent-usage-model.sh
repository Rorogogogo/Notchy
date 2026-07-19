#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_BIN="$(mktemp /tmp/notchy-agent-usage-test.XXXXXX)"
TEST_CACHE="$(mktemp -d /tmp/notchy-swift-cache.XXXXXX)"
trap 'rm -f "$TEST_BIN"; rm -rf "$TEST_CACHE"' EXIT

swiftc \
  -module-cache-path "$TEST_CACHE" \
  "$ROOT/Sources/Notchy/Models/AgentUsageModel.swift" \
  "$ROOT/scripts/test-agent-usage-model.swift" \
  -o "$TEST_BIN"

"$TEST_BIN"
