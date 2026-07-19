# Codex Dynamic Usage Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Notchy render the Codex rate-limit windows actually reported by current session events instead of requiring a five-hour plus weekly pair.

**Architecture:** The Codex helper will write a versioned TSV sequence of `(used percent, reset timestamp, window minutes)` triples. The Swift model will parse versioned dynamic windows while retaining compatibility with the legacy four-field Claude/Codex record, and the view will render each parsed window.

**Tech Stack:** Bash, embedded Python 3, SwiftUI/AppKit, shell regression tests

---

### Task 1: Reproduce and fix weekly-only Codex parsing

**Files:**
- Modify: `scripts/test-codex-usage.sh`
- Modify: `codex-usage.sh`

**Step 1: Write the failing test**

Add a current-format fixture whose `primary` window is 10,080 minutes and whose `secondary` value is null. Expect:

```text
v2\t82\t1784988328\t10080
```

Retain a second scenario proving that the older 300-minute plus 10,080-minute payload emits two triples.

**Step 2: Run the test to verify it fails**

Run: `scripts/test-codex-usage.sh`

Expected: FAIL because the current parser discards an event without `secondary`.

**Step 3: Implement the minimal parser change**

Collect each present, valid `primary` and `secondary` object as:

```python
(used_percent, resets_at, window_minutes)
```

Require at least one valid window and serialize `v2` followed by the flattened triples.

**Step 4: Run the test to verify it passes**

Run: `scripts/test-codex-usage.sh`

Expected: both weekly-only and legacy two-window scenarios pass.

### Task 2: Parse and render dynamic usage windows

**Files:**
- Modify: `Sources/Notchy/Models/AgentUsageModel.swift`
- Modify: `Sources/Notchy/Views/NotchContentView.swift`

**Step 1: Add the usage-window representation**

Add a value containing `label`, `pct`, and `resetUnix`. For `v2`, parse every complete triple and label 300 minutes as `5h block`, 1,440 as `Today`, 10,080 as `This week`, and other durations with a compact hours/days fallback.

**Step 2: Preserve legacy input**

When the first field is not `v2`, parse the existing four fields into the same two windows and keep the current labels.

**Step 3: Render available windows**

Replace the two fixed `usageRow` calls in `NotchContentView` with a `ForEach` over the model's windows.

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
