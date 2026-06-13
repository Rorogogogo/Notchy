# Notchy Web Ad Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a static React/Vite advertising page that demonstrates Notchy as a native macOS notch monitor for Claude Code, Codex, and Antigravity.

**Architecture:** Add a new `website/` Vite React TypeScript app that is independent from the native Swift app. The page is a single-screen-first promo demo: a MacBook-style mock, animated Notchy pill, expanded usage panel, proof points, and GitHub CTAs.

**Tech Stack:** Vite, React, TypeScript, CSS, npm.

---

## File Structure

- Create `website/package.json`: npm scripts and dependencies for the website.
- Create `website/index.html`: Vite HTML entry.
- Create `website/tsconfig.json`: TypeScript config.
- Create `website/tsconfig.node.json`: TypeScript config for Vite config.
- Create `website/vite.config.ts`: Vite React plugin config.
- Create `website/src/main.tsx`: React app bootstrap.
- Create `website/src/App.tsx`: page layout, demo data, and component composition.
- Create `website/src/styles.css`: complete responsive visual system and animation.

The native app files under `Sources/Notchy/` remain unchanged.

---

### Task 1: Scaffold The Vite React App

**Files:**
- Create: `website/package.json`
- Create: `website/index.html`
- Create: `website/tsconfig.json`
- Create: `website/tsconfig.node.json`
- Create: `website/vite.config.ts`
- Create: `website/src/main.tsx`

- [ ] **Step 1: Create package metadata and scripts**

Create `website/package.json`:

```json
{
  "name": "notchy-website",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 127.0.0.1",
    "build": "tsc -b && vite build",
    "preview": "vite preview --host 127.0.0.1"
  },
  "dependencies": {
    "@vitejs/plugin-react": "^5.0.0",
    "vite": "^7.0.0",
    "typescript": "^5.8.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "lucide-react": "^0.468.0"
  },
  "devDependencies": {}
}
```

- [ ] **Step 2: Create Vite HTML entry**

