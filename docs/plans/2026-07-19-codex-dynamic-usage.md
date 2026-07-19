# Codex Dynamic Usage Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Notchy render current Codex rate-limit windows, remaining quota, exact reset timing, and available manual reset credits instead of requiring a five-hour plus weekly pair.

**Architecture:** The Codex helper will prefer `account/rateLimits/read` from the authenticated local Codex app-server, fall back to session JSONL, and write a versioned TSV containing window triples plus reset-credit metadata. The Swift model will parse versioned dynamic windows while retaining compatibility with the legacy four-field Claude/Codex record, and the view will render each parsed window and a read-only reset-credit summary.

**Tech Stack:** Bash, embedded Python 3, SwiftUI/AppKit, shell regression tests

---

### Task 1: Reproduce current Codex usage and reset credits

**Files:**
- Modify: `scripts/test-codex-usage.sh`
- Modify: `codex-usage.sh`

**Step 1: Write the failing test**

Add a fake `codex app-server --stdio` executable that returns a current-format `account/rateLimits/read` response: a 10,080-minute primary window, null secondary, and three available reset credits. Expect:

```text
v2\t1\t83\t1784988328\t10080\t3\t1785109621
```

Retain a second scenario proving that the older 300-minute plus 10,080-minute payload emits two triples.

**Step 2: Run the test to verify it fails**

Run: `scripts/test-codex-usage.sh`

Expected: FAIL because the current parser does not query app-server or serialize reset-credit metadata.

**Step 3: Implement the minimal parser change**

Query `account/rateLimits/read`, collect each present valid `primary` and `secondary` object as:

```python
(used_percent, resets_at, window_minutes)
```

Require at least one valid window and serialize `v2`, the window count, flattened triples, available reset-credit count, and the nearest available expiry. Fall back to the existing session scan and use `-1` for unavailable reset-credit metadata.

**Step 4: Run the test to verify it passes**

Run: `scripts/test-codex-usage.sh`

Expected: app-server and session-fallback scenarios pass.

### Task 2: Parse and render dynamic usage windows

**Files:**
- Modify: `Sources/Notchy/Models/AgentUsageModel.swift`
- Modify: `Sources/Notchy/Views/NotchContentView.swift`

**Step 1: Add the usage-window representation**

Add a value containing `label`, `pct`, and `resetUnix`. For `v2`, read the declared window count, parse every complete triple, and label 300 minutes as `5h block`, 1,440 as `Today`, 10,080 as `This week`, and other durations with a compact hours/days fallback. Parse optional reset-credit count and nearest expiry fields.

**Step 2: Preserve legacy input**

When the first field is not `v2`, parse the existing four fields into the same two windows and keep the current labels.

**Step 3: Render available windows**

Replace the two fixed `usageRow` calls in `NotchContentView` with a `ForEach` over the model's windows. Show remaining percentage and the exact automatic reset date/time in the user's timezone. Show reset-credit count and nearest expiry only when the metadata is available; do not add a consume action.

**Step 4: Compile the app**

Run: `./build.sh`

Expected: Swift compilation and package creation succeed.

### Task 3: Documentation and full verification

**Files:**
- Modify: `README.md`

**Step 1: Update the Codex usage description**

Explain that Notchy uses the windows reported by Codex, so a plan with only a weekly quota shows one row and older two-window plans show two.

**Step 2: Verify shell scripts**

Run: `bash -n codex-usage.sh scripts/test-codex-usage.sh codex-play.sh scripts/postinstall build.sh`

Expected: exit 0 with no syntax errors.

**Step 3: Run the regression test and build**

Run: `scripts/test-codex-usage.sh && ./build.sh`

Expected: parser test passes and the package build succeeds.

**Step 4: Review the final diff**

Run: `git diff --check && git diff -- codex-usage.sh scripts/test-codex-usage.sh Sources/Notchy/Models/AgentUsageModel.swift Sources/Notchy/Views/NotchContentView.swift README.md`

Expected: no whitespace errors and only the intended dynamic-usage changes.
