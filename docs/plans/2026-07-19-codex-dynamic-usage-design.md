# Codex Dynamic Usage Design

## Goal

Keep Notchy's Codex usage display working when Codex reports a different set of rate-limit windows, including the current weekly-only response.

## Confirmed Cause

Older Codex session events reported a 300-minute `primary` window and a 10,080-minute `secondary` window. Current events can instead report only a 10,080-minute `primary` window with `secondary: null`. `codex-usage.sh` currently requires both entries and the Swift UI always labels them as `5h block` and `This week`, so current events are discarded.

## Design

`codex-usage.sh` will treat each available Codex limit as a window described by percentage, reset time, and `window_minutes`. It will write a versioned tab-separated record:

```text
v2\t<used_pct>\t<reset_unix>\t<window_minutes>[\t<used_pct>\t<reset_unix>\t<window_minutes>...]
```

The version marker avoids ambiguously reinterpreting the existing four-field Claude format. The parser will continue accepting that legacy format as a five-hour and weekly pair.

`AgentUsageModel` will expose usage windows rather than requiring two fixed quotas. Known durations receive friendly labels (`5h block`, `Today`, and `This week`); other durations receive a compact hour/day label. `NotchContentView` will render the windows that are actually present. This means current Codex accounts show only `This week`, while older Codex and Claude data still show both existing rows.

Malformed or incomplete windows will be ignored. If an event has no valid windows, the helper will leave the previous usage file untouched.

## Testing

The shell parser test will first cover the current weekly-only payload and verify the versioned output, then retain coverage for the older two-window payload and latest-event selection. Shell syntax and the complete Swift/package build will provide integration verification.
