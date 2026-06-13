import {
  Activity,
  Apple,
  BatteryFull,
  ChevronUp,
  Download,
  Gauge,
  Github,
  MonitorDot,
  Network,
  Search,
  SlidersHorizontal,
  Star,
  TerminalSquare,
  Wifi,
  X,
  Zap,
} from 'lucide-react';
import { useEffect, useState, type ReactNode } from 'react';

type AgentState = 'working' | 'waiting' | 'idle';
type AgentKind = 'claude' | 'codex' | 'antigravity';

type UsageBlock = { label: string; pct: number; reset: string };

type Agent = {
  kind: AgentKind;
  name: string;
  project: string;
  status: AgentState;
  usage?: UsageBlock[];
};

const agents: Agent[] = [
  {
    kind: 'claude',
    name: 'Claude',
    project: 'checkout-redesign',
    status: 'working',
    usage: [
      { label: '5h block', pct: 52, reset: '1h 42m' },
      { label: 'This week', pct: 33, reset: '2d 4h' },
    ],
  },
  {
    kind: 'codex',
    name: 'Codex',
    project: 'notchy',
    status: 'waiting',
    usage: [
      { label: '5h block', pct: 41, reset: '2h 10m' },
      { label: 'This week', pct: 28, reset: '1d 9h' },
    ],
  },
  {
    kind: 'antigravity',
    name: 'Antigravity',
    project: 'release-notes',
    status: 'idle',
  },
];

// Collapsed pill mirrors the active agent (most recent event). Claude is working.
const activeAgent = agents[0];

const proofPoints = [
  { icon: Gauge, value: '~0.1%', label: 'idle CPU' },
  { icon: Activity, value: '~32 MB', label: 'memory' },
  { icon: Network, value: 'zero', label: 'network calls' },
  { icon: MonitorDot, value: '3 agents', label: 'one notch' },
];

const statusHex: Record<AgentState, string> = {
  working: '#40d36b',
  waiting: '#f0b429',
  idle: '#8b9199',
};

const buttonBase =
  'inline-flex min-h-12 w-full items-center justify-center gap-2.5 rounded-lg px-4 text-[15px] font-bold leading-none transition duration-200 hover:-translate-y-0.5 sm:w-auto';

const glassPanel =
  'rounded-lg border border-ink/12 bg-white/62 shadow-[inset_0_1px_0_rgba(255,255,255,0.72)]';

const REPO = 'Rorogogogo/Notchy';

// Readable text tints for the three states (the glowing dots use the brighter
// statusHex values so they match the notch lights exactly).
const stateInk: Record<AgentState, string> = {
  working: '#1aa54e',
  waiting: '#b8810a',
  idle: '#646b75',
};

