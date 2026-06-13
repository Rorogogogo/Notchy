# Notchy Web Ad Demo Design

**Date:** 2026-06-13

## Goal

Create a self-contained React/Vite website that advertises Notchy by showing the product behavior directly: a MacBook-style browser mock where the notch pill monitors Claude, Codex, and Antigravity status, expands to reveal usage, and communicates the product's native, lightweight positioning.

The page should be useful both as a web destination and as a source for recording a short promo video.

## Audience

Developers using agentic coding tools on macOS, especially Claude Code, Codex, and Antigravity users who want an unobtrusive way to monitor agent status and usage.

## Non-Goals

- No backend.
- No live integration with local Notchy state files.
- No installer/download automation beyond links.
- No video renderer in this pass.
- No claim that the web mock is the actual app.

## Approach

Build a new `website/` Vite React app inside this repository. The app is a polished single-page product demo:

1. A first-viewport interactive MacBook-style scene.
2. A Notchy pill integrated with the top notch.
3. Animated agent status states: working, waiting, idle.
4. An expanded hover/demo panel with usage bars.
5. Compact proof points and CTAs below the demo.

The page should lead with the visual product behavior rather than a traditional marketing hero. Users should immediately understand that Notchy lives in the Mac notch and answers, at a glance, whether an agent is working, waiting, or idle.

## Page Structure

### Demo View

The first viewport contains:

- A dark MacBook/screen mock with menu bar and notch.
- A subtle editor/terminal workspace background that suggests AI coding without relying on screenshots.
- The Notchy collapsed pill at the notch.
- Status cycling across:
  - Claude: working
  - Codex: waiting
  - Antigravity: idle/status-only
- A demo expanded state showing:
  - Claude row with 5h and weekly usage bars.
  - Codex row with 5h and weekly usage bars.
  - Antigravity row with status only.

The demo can animate automatically so it works during screen recording. Hover or focus interactions may also reveal the expanded panel, but the page must not require user interaction to communicate the core idea.

### Copy

Primary message:

> Glance at your notch. Know if your agent is working, waiting on you, or idle.

Supporting points:

- Native Swift app.
- Around 0.1% idle CPU.
- Around 32 MB RSS.
- Zero network calls.
- Real `/usage` numbers for Claude and Codex.
- Supports Claude Code, Codex, and Antigravity.

The page should avoid long documentation-style explanations. It should feel like an ad/demo, not the README repeated in a new format.

### CTAs

Primary CTA:

- Download Notchy from the latest GitHub release.

Secondary CTA:

- View the source/README on GitHub.

Use existing repo URLs from the README.

## Visual Direction

The design should feel native, precise, and technical:

- Dark macOS-inspired screen surface.
- Crisp typography and restrained color.
- Status colors match the product model:
  - green = working
  - amber/yellow = waiting
  - gray = idle
- Agent identity is visible through concise labels and simple icon treatment.
- Avoid generic SaaS hero patterns, oversized marketing cards, decorative blobs, and one-note purple/blue gradients.

## Implementation

Create a `website/` folder with:

- Vite React TypeScript setup.
- A single app entry.
- Componentized UI for the demo scene, notch pill, usage rows, proof points, and CTAs.
- CSS scoped to the website app.

The site is static and should build with `npm run build` from `website/`.

## Verification

- Install dependencies if needed.
- Run the Vite build.
- Start the dev server.
- Verify the page renders in browser or with an equivalent local check.
- Confirm the layout works at desktop and mobile widths.

## Future Extension

After the web demo is working, it can be recorded as:

- README hero GIF/video.
- Social launch clip.
- Product Hunt media.
- Landing page hero asset.
