import {
  Activity,
  Apple,
  Code2,
  Download,
  Gauge,
  Github,
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
                <span
                  key={index}
                  style={{ width: `${58 + (index % 5) * 8}%` }}
                />
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
