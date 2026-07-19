<div align="center">

<img src="assets/logo.png?v=2" width="140" height="140" alt="Notchy logo" />

# Notchy

**A tiny, native macOS notch indicator for [Claude Code](https://docs.claude.com/en/docs/claude-code), Codex, and Antigravity.**

Glance at your notch. Know if your agent is working, waiting on you, or idle.
Hover for live quota usage — the exact windows the agents report, plus Codex manual reset credits.

<p>
  <a href="https://github.com/Rorogogogo/Notchy/stargazers"><img src="https://img.shields.io/github/stars/Rorogogogo/Notchy?style=for-the-badge&logo=github&color=FFD166&labelColor=1a1a1a" alt="GitHub stars" /></a>
  <a href="https://github.com/Rorogogogo/Notchy/releases/latest"><img src="https://img.shields.io/github/v/release/Rorogogogo/Notchy?style=for-the-badge&color=06D6A0&labelColor=1a1a1a" alt="Latest release" /></a>
  <a href="https://github.com/Rorogogogo/Notchy/releases"><img src="https://img.shields.io/github/downloads/Rorogogogo/Notchy/total?style=for-the-badge&color=118AB2&labelColor=1a1a1a" alt="Downloads" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Rorogogogo/Notchy?style=for-the-badge&color=EF476F&labelColor=1a1a1a" alt="License" /></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-black?style=for-the-badge&logo=apple&logoColor=white&labelColor=1a1a1a" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/Swift-native-F05138?style=for-the-badge&logo=swift&logoColor=white&labelColor=1a1a1a" alt="Swift native" />
</p>

### [⬇️ Download Notchy.pkg](https://github.com/Rorogogogo/Notchy/releases/latest/download/Notchy.pkg) &nbsp;·&nbsp; [📦 Releases](https://github.com/Rorogogogo/Notchy/releases) &nbsp;·&nbsp; [🐛 Issues](https://github.com/Rorogogogo/Notchy/issues)

</div>

---

## ✨ Highlights

- 🟢 **Live agent status** — green = working · yellow = waiting on you · gray = idle
- 📊 **Real usage, not estimates** — reported quota windows, remaining allowance, and exact reset times
- 🤝 **Multi-agent support** — Claude Code, Codex, **and** Antigravity (Gemini CLI) in the same pill
- 🪶 **Featherweight** — ~0.1 % idle CPU, ~32 MB RSS, ~220 KB binary
- 🛜 **No vendor API keys** — Claude is file-fed; Codex is queried through its authenticated local app-server
- 🌗 **Native macOS UI** — single Swift app binary, no Electron and no 60 Hz redraw loops
- 👻 **Stays out of the way** — auto-hides after 10 min, reappears the instant a hook fires

<br />

## 🪟 What it looks like

A small black notch-shaped pill, slightly wider than the physical notch:

- 🦀 Coral Claude-style crab on the left — or the Codex mark, or the Antigravity sparkle, depending on which agent updated most recently
- A colored status dot on the right:
  - 🟢 **green** — working (you sent a prompt, agent is generating or running a tool)
  - 🟡 **yellow** — waiting on you (permission prompt or other input)
  - ⚪ **gray** — idle (last turn finished cleanly)

Hover the pill to expand Dynamic-Island-style and reveal:

- Each usage window the agent currently reports, with a 16-segment bar, remaining allowance, and exact local reset time
- Available Codex manual reset credits and the nearest credit expiry (consumption stays safely inside Codex `/usage`)
- A status-only row for Antigravity (agent · project · status — Antigravity exposes no quota to chart)
- Current project + status, with a one-click quit button

<br />

## ⚖️ How Notchy compares

There are a few notch-style "vibe coding" indicators out there. Here's how Notchy stacks up against the rough category average — no names, just patterns we've seen.

| | **Notchy** | Typical notch indicator |
|---|---|---|
| Runtime | Single native Swift binary | Electron / web view / Python wrapper |
| Idle CPU | ~0.1 % | 2 – 10 % (per-frame redraws, polling loops) |
| Memory | ~32 MB RSS | 150 – 400 MB |
| Binary size | ~220 KB | 80 – 250 MB |
| Update mechanism | `kqueue` file watch, event-driven | Timer polling, often 1 – 60 Hz |
| Usage numbers | Real `/usage` values via statusline JSON | Estimated, scraped, or absent |
| Usage access | Local status data + authenticated Codex app-server | Often scrapes or needs a separate API key |
| Reset times | ✅ Exact (from server) | ❌ or approximate |
| Multi-agent (Claude Code + Codex + Antigravity) | ✅ All three, side by side | Usually one only |
| Notch-shape geometry | Matches Dynamic Island curves | Often a flat rectangle floating below |
| Auto-hide when idle | ✅ After 10 min, instant wake on hook | Often always-on |
| Click-through outside pill | ✅ Hit-tested to the visible shape | ❌ Whole bounding box blocks clicks |
| Install footprint | One `.pkg`, scripts under `~/.claude`, `~/.codex` & `~/.gemini` | App + helper daemons + login items |

The short version: most existing tools are great-looking demos built on web stacks. Notchy is what you'd build if you wanted the same idea to disappear into the OS — quiet, native, and accurate.

<br />

## 📈 Live usage data

The 5h-block and weekly percentages are **the same numbers** Claude Code's built-in `/usage` shows — including the precise reset times. Notchy doesn't estimate, it doesn't poll Anthropic, it doesn't need an admin API key.

It works by tapping the JSON Claude Code already pipes to your **statusline command** on every TUI render. That JSON contains:

```json
"rate_limits": {
  "five_hour":  { "used_percentage": 52, "resets_at": 1778767200 },
  "seven_day":  { "used_percentage": 33, "resets_at": 1779087600 }
}
```

Notchy's installer adds a 10-line writer block to your `~/.claude/statusline-command.sh` (or creates a minimal one if you have none) that extracts those fields into `~/.claude/state/usage`. The app file-watches that path with `kqueue` and re-renders the bars when it changes. **Zero polling, zero network calls.**

Numbers refresh on every statusline render (i.e. while a TUI is active). When no TUI is open, the last known numbers stay on screen until the next render.

For Codex, Notchy asks the authenticated local Codex app-server for `account/rateLimits/read`. It renders whichever windows Codex currently returns—today that may be a weekly-only quota instead of the older 5h + weekly pair—and shows available manual reset credits plus their nearest expiry. The helper caches fresh results for 30 seconds and falls back to the latest local session `token_count.rate_limits` event if app-server is unavailable. Reset credits are read-only in Notchy; use Codex `/usage` to consume one.

Antigravity (Gemini CLI / `agy`) is **status-only**: it doesn't expose a 5h/weekly quota anywhere we can read, so its row shows agent · project · status with no usage bars rather than fabricating numbers. If a future Antigravity release surfaces real quota, the same writer pattern slots straight in.

<br />

## 📦 Requirements

- macOS 14 (Sonoma) or later
- A MacBook with a notch (M-series 14"/16" Pro, M3 Air, etc.)
- Any of Claude Code, Codex, and/or Antigravity (Gemini CLI) installed
- `jq` on `PATH` (preinstalled on most dev machines; `brew install jq` if missing) — needed for Claude live usage
- `python3` on `PATH` for Codex usage and Codex/Antigravity project-name parsing
- For building from source: Xcode Command Line Tools (`xcode-select --install`)

<br />

## 🚀 Install (from the .pkg)

1. Download `Notchy.pkg` from the [Releases](https://github.com/Rorogogogo/Notchy/releases) page.
2. Double-click. macOS will show "Notchy.pkg cannot be opened because it is from an unidentified developer."
3. Open **System Settings → Privacy & Security**, scroll to the message about Notchy, click **Open Anyway**.
4. Walk through the macOS Installer.
5. **Restart any running Claude Code and/or Codex CLI sessions.** Hooks and the statusline command only load at session start.

> The package is ad-hoc signed (free) but not notarized (requires a paid Apple Developer account). That's why you need the one-time "Open Anyway" step.

The installer's postinstall script will:

- Copy the app to `/Applications/Notchy.app`
- Install scripts to `~/.claude/notchy/` (`play.sh` for status hooks, `statusline.sh` for live usage)
- Install Codex scripts to `~/.codex/notchy/` (`play.sh` for status hooks, `usage.sh` for live usage)
- Install the Antigravity script to `~/.gemini/notchy/` (`play.sh` for status hooks)
- Merge Claude Code hook entries into `~/.claude/settings.json` (existing hooks preserved)
- Enable Codex lifecycle hooks in `~/.codex/config.toml`
- Merge Notchy Codex hook entries into `~/.codex/hooks.json`
- Merge Notchy Antigravity hook entries into `~/.gemini/config/hooks.json` (existing hooks preserved)
- Append a marked writer block to your existing `~/.claude/statusline-command.sh`, or register a minimal one if you don't have a statusline configured
- Write a LaunchAgent at `~/Library/LaunchAgents/com.notchy.app.plist`
- Start the app immediately and on every login
- Clean up any artifacts from the legacy `ClaudeStatus` build

Re-running the installer is safe — hooks and writer blocks are detected by marker comments and replaced, not duplicated.

<br />

## 🛠️ Build from source

```bash
git clone https://github.com/Rorogogogo/Notchy.git
cd Notchy
./build.sh
```

Outputs:
- `build/pkg-root/Applications/Notchy.app` — the standalone app
- `build/Notchy.pkg` — the installer

<br />

## 🔬 How it works

Seven pieces:

1. **`play.sh`** — invoked by Claude Code hook events. Reads the hook payload from stdin, writes `<status>\t<unix_ts>\t<project_name>\n` to `~/.claude/state/status`. ~20 ms per invocation.

2. **Statusline writer** — a 10-line block injected into your `~/.claude/statusline-command.sh`. Each statusline render, it pulls `rate_limits` from the JSON Claude Code piped to stdin and writes `<block_pct>\t<block_reset>\t<weekly_pct>\t<weekly_reset>\n` to `~/.claude/state/usage`. Runs in `&` background so your statusline render isn't blocked.

3. **`~/.claude/state/{status,usage}`** — two single-line text files for Claude Code status and usage.

4. **`~/.codex/notchy/play.sh`** — invoked by Codex lifecycle hooks. Reads the hook payload from stdin and writes Codex status updates to `~/.codex/notchy/status`.

5. **`~/.codex/notchy/usage.sh`** — reads dynamic rate-limit windows and reset-credit metadata from Codex's local app-server, caches them briefly, and writes a versioned record to `~/.codex/notchy/usage`. Recent session JSONL remains the offline usage fallback.

6. **`~/.gemini/notchy/play.sh`** — invoked by Antigravity (Gemini CLI) hook events. Reads the hook payload from stdin and writes `<status>\t<unix_ts>\t<project_name>\n` to `~/.gemini/notchy/status`. Status-only; no usage file.

7. **`Notchy.app`** — a long-running native macOS app:
   - Floating `NSPanel` over the physical notch, level above the menu bar
   - Notch-shaped pill drawn with a custom `Shape` (top corners 6pt inward, bottom 14pt outward when collapsed, 22pt when expanded — same curves as the iPhone Dynamic Island)
   - File-watches Claude Code status/usage, Codex status/usage, and Antigravity status with `DispatchSource.makeFileSystemObjectSource` (kqueue under the hood). Re-renders only when the kernel fires `VNODE_WRITE`.
   - Hover detection constrained to the visible pill shape via `.contentShape(NotchShape(...))`, so transparent areas around the pill don't block clicks to apps below.
   - Spring-animated expansion: ~0.32 s response, 0.78 damping.
   - Auto-expires `waiting` → `idle` after 3 s (see [Caveats](#-caveats)).

<br />

## 🪝 Hooks installed

| Claude Code event | Sets status to |
|---|---|
| `SessionStart` | working |
| `UserPromptSubmit` | working |
| `PreToolUse` | working |
| `PostToolUse` | working |
| `PostToolUseFailure` | working |
| `Stop` | idle |
| `StopFailure` | idle |
| `Notification` | waiting |
| `PermissionRequest` | waiting |

Codex registers the same set of events in `~/.codex/hooks.json`.

**Antigravity** registers the same events in `~/.gemini/config/hooks.json`, but `agy` only recognizes three of them — `PreToolUse` → working, `PostToolUse` → working, `Stop` → idle. It has no notification/permission hook, so the Antigravity dot goes green while a tool runs and gray when the turn ends, but **never yellow** (see [Caveats](#-caveats)). The extra entries are harmless — `agy` ignores the ones it doesn't know.

<br />

## ⚠️ Caveats

- **No hook fires when the user denies a permission prompt** ([per the docs](https://docs.claude.com/en/docs/claude-code/hooks)). Notchy handles this by auto-expiring `waiting` → `idle` after 3 seconds with no further events.
- **Live usage only refreshes while a TUI is active.** Anthropic only sends `rate_limits` in the statusline JSON during an interactive session. When no `claude` TUI is open, the bars freeze at the last known values until the next render.
- **Codex usage depends on Codex authentication.** The local app-server supplies current windows and manual reset credits. If it is temporarily unavailable, Notchy falls back to session logs for usage windows and hides reset-credit metadata until the next successful refresh.
- **`rate_limits` only appears after the first API response** in a session. Open a fresh TUI without sending anything, and the bars stay on whatever the previous render left.
- **Hooks load at session start.** After installing (or reconfiguring), restart any running Claude Code session.
- **Codex hooks require a restart.** Restart any running Codex CLI session after installing or reconfiguring Notchy.
- **Antigravity has no usage bars and never shows yellow.** `agy` exposes no 5h/weekly quota to read (so the row is status-only), and it fires no notification/permission hook — only `PreToolUse`/`PostToolUse`/`Stop`. The dot is green during tool use and gray when idle; a permission prompt won't turn it yellow because `agy` sends no event for it.
- **Antigravity hooks require a restart.** Restart any running Antigravity (Gemini CLI) session after installing or reconfiguring Notchy.
- **Codex prompts you to trust each hook the first time it runs.** Codex stores a `trusted_hash` per hook in `~/.codex/config.toml` and asks for approval the first time it sees a new (or changed) hook command. You'll see one prompt per lifecycle event (`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `Notification`, `PermissionRequest`, etc.) — approve to let Notchy receive status updates. Codex's hook review UI numbers hooks by order (`Hook 1`, `Hook 2`, etc.); Notchy adds `statusMessage` labels to its hook commands, but Codex still controls the row title. Re-running the installer with updated hook metadata will re-prompt because the hash changes.
- **First-launch Gatekeeper warning.** The `.pkg` isn't notarized — Privacy & Security → "Open Anyway" the first time.
- **Notch-only.** Older / non-notch displays still get a pill at the top center, but it looks less like a natural notch extension.

<br />

## 🧹 Uninstall

```bash
launchctl bootout "gui/$(id -u)/com.notchy.app" 2>/dev/null
rm -rf /Applications/Notchy.app
rm -f ~/Library/LaunchAgents/com.notchy.app.plist
rm -rf ~/.claude/notchy
rm -rf ~/.codex/notchy
rm -rf ~/.gemini/notchy
```

Then strip the writer block from `~/.claude/statusline-command.sh` (look for the `# notchy-writer-begin` … `# notchy-writer-end` markers) and remove the Notchy hook entries from `~/.claude/settings.json` (they all reference `~/.claude/notchy/play.sh`).

For Codex, remove the Notchy hook entries from `~/.codex/hooks.json` (they reference `~/.codex/notchy/play.sh`). The `hooks = true` setting in `~/.codex/config.toml` can be left enabled if you use other Codex hooks, or removed if Notchy was the only reason it was enabled.

For Antigravity, remove the Notchy hook entries from `~/.gemini/config/hooks.json` (they reference `~/.gemini/notchy/play.sh`).

<br />

## 📄 License

Notchy is **dual-licensed**:

- 🆓 **AGPL-3.0** — free for personal use, open-source forks, and any project that is itself open-sourced under a compatible license. See [LICENSE](LICENSE).
- 💼 **Commercial license** — required if you want to use Notchy (or a derivative) in a **closed-source product**, a **proprietary internal tool you don't intend to open-source**, or a **paid service** where AGPL-3.0's copyleft / network-use obligations don't fit. See [COMMERCIAL.md](COMMERCIAL.md).

### Quick guide — do I need a commercial license?

| Use case | License you need |
|---|---|
| Running Notchy on your own Mac as an end user | AGPL-3.0 (free) |
| Forking Notchy and publishing your fork under AGPL-3.0 | AGPL-3.0 (free) |
| Bundling Notchy (or its code) into a closed-source app you sell | **Commercial** |
| Running a modified Notchy as part of a SaaS / hosted service without publishing the source | **Commercial** |
| Internal company tool built on Notchy that your employer won't open-source | **Commercial** |

For commercial licensing, contact **Robert Wang** at **xwang.robert@gmail.com** — see [COMMERCIAL.md](COMMERCIAL.md) for what to include in your request.

## 🙏 Credits

Notch shape geometry and the crab icon concept inspired by [farouqaldori/vibe-notch](https://github.com/farouqaldori/vibe-notch) (Apache 2.0). Codex uses OpenAI's 2025 symbol; Antigravity is drawn as a static four-point Gemini-style sparkle.

<br />

<div align="center">

If Notchy makes your notch a little more useful, consider giving it a ⭐ — it really helps.

<a href="https://github.com/Rorogogogo/Notchy/stargazers"><img src="https://img.shields.io/github/stars/Rorogogogo/Notchy?style=social" alt="Star on GitHub" /></a>

</div>