// Live GitHub star count, fetched once and shared across every caller.
let starsPromise: Promise<number | null> | null = null;
function fetchStars(): Promise<number | null> {
  if (!starsPromise) {
    starsPromise = fetch(`https://api.github.com/repos/${REPO}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((d) =>
        d && typeof d.stargazers_count === 'number' ? d.stargazers_count : null,
      )
      .catch(() => null);
  }
  return starsPromise;
}

function useGithubStars() {
  const [stars, setStars] = useState<number | null>(null);
  useEffect(() => {
    let on = true;
    fetchStars().then((n) => {
      if (on) setStars(n);
    });
    return () => {
      on = false;
    };
  }, []);
  return stars;
}

function formatStars(n: number): string {
  return n >= 1000 ? `${(n / 1000).toFixed(1).replace(/\.0$/, '')}k` : String(n);
}

function StateWord({
  state,
  children,
}: {
  state: AgentState;
  children: ReactNode;
}) {
  return (
    <span className="whitespace-nowrap">
      <span
        className="mr-[0.3em] inline-block size-[0.5em] -translate-y-[0.06em] rounded-full align-middle"
        style={{
          background: statusHex[state],
          boxShadow: `0 0 0.5em ${statusHex[state]}`,
        }}
      />
      <span style={{ color: stateInk[state] }}>{children}</span>
    </span>
  );
}

// Counts up to `base` on mount, then gently drifts ±a few points so the meter
// feels live — the way a real usage bar inches up while an agent runs.
function useDriftingPercent(base: number) {
  const [pct, setPct] = useState(base);
  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    let cur = 0;
    let settled = false;
    setPct(0);
    const up = setInterval(() => {
      cur = Math.min(base, cur + 4);
      setPct(cur);
      if (cur >= base) {
        settled = true;
        clearInterval(up);
      }
    }, 30);
    const drift = setInterval(() => {
      if (!settled) return;
      cur = Math.max(base - 6, Math.min(base + 9, cur + (Math.random() < 0.5 ? -1 : 1)));
      setPct(cur);
    }, 2200);
    return () => {
      clearInterval(up);
      clearInterval(drift);
    };
  }, [base]);
  return pct;
}

// Live 5h-usage meter shown in the "Real usage" detail card — a bar + a
// percentage that ticks as if an agent is burning through its limit right now.
function LiveUsageRow() {
  const pct = useDriftingPercent(52);
  const filled = Math.round((pct / 100) * 14);
  return (
    <div className="mt-4 flex items-center gap-2.5">
      <span className="whitespace-nowrap text-[12px] font-semibold text-ink/55">
        5h block
      </span>
      <span className="flex flex-1 items-center gap-[3px]" aria-hidden>
        {Array.from({ length: 14 }).map((_, i) => (
          <span
            key={i}
            className={`h-2.5 flex-1 rounded-[2px] transition-colors duration-300 ${
              i < filled ? 'bg-accent' : 'bg-ink/12'
            }`}
          />
        ))}
      </span>
      <span className="text-[13px] font-extrabold tabular-nums text-ink">
        {pct}%
      </span>
    </div>
  );
}

function App() {
  const stars = useGithubStars();
  return (
    <main className="mx-auto w-[min(1180px,calc(100%-24px))] pb-6 pt-8 sm:w-[min(1180px,calc(100%-40px))] sm:pb-9 sm:pt-11">
      <section
        className="flex flex-col items-center gap-8 text-center sm:gap-11"
        aria-labelledby="hero-title"
      >
        <div className="flex max-w-full flex-col items-center">
          <h1
            className="max-w-full break-words text-[52px] font-[750] leading-[0.92] tracking-normal text-ink xs:text-[60px] md:text-[80px] xl:text-[92px]"
            id="hero-title"
          >
            Notchy
          </h1>
          <p className="mt-3.5 max-w-[640px] text-balance text-[20px] font-medium leading-[1.2] tracking-normal text-ink/78 sm:text-[23px] md:text-[26px] xl:text-[28px]">
            Glance at your notch. Know if your agent is{' '}
            <StateWord state="working">working</StateWord>,{' '}
            <StateWord state="waiting">waiting on you</StateWord>, or{' '}
            <StateWord state="idle">idle</StateWord>.
          </p>

          <div
            className="mt-6 flex w-full flex-wrap justify-center gap-3 sm:w-auto"
            aria-label="Primary actions"
          >
            <a
              className={`${buttonBase} bg-ink text-white shadow-[0_12px_24px_rgba(23,24,25,0.18)] hover:bg-black hover:shadow-[0_14px_28px_rgba(23,24,25,0.24)]`}
              href="https://github.com/Rorogogogo/Notchy/releases/latest/download/Notchy.pkg"
            >
              <Download className="size-[18px]" />
              Download
            </a>
            <a
              className={`${buttonBase} border border-ink/12 bg-white/75 text-ink hover:bg-white`}
              href="https://github.com/Rorogogogo/Notchy"
            >
              <Github className="size-[18px]" />
              View source
              {stars != null && (
                <span className="inline-flex items-center gap-1 border-l border-ink/15 pl-2.5 text-ink/60">
                  <Star className="size-[14px] fill-[#ffc73d] text-[#ffc73d]" />
                  <span className="tabular-nums">{formatStars(stars)}</span>
                </span>
              )}
            </a>
          </div>
        </div>

        <NotchyDemo />
      </section>

      <section
        className="mt-4 grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-4"
        aria-label="Notchy proof points"
      >
        {proofPoints.map(({ icon: Icon, value, label }) => (
          <div
            className={`${glassPanel} flex min-h-16 min-w-0 items-center gap-2.5 p-3.5 sm:min-h-[72px]`}
            key={label}
          >
            <Icon className="size-[18px] shrink-0 text-accent" />
            <strong className="whitespace-nowrap text-xl font-extrabold leading-none text-ink">
              {value}
            </strong>
            <span className="min-w-0 text-[13px] font-semibold leading-tight text-ink/65">
              {label}
            </span>
          </div>
        ))}
      </section>

      <section
        className="mt-3.5 grid grid-cols-1 gap-3.5 md:grid-cols-2 lg:grid-cols-3"
        aria-label="Product details"
      >
        <DetailCard icon={Apple} title="Native Swift, not a browser wrapper">
          Notchy stays lightweight because the real app is a single native
          macOS binary, built to disappear into the menu bar.
        </DetailCard>
        <DetailCard
          icon={TerminalSquare}
          title="Real usage, not estimates"
          footer={<LiveUsageRow />}
        >
          Claude and Codex rows use the same local usage data their CLIs expose,
          including reset timing.
        </DetailCard>
        <DetailCard icon={Zap} title="Event-driven and local">
          Hooks write tiny local state files and the app wakes only when
          something changes.
        </DetailCard>
      </section>

      <footer className="mt-8 border-t border-ink/10 pt-5 text-center text-[13px] leading-[1.6] text-ink/55">
        Notch geometry and the crab-icon concept inspired by{' '}
        <a
          className="font-semibold text-ink/75 underline-offset-2 hover:underline"
          href="https://github.com/farouqaldori/vibe-notch"
        >
          vibe-notch
        </a>{' '}
        by @farouqaldori (Apache 2.0).
      </footer>
    </main>
  );
}

function NotchyDemo() {
  // The active agent's live status — the single notch light reflects this, and
  // the switcher below lets visitors flip it to learn what each color means.
  const [status, setStatus] = useState<AgentState>('working');
  const liveAgents = agents.map((agent, i) =>
    i === 0 ? { ...agent, status } : agent,
  );

  return (
    <div className="w-full" aria-label="Interactive Notchy demo">
      {/* macOS desktop */}
      <div className="relative min-h-[460px] w-full overflow-hidden rounded-[20px] shadow-[0_30px_80px_rgba(32,33,36,0.3),inset_0_0_0_1px_rgba(255,255,255,0.1)] sm:min-h-[560px] sm:rounded-[24px] lg:min-h-[640px]">
        <MacWallpaper />

        {/* Menu bar */}
        <div className="absolute inset-x-0 top-0 z-20 flex h-7 items-center justify-between px-4 text-[12px] font-medium leading-none text-white/90 [text-shadow:0_1px_2px_rgba(0,0,0,0.35)] sm:h-[30px] sm:px-5">
          <div className="flex items-center gap-3.5 sm:gap-4">
            <Apple className="size-[15px] fill-white text-white" />
            <span className="font-semibold">Finder</span>
            <span className="hidden text-white/90 sm:inline">File</span>
            <span className="hidden text-white/90 sm:inline">Edit</span>
            <span className="hidden text-white/90 sm:inline">View</span>
            <span className="hidden text-white/90 md:inline">Go</span>
            <span className="hidden text-white/90 md:inline">Window</span>
            <span className="hidden text-white/90 md:inline">Help</span>
          </div>
          <div className="flex items-center gap-3.5 sm:gap-[18px]">
            <BatteryFull className="size-[18px] text-white" />
            <Wifi className="size-[15px] text-white" />
            <Search className="size-[15px] text-white" />
            <SlidersHorizontal className="size-[15px] text-white" />
            <span className="tabular-nums">Sat 10:24</span>
          </div>
        </div>

        {/* The notch */}
        <Notch agents={liveAgents} activeStatus={status} />

        {/* In-scene terminal — the agent's session. Flipping its state here
            drives the notch light directly above, all within one frame. */}
        <AgentTerminal status={status} onChange={setStatus} />

        {/* Dock */}
        <MacDock />
      </div>

      <p className="mt-5 text-center text-[13px] font-semibold text-ink/55">
        Flip the agent’s state in the terminal — watch the notch light change ↑
      </p>
    </div>
  );
}

// Cycling asterisk-burst spinner, the way Claude Code animates while it thinks.
const spinnerFrames = ['✶', '✸', '✹', '✺', '✹', '✷'];

function useSpinner(active: boolean) {
  const [i, setI] = useState(0);
  useEffect(() => {
    if (!active) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const id = setInterval(() => setI((n) => (n + 1) % spinnerFrames.length), 110);
    return () => clearInterval(id);
  }, [active]);
  return active ? spinnerFrames[i] : spinnerFrames[4];
}

// A faux Claude Code session. The body below the conversation reflects the live
// state — a spinner while working, a permission prompt while waiting, a done
// line while idle — mirroring the notch light directly above.
function AgentTerminal({
  status,
  onChange,
}: {
  status: AgentState;
  onChange: (s: AgentState) => void;
}) {
  const order: AgentState[] = ['working', 'waiting', 'idle'];
  const spin = useSpinner(status === 'working');
  return (
    <div className="absolute bottom-[88px] left-1/2 z-30 w-[min(86%,360px)] -translate-x-1/2">
      <div className="overflow-hidden rounded-[10px] bg-[#0d0d0f]/95 font-mono shadow-[0_24px_60px_rgba(0,0,0,0.5)] ring-1 ring-white/12 backdrop-blur-xl">
        {/* Title bar */}
        <div className="relative flex h-7 items-center gap-1.5 border-b border-white/8 bg-white/[0.04] px-3">
          <span className="size-[11px] rounded-full bg-[#ff5f57]" />
          <span className="size-[11px] rounded-full bg-[#febc2e]" />
          <span className="size-[11px] rounded-full bg-[#28c840]" />
          <span className="absolute left-1/2 flex -translate-x-1/2 items-center gap-1.5 whitespace-nowrap text-[11px] font-semibold text-white/45">
            <span className="text-[#d97757]">✻</span> claude — checkout-redesign
          </span>
        </div>

        {/* Body — the conversation transcript */}
        <div className="px-3.5 py-3 text-[11.5px] leading-[1.55] sm:text-[12px]">
          <div className="text-white/85">
            <span className="text-[#d97757]">&gt;</span> add Apple Pay to checkout
          </div>
          <div className="mt-1.5 text-white/80">
            <span className="text-[#40d36b]">⏺</span> Update
            <span className="text-white/40">(src/checkout/payment.ts)</span>
          </div>
          <div className="text-white/35">
            {'  '}⎿ <span className="text-[#40d36b]">+24</span>{' '}
            <span className="text-[#f25950]">-6</span>
          </div>

          {/* Live status line — this is what the state switcher drives */}
          <div className="mt-2 min-h-[34px]">
            <StatusLine status={status} spin={spin} />
          </div>

          {/* Demo control — pick the agent's state */}
          <div className="mt-2.5 flex flex-wrap items-center gap-1.5 border-t border-white/8 pt-2.5">
            <span className="text-[10.5px] text-white/30">set state</span>
            {order.map((key) => {
              const active = status === key;
              return (
                <button
                  key={key}
                  type="button"
                  onClick={() => onChange(key)}
                  aria-pressed={active}
                  className={`inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-[10.5px] font-semibold leading-none transition ${
                    active
                      ? 'bg-white/15 text-white ring-1 ring-white/20'
                      : 'text-white/55 hover:bg-white/10'
                  }`}
                >
                  <span
                    className="size-2 rounded-full"
                    style={{
                      background: statusHex[key],
                      boxShadow: active ? `0 0 8px ${statusHex[key]}` : 'none',
                    }}
                  />
                  {key}
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

function StatusLine({ status, spin }: { status: AgentState; spin: string }) {
  if (status === 'working') {
    return (
      <div className="flex items-baseline gap-2">
        <span style={{ color: statusHex.working }}>{spin}</span>
        <span className="text-white/80">Working…</span>
        <span className="text-white/35">(esc to interrupt · 8s · ↑ 1.2k tokens)</span>
      </div>
    );
  }
  if (status === 'waiting') {
    return (
      <div>
        <div className="text-white/80">
          Allow edit to <span className="text-white/55">payment.ts</span>?
        </div>
        <div className="mt-0.5" style={{ color: statusHex.waiting }}>
          ❯ Yes <span className="text-white/30">· No, tell Claude what to do</span>
        </div>
      </div>
    );
  }
  return (
    <div className="flex items-baseline gap-2 text-white/40">
      <span style={{ color: statusHex.idle }}>✓</span>
      <span>Done — 3 files changed. Idle, waiting for input.</span>
    </div>
  );
}

// macOS Sequoia-style wallpaper, built from layered gradients (no asset).
function MacWallpaper() {
  return (
    <div className="pointer-events-none absolute inset-0">
      <div className="absolute inset-0 bg-[linear-gradient(160deg,#1a2340_0%,#2a2b58_30%,#5a3a6e_55%,#8a4a63_78%,#c46a4e_100%)]" />
      <div className="absolute inset-0 bg-[radial-gradient(100%_80%_at_80%_-10%,rgba(255,200,150,0.5),transparent_55%),radial-gradient(90%_70%_at_10%_110%,rgba(70,110,210,0.55),transparent_60%)]" />
      <div className="absolute inset-0 bg-[conic-gradient(from_210deg_at_70%_30%,transparent_0deg,rgba(255,255,255,0.08)_40deg,transparent_120deg)] mix-blend-screen" />
      <div className="absolute inset-0 bg-[radial-gradient(60%_40%_at_50%_8%,rgba(0,0,0,0.18),transparent_60%)]" />
    </div>
  );
}

type DockApp =
  | 'Finder'
  | 'Ghostty'
  | 'iTerm2'
  | 'WeChat'
  | 'Chrome'
  | 'Spotify'
  | 'Notchy';

const dockApps: DockApp[] = [
  'Finder',
  'Ghostty',
  'iTerm2',
  'WeChat',
  'Chrome',
  'Spotify',
  'Notchy',
];

function MacDock() {
  return (
    <div className="pointer-events-none absolute inset-x-0 bottom-3 z-10 flex justify-center sm:bottom-4">
      <div className="flex items-end gap-2.5 rounded-2xl border border-white/25 bg-white/15 px-3 py-2 shadow-[0_12px_30px_rgba(0,0,0,0.35),inset_0_1px_0_rgba(255,255,255,0.5)] backdrop-blur-xl sm:gap-3 sm:px-3.5">
        {dockApps.map((app) => (
          <div key={app} className="size-9 sm:size-11" title={app}>
            <DockIcon app={app} />
          </div>
        ))}
      </div>
    </div>
  );
}

// Real macOS app-icon PNGs, extracted from each app's bundle. They're already
// the rounded squircle on transparent padding with the system look, so we just
// render them with a subtle dock shadow — no synthetic tile/mask.
const dockIconFile: Record<Exclude<DockApp, 'Notchy'>, string> = {
  Finder: 'finder',
  Ghostty: 'ghostty',
  iTerm2: 'iterm2',
  WeChat: 'wechat',
  Chrome: 'chrome',
  Spotify: 'spotify',
};

function DockIcon({ app }: { app: DockApp }) {
  if (app === 'Notchy') {
    // Notchy has no installed bundle to pull from, so we draw its tile here,
    // sized to match the ~82% artwork footprint of the real squircles.
    return (
      <div className="grid size-full place-items-center">
        <div className="grid size-[82%] place-items-center rounded-[22%] bg-[linear-gradient(160deg,#26272b,#050505)] shadow-[0_2px_4px_rgba(0,0,0,0.35)]">
          <ClaudeCrab size={20} />
        </div>
      </div>
    );
  }
  return (
    <img
      src={`/dock/${dockIconFile[app]}.png`}
      alt={app}
      className="size-full object-contain drop-shadow-[0_2px_3px_rgba(0,0,0,0.3)]"
    />
  );
}

function Notch({
  agents: rows,
  activeStatus,
}: {
  agents: Agent[];
  activeStatus: AgentState;
}) {
  const [open, setOpen] = useState(false);
  // Once the visitor has opened the notch even once, drop the hover hint —
  // it has done its job and shouldn't keep nagging.
  const [discovered, setDiscovered] = useState(false);

  const reveal = () => {
    setOpen(true);
    setDiscovered(true);
  };

  return (
    <div className="absolute left-1/2 top-0 z-40 -translate-x-1/2">
      <button
        type="button"
        className="block cursor-default text-left"
        aria-expanded={open}
        aria-label="Notchy agent monitor"
        onMouseEnter={reveal}
        onMouseLeave={() => setOpen(false)}
        onFocus={reveal}
        onBlur={() => setOpen(false)}
        onClick={() => {
          setDiscovered(true);
          setOpen((v) => !v);
        }}
      >
        <div
          className="relative bg-black shadow-[0_18px_44px_rgba(0,0,0,0.55)] transition-[width,border-radius] duration-[340ms] ease-[cubic-bezier(0.32,1.36,0.6,1)] motion-reduce:transition-none"
          style={{
            width: open ? 348 : 210,
            borderBottomLeftRadius: open ? 24 : 16,
            borderBottomRightRadius: open ? 24 : 16,
          }}
        >
          {/* Top inward flares — black silhouette of the island against the
              translucent menu bar, matching NotchShape's 6pt top corners. */}
          <span className="pointer-events-none absolute left-0 top-0 size-[9px] -translate-x-full bg-black [mask-image:radial-gradient(circle_at_bottom_left,transparent_9px,black_9px)]" />
          <span className="pointer-events-none absolute right-0 top-0 size-[9px] translate-x-full bg-black [mask-image:radial-gradient(circle_at_bottom_right,transparent_9px,black_9px)]" />

          {/* Collapsed top row: active agent icon + its single status light,
              colored by the live status (green / amber / gray). */}
          <div
            className="flex h-7 items-center transition-[padding] duration-[340ms] sm:h-[30px]"
            style={{ paddingInline: open ? 20 : 18 }}
          >
            <AgentIcon kind={activeAgent.kind} size={18} />
            <span className="flex-1" />
            <span
              className="size-2.5 rounded-full transition-colors duration-300"
              style={{
                background: statusHex[activeStatus],
                boxShadow: `0 0 9px ${statusHex[activeStatus]}cc`,
              }}
            />
          </div>

          {/* Expanded detail */}
          <div
            className={`grid transition-[grid-template-rows,opacity] duration-[320ms] ease-out motion-reduce:transition-none ${
              open ? 'grid-rows-[1fr] opacity-100' : 'grid-rows-[0fr] opacity-0'
            }`}
          >
            <div className="overflow-hidden">
              <div className="flex flex-col gap-2.5 px-5 pb-4 pt-3">
                {rows.map((agent, index) => (
                  <div key={agent.name}>
                    {index > 0 && <div className="mb-2.5 h-px bg-white/12" />}
                    <AgentRow agent={agent} />
                  </div>
                ))}
                <FooterControls />
              </div>
            </div>
          </div>
        </div>
      </button>

      {/* Hover hint — an arrow nudging visitors up toward the notch, since the
          interaction isn't obvious. Fades out for good after the first open. */}
      <div
        className={`pointer-events-none absolute left-1/2 top-[42px] flex -translate-x-1/2 flex-col items-center gap-1 transition-opacity duration-500 ${
          discovered ? 'opacity-0' : 'opacity-100'
        }`}
      >
        <ChevronUp className="size-4 text-white/95 drop-shadow-[0_1px_2px_rgba(0,0,0,0.5)] motion-safe:animate-bounce" />
        <span className="whitespace-nowrap rounded-full bg-black/55 px-2.5 py-1 text-[11px] font-semibold text-white ring-1 ring-white/15 backdrop-blur-sm [text-shadow:0_1px_2px_rgba(0,0,0,0.4)]">
          Hover the notch
        </span>
      </div>
    </div>
  );
}

function AgentRow({ agent }: { agent: Agent }) {
  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex items-center gap-1.5">
        <AgentIcon kind={agent.kind} size={13} />
        <span className="text-[10.5px] font-semibold text-white/85">
          {agent.name}
        </span>
        <span className="min-w-0 truncate text-[10.5px] font-medium text-white/50">
          {agent.project}
        </span>
        <span className="flex-1" />
        <span className="text-[10.5px] font-medium text-white/55">
          {agent.status}
        </span>
      </div>
      {agent.usage?.map((block) => (
        <UsageRow block={block} key={block.label} />
      ))}
    </div>
  );
}

const USAGE_SEGMENTS = 20;

function UsageRow({ block }: { block: UsageBlock }) {
  const filled = Math.ceil(
    (Math.max(0, Math.min(100, block.pct)) / 100) * USAGE_SEGMENTS,
  );
  const color =
    block.pct < 70
      ? 'bg-working'
      : block.pct < 90
        ? 'bg-waiting'
        : 'bg-[#f25950]';

  return (
    <div className="flex items-center gap-2.5">
      <span className="w-[52px] shrink-0 text-[10px] font-semibold text-white/70">
        {block.label}
      </span>
      <div className="flex flex-1 items-center gap-[2px]">
        {Array.from({ length: USAGE_SEGMENTS }).map((_, i) => (
          <span
            className={`h-[7px] flex-1 rounded-[1.5px] ${i < filled ? color : 'bg-white/18'}`}
            key={i}
          />
        ))}
      </div>
      <span className="whitespace-nowrap text-[10px] font-medium tabular-nums text-white/55">
        {block.pct}% · {block.reset}
      </span>
    </div>
  );
}

function FooterControls() {
  const stars = useGithubStars();
  return (
    <div className="mt-1 flex items-center gap-2">
      <span className="inline-flex h-[23px] items-center gap-2 rounded-full bg-white/[0.08] px-2.5 text-white/68 ring-[0.5px] ring-white/10">
        <span className="flex items-center gap-1.5">
          <Github className="size-[12px]" />
          <span className="text-[10px] font-semibold">Notchy</span>
        </span>
        <span className="h-3 w-px bg-white/12" />
        <span className="flex items-center gap-1">
          <Star className="size-[10px] fill-[#ffc73d] text-[#ffc73d]" />
          <span className="text-[10px] font-semibold tabular-nums">
            {stars != null ? formatStars(stars) : '—'}
          </span>
        </span>
      </span>
      <span className="flex-1" />
      <span className="inline-flex h-[23px] items-center gap-1.5 rounded-full bg-white/[0.08] px-2.5 text-white/66 ring-[0.5px] ring-white/10">
        <X className="size-[11px]" />
        <span className="text-[10px] font-semibold">Quit</span>
      </span>
    </div>
  );
}

function AgentIcon({ kind, size }: { kind: AgentKind; size: number }) {
  if (kind === 'claude') return <ClaudeCrab size={size} />;
  if (kind === 'codex') return <CodexGlyph size={size} />;
  return <AntigravitySpark size={size} />;
}

// Pixel-art crab, ported from the app's ClaudeCrabIcon (viewBox 66x52).
function ClaudeCrab({ size }: { size: number }) {
  const c = '#d9785a';
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 66 52"
      fill="none"
      aria-hidden="true"
      style={{ display: 'block' }}
    >
      <rect x="0" y="13" width="6" height="13" fill={c} />
      <rect x="60" y="13" width="6" height="13" fill={c} />
      <rect x="6" y="39" width="6" height="13" fill={c} />
      <rect x="18" y="39" width="6" height="13" fill={c} />
      <rect x="42" y="39" width="6" height="13" fill={c} />
      <rect x="54" y="39" width="6" height="13" fill={c} />
      <rect x="6" y="0" width="54" height="39" fill={c} />
      <rect x="12" y="13" width="6" height="6.5" fill="#000" />
      <rect x="48" y="13" width="6" height="6.5" fill="#000" />
    </svg>
  );
}

// Codex mark, from the app's bundled codex.svg.
function CodexGlyph({ size }: { size: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 20 20"
      aria-hidden="true"
      style={{ display: 'block' }}
    >
      <path
        fill="#f4f4f4"
        d="M11.248 18.25q-.825 0-1.568-.314a4.3 4.3 0 0 1-1.32-.874 4 4 0 0 1-1.304.214 4 4 0 0 1-2.046-.544 4.27 4.27 0 0 1-1.518-1.485 4 4 0 0 1-.56-2.095q0-.48.131-1.04A4.4 4.4 0 0 1 2.04 10.71a4.07 4.07 0 0 1 .017-3.4 4.2 4.2 0 0 1 1.056-1.418 3.8 3.8 0 0 1 1.6-.842 3.9 3.9 0 0 1 .76-1.683q.593-.759 1.451-1.188a4.04 4.04 0 0 1 1.832-.429q.825 0 1.567.313.742.314 1.32.875a4 4 0 0 1 1.304-.215q1.106 0 2.046.545a4.14 4.14 0 0 1 1.501 1.485q.578.941.578 2.095 0 .48-.132 1.04.66.61 1.023 1.419.363.792.363 1.666 0 .892-.38 1.717a4.3 4.3 0 0 1-1.072 1.435 3.8 3.8 0 0 1-1.584.825 3.8 3.8 0 0 1-.775 1.683 4.06 4.06 0 0 1-1.436 1.188 4.04 4.04 0 0 1-1.832.429m-4.076-2.062q.825 0 1.435-.347l3.103-1.782a.36.36 0 0 0 .164-.313v-1.42L7.881 14.62a.67.67 0 0 1-.726 0l-3.118-1.798a.5.5 0 0 1-.017.115v.198q0 .841.396 1.551.413.693 1.139 1.089a3.2 3.2 0 0 0 1.617.412m.165-2.69a.4.4 0 0 0 .181.05q.083 0 .165-.05l1.238-.71-3.977-2.31a.7.7 0 0 1-.363-.643v-3.58q-.825.362-1.32 1.122a2.9 2.9 0 0 0-.495 1.65q0 .809.413 1.55.412.743 1.072 1.123zm3.91 3.663q.875 0 1.585-.396a2.96 2.96 0 0 0 1.534-2.64v-3.564a.32.32 0 0 0-.165-.297l-1.254-.726v4.604a.7.7 0 0 1-.363.643l-3.119 1.799a3 3 0 0 0 1.783.577m.627-6.039V8.878L10.01 7.822 8.129 8.878v2.244l1.881 1.056zM7.057 5.859a.7.7 0 0 1 .363-.644l3.119-1.798a3 3 0 0 0-1.782-.578q-.874 0-1.584.396A2.96 2.96 0 0 0 6.05 4.324a3.07 3.07 0 0 0-.396 1.551v3.547q0 .199.165.314l1.237.726zm8.383 7.887q.825-.364 1.303-1.123.495-.758.495-1.65a3.15 3.15 0 0 0-.412-1.55q-.413-.743-1.073-1.123l-3.086-1.782q-.099-.065-.181-.049a.3.3 0 0 0-.165.05l-1.238.692 3.993 2.327a.6.6 0 0 1 .264.264.64.64 0 0 1 .1.363zm-3.317-8.382a.63.63 0 0 1 .726 0l3.135 1.831v-.297q0-.792-.396-1.501a2.86 2.86 0 0 0-1.105-1.155q-.71-.43-1.65-.43-.825 0-1.436.347L8.294 5.941a.36.36 0 0 0-.165.314v1.418z"
      />
    </svg>
  );
}

// Four-point Gemini sparkle, from the app's AntigravitySparkle shape.
function AntigravitySpark({ size }: { size: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      aria-hidden="true"
      style={{ display: 'block' }}
    >
      <path
        fill="#5c8ff5"
        d="M50 0 Q66 34 100 50 Q66 66 50 100 Q34 66 0 50 Q34 34 50 0 Z"
      />
    </svg>
  );
}

function DetailCard({
  children,
  icon: Icon,
  title,
  footer,
}: {
  children: ReactNode;
  icon: typeof Apple;
  title: string;
  footer?: ReactNode;
}) {
  return (
    <article className={`${glassPanel} min-w-0 p-5`}>
      <Icon className="size-[22px] text-ink/90" />
      <h2 className="mt-3.5 text-lg font-bold leading-tight tracking-normal text-ink">
        {title}
      </h2>
      <p className="mt-2 text-[15px] leading-[1.55] text-ink/65">{children}</p>
      {footer}
    </article>
  );
}

export default App;
