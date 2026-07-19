#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

SESSION_DIR="$TMP_HOME/.codex/sessions/2026/05/16"
BIN_DIR="$TMP_HOME/bin"
mkdir -p "$SESSION_DIR" "$BIN_DIR"

cat > "$BIN_DIR/codex" <<'SH'
#!/bin/bash
set -euo pipefail
read -r initialize_request
printf '%s\n' '{"id":1,"result":{"userAgent":"notchy-test","codexHome":"/tmp/test","platformFamily":"unix","platformOs":"macos"}}'
read -r rate_limits_request
printf '%s\n' '{"id":2,"result":{"rateLimits":{"limitId":"codex","limitName":null,"primary":{"usedPercent":83.0,"windowDurationMins":10080,"resetsAt":1784988328},"secondary":null,"credits":{"hasCredits":false,"unlimited":false,"balance":"0"},"individualLimit":null,"planType":"plus","rateLimitReachedType":null},"rateLimitsByLimitId":null,"rateLimitResetCredits":{"availableCount":3,"credits":[{"id":"one","resetType":"codexRateLimits","status":"available","grantedAt":1782517621,"expiresAt":1785109621,"title":"Full reset","description":null},{"id":"two","resetType":"codexRateLimits","status":"available","grantedAt":1782936759,"expiresAt":1785528759,"title":"Full reset","description":null},{"id":"three","resetType":"codexRateLimits","status":"available","grantedAt":1783964833,"expiresAt":1786556833,"title":"Full reset","description":null}]}}}'
SH
chmod +x "$BIN_DIR/codex"

cat > "$SESSION_DIR/old.jsonl" <<'JSONL'
{"timestamp":"2026-05-16T00:00:00.000Z","type":"event_msg","payload":{"type":"token_count"},"rate_limits":{"primary":{"used_percent":11.0,"window_minutes":300,"resets_at":1000},"secondary":{"used_percent":22.0,"window_minutes":10080,"resets_at":2000}}}
JSONL

cat > "$SESSION_DIR/new.jsonl" <<'JSONL'
{"timestamp":"2026-05-16T00:00:01.000Z","type":"event_msg","payload":{"type":"token_count"},"rate_limits":{"primary":{"used_percent":33.0,"window_minutes":300,"resets_at":3000},"secondary":{"used_percent":44.0,"window_minutes":10080,"resets_at":4000}}}
not json
{"timestamp":"2026-05-16T00:00:02.000Z","type":"event_msg","payload":{"type":"token_count"},"rate_limits":{"primary":{"used_percent":55.0,"window_minutes":300,"resets_at":5000},"secondary":{"used_percent":66.0,"window_minutes":10080,"resets_at":6000}}}
{"timestamp":"2026-05-16T00:00:03.000Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","primary":{"used_percent":82.0,"window_minutes":10080,"resets_at":1784988328},"secondary":null,"plan_type":"plus"}}}
JSONL

HOME="$TMP_HOME" PATH="$BIN_DIR:$PATH" "$ROOT/codex-usage.sh"

expected=$'v2\t1\t83\t1784988328\t10080\t3\t1785109621'
actual="$(cat "$TMP_HOME/.codex/notchy/usage")"

if [ "$actual" != "$expected" ]; then
  printf 'expected: %s\nactual:   %s\n' "$expected" "$actual" >&2
  exit 1
fi

cat > "$BIN_DIR/codex" <<'SH'
#!/bin/bash
touch "$HOME/codex-called-again"
exit 1
SH
chmod +x "$BIN_DIR/codex"

HOME="$TMP_HOME" PATH="$BIN_DIR:$PATH" "$ROOT/codex-usage.sh"
if [ -e "$TMP_HOME/codex-called-again" ]; then
  echo "fresh v2 usage should not query Codex again" >&2
  exit 1
fi

rm "$TMP_HOME/.codex/notchy/usage"
HOME="$TMP_HOME" PATH="$BIN_DIR:$PATH" "$ROOT/codex-usage.sh"

expected=$'v2\t1\t82\t1784988328\t10080\t-1\t0'
actual="$(cat "$TMP_HOME/.codex/notchy/usage")"
if [ "$actual" != "$expected" ]; then
  printf 'fallback expected: %s\nactual:            %s\n' "$expected" "$actual" >&2
  exit 1
fi

echo "codex usage test passed"