Create `website/index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta
      name="description"
      content="Notchy is a tiny native macOS notch indicator for Claude Code, Codex, and Antigravity."
    />
    <title>Notchy - Native Agent Status In Your Mac Notch</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 3: Create TypeScript configs**

Create `website/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["DOM", "DOM.Iterable", "ES2020"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx"
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

Create `website/tsconfig.node.json`:

```json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "Node",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
```

- [ ] **Step 4: Create Vite config**

Create `website/vite.config.ts`:

```ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
});
```

- [ ] **Step 5: Create React bootstrap**

Create `website/src/main.tsx`:

```tsx
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './styles.css';

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
```

- [ ] **Step 6: Install dependencies**

Run:

```bash
cd website
npm install
```

Expected: `package-lock.json` is created and dependencies install.

- [ ] **Step 7: Commit scaffold**

Run:

```bash
git add website/package.json website/package-lock.json website/index.html website/tsconfig.json website/tsconfig.node.json website/vite.config.ts website/src/main.tsx
git commit -m "feat: scaffold notchy website"
```

---

### Task 2: Build The React Demo Page

**Files:**
- Create: `website/src/App.tsx`

- [ ] **Step 1: Create the page component**

Create `website/src/App.tsx`:

```tsx
import {
  Activity,
  Apple,
  ArrowRight,
  Code2,
  Download,
  Github,
  Gauge,
  MonitorDot,
  Network,
  Sparkles,
  TerminalSquare,
  Zap,
} from 'lucide-react';

type AgentState = 'working' | 'waiting' | 'idle';

type Agent = {
  name: string;
  label: string;
  status: AgentState;
  project: string;
  fiveHour?: number;
  weekly?: number;
  reset?: string;
};

const agents: Agent[] = [
  {
    name: 'Claude',
    label: 'Claude Code',
    status: 'working',
    project: 'checkout-redesign',
    fiveHour: 52,
    weekly: 33,
    reset: 'resets in 1h 42m',
  },
  {
    name: 'Codex',
    label: 'Codex',
    status: 'waiting',
    project: 'notchy',
    fiveHour: 41,
    weekly: 28,
    reset: 'resets in 2h 10m',
  },
  {
    name: 'Antigravity',
    label: 'Antigravity',
    status: 'idle',
    project: 'release-notes',
  },
];

const proofPoints = [
  { icon: Gauge, value: '~0.1%', label: 'idle CPU' },
  { icon: Activity, value: '~32 MB', label: 'memory' },
  { icon: Network, value: 'zero', label: 'network calls' },
  { icon: MonitorDot, value: '3 agents', label: 'one notch' },
];

const statusCopy: Record<AgentState, string> = {
  working: 'working',
  waiting: 'waiting on you',
  idle: 'idle',
};

function App() {
  return (
    <main className="page-shell">
      <section className="hero" aria-labelledby="hero-title">
        <div className="hero-copy">
          <a className="repo-pill" href="https://github.com/Rorogogogo/Notchy">
            <Github size={15} />
            Open-source macOS utility
          </a>

          <h1 id="hero-title">Notchy</h1>
          <p className="hero-lede">
            Glance at your notch. Know if your agent is working, waiting on you,
            or idle.
          </p>

          <div className="hero-actions" aria-label="Primary actions">
            <a
              className="button button-primary"
              href="https://github.com/Rorogogogo/Notchy/releases/latest/download/Notchy.pkg"
            >
              <Download size={18} />
              Download
            </a>
            <a
              className="button button-secondary"
              href="https://github.com/Rorogogogo/Notchy"
            >
              <Github size={18} />
              View source
            </a>
          </div>
        </div>

        <NotchyDemo />
      </section>

      <section className="proof-strip" aria-label="Notchy proof points">
        {proofPoints.map(({ icon: Icon, value, label }) => (
          <div className="proof-item" key={label}>
            <Icon size={18} />
            <strong>{value}</strong>
            <span>{label}</span>
          </div>
        ))}
      </section>

      <section className="details" aria-label="Product details">
        <article>
          <Apple size={22} />
          <h2>Native Swift, not a browser wrapper</h2>
          <p>
            Notchy stays lightweight because the real app is a single native
            macOS binary, built to disappear into the menu bar.
          </p>
        </article>
        <article>
          <TerminalSquare size={22} />
          <h2>Real usage, not estimates</h2>
          <p>
            Claude and Codex rows use the same local usage data their CLIs
            expose, including reset timing.
          </p>
        </article>
        <article>
          <Zap size={22} />
          <h2>Event-driven and local</h2>
          <p>
            Hooks write tiny local state files and the app wakes only when
            something changes.
          </p>
        </article>
      </section>
    </main>
  );
}

function NotchyDemo() {
  return (
    <div className="demo-stage" aria-label="Animated Notchy product demo">
      <div className="mac-screen">
        <div className="menu-bar">
          <div className="traffic-lights" aria-hidden="true">
            <span />
            <span />
            <span />
          </div>
          <span>Notchy Demo</span>
          <span>Sat 10:24</span>
        </div>

        <div className="notch-area">
          <div className="hardware-notch" aria-hidden="true" />
          <div className="notchy-pill">
            <AgentGlyph agent="Claude" />
            <span className="pill-status-dot status-working" />
          </div>
          <div className="notchy-panel">
            <div className="panel-header">
              <span>Live agent monitor</span>
              <Code2 size={15} />
            </div>
            {agents.map((agent) => (
              <AgentRow agent={agent} key={agent.name} />
            ))}
          </div>
        </div>

        <div className="workspace">
          <div className="editor-pane">
            <div className="file-tabs">
              <span>App.swift</span>
              <span>usage.sh</span>
              <span>README.md</span>
            </div>
            <div className="code-lines" aria-hidden="true">
              {Array.from({ length: 13 }).map((_, index) => (
                <span key={index} style={{ width: `${58 + (index % 5) * 8}%` }} />
              ))}
            </div>
          </div>
          <div className="terminal-pane">
            <span>$ claude code</span>
            <strong>working on checkout-redesign</strong>
            <span>$ codex</span>
            <strong className="waiting">permission required</strong>
          </div>
        </div>
      </div>
    </div>
  );
}

function AgentRow({ agent }: { agent: Agent }) {
  return (
    <div className="agent-row">
      <div className="agent-meta">
        <AgentGlyph agent={agent.name} />
        <div>
          <strong>{agent.label}</strong>
          <span>{agent.project}</span>
        </div>
      </div>
      <div className="agent-status">
        <span className={`status-dot status-${agent.status}`} />
        <span>{statusCopy[agent.status]}</span>
      </div>
      {typeof agent.fiveHour === 'number' && typeof agent.weekly === 'number' ? (
        <div className="usage-grid">
          <UsageBar label="5h" value={agent.fiveHour} />
          <UsageBar label="week" value={agent.weekly} />
          <small>{agent.reset}</small>
        </div>
      ) : (
        <small className="status-only">status only</small>
      )}
    </div>
  );
}

function UsageBar({ label, value }: { label: string; value: number }) {
  return (
    <div className="usage-row">
      <span>{label}</span>
      <div className="usage-track" aria-label={`${label} usage ${value}%`}>
        <span style={{ width: `${value}%` }} />
      </div>
      <strong>{value}%</strong>
    </div>
  );
}

function AgentGlyph({ agent }: { agent: string }) {
  if (agent === 'Codex') {
    return <span className="agent-glyph glyph-codex">C</span>;
  }

  if (agent === 'Antigravity') {
    return (
      <span className="agent-glyph glyph-antigravity">
        <Sparkles size={14} />
      </span>
    );
  }

  return <span className="agent-glyph glyph-claude">Cl</span>;
}

export default App;
```

- [ ] **Step 2: Type-check before styling**

Run:

```bash
cd website
npm run build
```

Expected before `styles.css` exists: FAIL with a missing `./styles.css` module or equivalent unresolved stylesheet error. This confirms the React entry is being compiled.

---

### Task 3: Add The Complete Responsive Visual System

**Files:**
- Create: `website/src/styles.css`

- [ ] **Step 1: Create CSS**

Create `website/src/styles.css`:

```css
:root {
  color: #f6f4ef;
  background: #10110f;
  font-family:
    Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
    sans-serif;
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-width: 320px;
  background:
    radial-gradient(circle at 16% 12%, rgba(45, 92, 126, 0.22), transparent 30%),
    linear-gradient(145deg, #141512 0%, #181915 48%, #0c0d0c 100%);
}

a {
  color: inherit;
  text-decoration: none;
}

.page-shell {
  width: min(1180px, calc(100% - 32px));
  margin: 0 auto;
  padding: 30px 0 42px;
}

.hero {
  min-height: 78vh;
  display: grid;
  grid-template-columns: minmax(280px, 0.82fr) minmax(420px, 1.18fr);
  align-items: center;
  gap: 42px;
}

.hero-copy {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.repo-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 11px;
  border: 1px solid rgba(246, 244, 239, 0.14);
  border-radius: 999px;
  color: #d9d4ca;
  background: rgba(255, 255, 255, 0.04);
  font-size: 13px;
}

h1,
h2,
p {
  margin: 0;
}

h1 {
  margin-top: 22px;
  font-size: clamp(56px, 9vw, 116px);
  line-height: 0.9;
  letter-spacing: 0;
}

.hero-lede {
  margin-top: 18px;
  max-width: 540px;
  color: #d7d2c7;
  font-size: clamp(20px, 3vw, 32px);
  line-height: 1.12;
}

.hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 28px;
}

.button {
  min-height: 46px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 9px;
  padding: 0 17px;
  border-radius: 8px;
  font-weight: 700;
  white-space: nowrap;
}

.button-primary {
  background: #f6f4ef;
  color: #11120f;
}

.button-secondary {
  border: 1px solid rgba(246, 244, 239, 0.18);
  color: #f6f4ef;
  background: rgba(255, 255, 255, 0.05);
}

.demo-stage {
  min-width: 0;
}

.mac-screen {
  position: relative;
  overflow: hidden;
  min-height: 560px;
  border: 1px solid rgba(255, 255, 255, 0.13);
  border-radius: 28px;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.06), transparent 19%),
    #1b1d1a;
  box-shadow:
    0 32px 80px rgba(0, 0, 0, 0.42),
    inset 0 1px 0 rgba(255, 255, 255, 0.12);
}

.menu-bar {
  height: 34px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 18px;
  color: rgba(246, 244, 239, 0.72);
  font-size: 12px;
  background: rgba(0, 0, 0, 0.24);
}

.traffic-lights {
  display: flex;
  gap: 7px;
}

.traffic-lights span {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #ef695f;
}

.traffic-lights span:nth-child(2) {
  background: #e8bd48;
}

.traffic-lights span:nth-child(3) {
  background: #61c454;
}

.notch-area {
  position: absolute;
  top: 0;
  left: 50%;
  z-index: 3;
  width: min(430px, 78%);
  height: 250px;
  transform: translateX(-50%);
  display: flex;
  justify-content: center;
  pointer-events: none;
}

.hardware-notch {
  position: absolute;
  top: 0;
  width: 178px;
  height: 32px;
  border-radius: 0 0 22px 22px;
  background: #050505;
}

.notchy-pill {
  position: absolute;
  top: 11px;
  left: 50%;
  z-index: 2;
  width: 88px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  border-radius: 0 0 18px 18px;
  background: #050505;
  transform: translateX(-50%);
  box-shadow: 0 8px 22px rgba(0, 0, 0, 0.38);
  animation: pillPulse 7.5s ease-in-out infinite;
}

.pill-status-dot,
.status-dot {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.08);
}

.notchy-panel {
  position: absolute;
  top: 50px;
  width: min(380px, 100%);
  padding: 14px;
  border: 1px solid rgba(255, 255, 255, 0.11);
  border-radius: 22px;
  background: rgba(5, 5, 5, 0.94);
  box-shadow: 0 22px 55px rgba(0, 0, 0, 0.42);
  transform-origin: top center;
  animation: panelFloat 7.5s ease-in-out infinite;
}

.panel-header,
.agent-meta,
.agent-status,
.usage-row,
.proof-item {
  display: flex;
  align-items: center;
}

.panel-header {
  justify-content: space-between;
  margin-bottom: 10px;
  color: #cbc6bc;
  font-size: 13px;
}

.agent-row {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 10px 12px;
  padding: 12px 0;
  border-top: 1px solid rgba(255, 255, 255, 0.09);
}

.agent-meta {
  min-width: 0;
  gap: 9px;
}

.agent-meta div {
  min-width: 0;
  display: grid;
  gap: 2px;
}

.agent-meta strong,
.agent-meta span,
.agent-status span,
.usage-row span,
.usage-row strong,
.agent-row small {
  font-size: 12px;
}

.agent-meta span,
.agent-status,
.agent-row small {
  color: #aaa49a;
}

.agent-status {
  gap: 7px;
  white-space: nowrap;
}

.agent-glyph {
  width: 24px;
  height: 24px;
  flex: 0 0 24px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 7px;
  font-size: 11px;
  font-weight: 800;
}

.glyph-claude {
  color: #21110e;
  background: #ff8a65;
}

.glyph-codex {
  color: #07120d;
  background: #76e4a6;
}

.glyph-antigravity {
  color: #10152a;
  background: #9db8ff;
}

.status-working {
  background: #5ee37d;
}

.status-waiting {
  background: #f4c84f;
}

.status-idle {
  background: #8d938d;
}

.usage-grid {
  grid-column: 1 / -1;
  display: grid;
  gap: 7px;
}

.usage-row {
  gap: 8px;
}

.usage-row span:first-child {
  width: 34px;
  color: #c9c3b7;
}

.usage-row strong {
  width: 34px;
  text-align: right;
}

.usage-track {
  flex: 1;
  height: 8px;
  overflow: hidden;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.12);
}

.usage-track span {
  display: block;
  height: 100%;
  border-radius: inherit;
  background: linear-gradient(90deg, #5ee37d, #f4c84f);
}

.status-only {
  grid-column: 1 / -1;
}

.workspace {
  position: absolute;
  inset: 72px 22px 22px;
  display: grid;
  grid-template-columns: 1.4fr 0.8fr;
  gap: 16px;
}

.editor-pane,
.terminal-pane {
  min-width: 0;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  background: rgba(13, 14, 13, 0.74);
}

.file-tabs {
  height: 38px;
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 0 12px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.file-tabs span {
  padding: 6px 9px;
  border-radius: 7px;
  color: #c4beb2;
  background: rgba(255, 255, 255, 0.05);
  font-size: 12px;
}

.code-lines {
  display: grid;
  gap: 12px;
  padding: 24px 18px;
}

.code-lines span {
  height: 10px;
  border-radius: 999px;
  background: linear-gradient(90deg, rgba(246, 244, 239, 0.2), rgba(246, 244, 239, 0.05));
}

.terminal-pane {
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  gap: 10px;
  padding: 18px;
  color: #b9b3a8;
  font-family: "SFMono-Regular", Consolas, monospace;
  font-size: 13px;
}

.terminal-pane strong {
  color: #72e493;
  font-weight: 700;
}

.terminal-pane .waiting {
  color: #f4c84f;
}

.proof-strip {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  margin-top: 16px;
}

.proof-item {
  gap: 9px;
  min-height: 72px;
  padding: 14px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.045);
}

.proof-item strong {
  font-size: 20px;
}

.proof-item span {
  color: #bbb5aa;
  font-size: 13px;
}

.details {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 14px;
  margin-top: 14px;
}

.details article {
  padding: 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.04);
}

.details h2 {
  margin-top: 14px;
  font-size: 18px;
}

.details p {
  margin-top: 8px;
  color: #c4beb2;
  line-height: 1.55;
}

@keyframes panelFloat {
  0%,
  18% {
    opacity: 0;
    transform: translateY(-8px) scale(0.96);
  }
  28%,
  82% {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  100% {
    opacity: 0;
    transform: translateY(-8px) scale(0.96);
  }
}

@keyframes pillPulse {
  0%,
  100% {
    width: 88px;
  }
  28%,
  82% {
    width: 118px;
  }
}

@media (max-width: 900px) {
  .page-shell {
    width: min(100% - 24px, 680px);
    padding-top: 22px;
  }

  .hero {
    min-height: auto;
    grid-template-columns: 1fr;
    gap: 28px;
  }

  .mac-screen {
    min-height: 500px;
  }

  .workspace {
    grid-template-columns: 1fr;
  }

  .terminal-pane {
    display: none;
  }

  .proof-strip,
  .details {
    grid-template-columns: 1fr 1fr;
  }
}

@media (max-width: 560px) {
  .hero-actions,
  .button {
    width: 100%;
  }

  .proof-strip,
  .details {
    grid-template-columns: 1fr;
  }

  .mac-screen {
    min-height: 470px;
    border-radius: 18px;
  }

  .notch-area {
    width: calc(100% - 18px);
  }

  .notchy-panel {
    width: 100%;
  }

  .workspace {
    inset: 70px 10px 12px;
  }

  .file-tabs span:nth-child(3) {
    display: none;
  }
}
```

- [ ] **Step 2: Build after CSS**

Run:

```bash
cd website
npm run build
```

Expected: PASS and Vite outputs `dist/`.

- [ ] **Step 3: Commit page implementation**

Run:

```bash
git add website/src/App.tsx website/src/styles.css
git commit -m "feat: build notchy web ad demo"
```

---

### Task 4: Verify Locally And Tune If Needed

**Files:**
- Modify only if verification finds layout or accessibility issues:
  - `website/src/App.tsx`
  - `website/src/styles.css`

- [ ] **Step 1: Start dev server**

Run:

```bash
cd website
npm run dev
```

Expected: Vite starts on a local URL such as `http://127.0.0.1:5173/`.

- [ ] **Step 2: Verify desktop layout**

Open the local URL at desktop width. Confirm:

- H1 says `Notchy`.
- The Mac screen mock is visible in the first viewport.
- The hardware notch and Notchy pill are centered.
- The expanded monitor panel appears automatically during the animation cycle.
- Claude and Codex show usage bars.
- Antigravity shows `status only`.
- CTAs point to GitHub release download and repository source.

- [ ] **Step 3: Verify mobile layout**

Resize the browser below 560px width. Confirm:

- Text does not overlap.
- Buttons stack and remain readable.
- The Notchy panel stays within the screen mock.
- Proof points and details stack into one column.

- [ ] **Step 4: Run final build**

Run:

```bash
cd website
npm run build
```

Expected: PASS.

- [ ] **Step 5: Commit verification tweaks**

If any files changed during verification:

```bash
git add website/src/App.tsx website/src/styles.css
git commit -m "fix: tune notchy website layout"
```

If no files changed, do not create an empty commit.

---

## Self-Review

- Spec coverage: The plan creates a static React/Vite app, first-viewport MacBook demo, Notchy pill, automatic expanded panel, agent rows, usage bars, proof points, and CTAs.
- Placeholder scan: No unfinished-marker or deferred implementation steps remain.
- Type consistency: `Agent`, `AgentState`, `AgentRow`, `UsageBar`, and `AgentGlyph` names match across the plan.
