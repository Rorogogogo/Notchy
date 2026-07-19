# Codex Dynamic Usage Design

## Goal

Keep Notchy's Codex usage display working when Codex reports a different set of rate-limit windows, including the current weekly-only response.

## Confirmed Cause

Older Codex session events reported a 300-minute `primary` window and a 10,080-minute `secondary` window. Current events can instead report only a 10,080-minute `primary` window with `secondary: null`. `codex-usage.sh` currently requires both entries and the Swift UI always labels them as `5h block` and `This week`, so current events are discarded.

## Design

`codex-usage.sh` will first query Codex's authenticated local app-server with `account/rateLimits/read`. That response is the canonical source for both the active limit windows and manual rate-limit reset credits. The existing session-log scan remains an offline fallback for usage windows when the app-server is unavailable. A short refresh interval prevents lifecycle hooks from starting excessive app-server processes.

Each available Codex limit is described by percentage, reset time, and window duration. The helper will write a versioned tab-separated record:

```text
v2\t<window_count>\t[<used_pct>\t<reset_unix>\t<window_minutes>...]\t<reset_credit_count>\t<nearest_credit_expiry>
```

The version marker avoids ambiguously reinterpreting the existing four-field Claude format. The parser will continue accepting that legacy format as a five-hour and weekly pair.

`AgentUsageModel` will expose usage windows rather than requiring two fixed quotas. Known durations receive friendly labels (`5h block`, `Today`, and `This week`); other durations receive a compact hour/day label. `NotchContentView` will render the windows that are actually present, show remaining percentage, and format the automatic reset as an exact local date and time. This means current Codex accounts show only `This week`, while older Codex and Claude data still show both existing rows.

When reset-credit metadata is available, the Codex row will also show the number of manual resets and the nearest expiry in local time. Notchy will not consume credits; users continue to perform the irreversible reset through Codex `/usage`.

Malformed or incomplete windows will be ignored. If an event has no valid windows, the helper will leave the previous usage file untouched.

## Testing

The shell parser test will use a fake Codex app-server to cover a weekly-only payload with reset credits and verify the versioned output. It will also retain coverage for session-log fallback, the older two-window payload, and latest-event selection. Shell syntax and the complete Swift/package build will provide integration verification.
