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
import type { ReactNode } from 'react';

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

const statusClasses: Record<AgentState, string> = {
  working: 'bg-working text-working',
  waiting: 'bg-waiting text-waiting',
  idle: 'bg-idle text-idle',
};

const buttonBase =
  'inline-flex min-h-12 w-full items-center justify-center gap-2.5 rounded-lg px-4 text-[15px] font-bold leading-none transition duration-200 hover:-translate-y-0.5 sm:w-auto';

const glassPanel =
  'rounded-lg border border-ink/12 bg-white/62 shadow-[inset_0_1px_0_rgba(255,255,255,0.72)]';

function App() {
  return (
    <main className="mx-auto w-[min(1180px,calc(100%-24px))] py-5 sm:w-[min(1180px,calc(100%-40px))] sm:py-7">
      <section
        className="grid min-h-[auto] items-center gap-7 lg:min-h-[76vh] lg:grid-cols-[minmax(280px,0.8fr)_minmax(520px,1.2fr)] lg:gap-11"
        aria-labelledby="hero-title"
      >
        <div className="flex min-w-0 flex-col items-start">
          <a
            className="inline-flex max-w-full items-center gap-2 rounded-full border border-ink/12 bg-white/75 px-3 py-2 text-[12px] font-semibold leading-tight text-ink/80 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] sm:text-[13px]"
            href="https://github.com/Rorogogogo/Notchy"
          >
            <Github className="size-[15px] shrink-0" />
            <span className="min-w-0 truncate">Open-source macOS utility</span>
          </a>

          <h1
            className="mt-5 max-w-full break-words text-[52px] font-[750] leading-[0.92] tracking-normal text-ink xs:text-[58px] md:text-[82px] xl:text-[96px]"
            id="hero-title"
          >
            Notchy
          </h1>
          <p className="mt-4 max-w-[530px] text-[19px] font-medium leading-[1.18] tracking-normal text-ink/78 sm:text-[21px] md:text-[25px] xl:text-[28px]">
            Glance at your notch. Know if your agent is working, waiting on you,
            or idle.
          </p>

          <div
            className="mt-7 flex w-full flex-wrap gap-3 sm:w-auto"
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
        <DetailCard icon={TerminalSquare} title="Real usage, not estimates">
          Claude and Codex rows use the same local usage data their CLIs expose,
          including reset timing.
        </DetailCard>
        <DetailCard icon={Zap} title="Event-driven and local">
          Hooks write tiny local state files and the app wakes only when
          something changes.
        </DetailCard>
      </section>
    </main>
  );
}

function NotchyDemo() {
  return (
    <div
      className="relative min-w-0 px-0 pb-8 pt-1 sm:px-4 sm:pb-11 sm:pt-4 before:absolute before:bottom-3 before:left-1/2 before:h-[18px] before:w-4/5 before:-translate-x-1/2 before:rounded-b-[28px] before:bg-linear-to-b before:from-[#d8dadc] before:to-[#a8adb4] before:shadow-[0_16px_28px_rgba(32,33,36,0.18),inset_0_1px_0_rgba(255,255,255,0.78)] after:absolute after:bottom-[18px] after:left-1/2 after:h-[5px] after:w-[34%] after:-translate-x-1/2 after:rounded-b-xl after:bg-ink/20 sm:before:bottom-[18px] sm:before:w-[68%] sm:after:bottom-6 sm:after:w-[24%]"
      aria-label="Animated Notchy product demo"
    >
      <div className="relative z-10 min-h-[492px] overflow-hidden rounded-[23px] border-[7px] border-[#101112] bg-[linear-gradient(180deg,rgba(255,255,255,0.08)_0%,transparent_20%),linear-gradient(135deg,#1c1e1b_0%,#141514_52%,#242520_100%)] shadow-[0_30px_70px_rgba(32,33,36,0.28),inset_0_2px_0_rgba(255,255,255,0.75),inset_0_0_0_1px_rgba(255,255,255,0.08)] sm:min-h-[504px] sm:rounded-[23px] lg:min-h-[560px] lg:rounded-[30px] lg:border-[10px] before:pointer-events-none before:absolute before:inset-0 before:bg-[linear-gradient(90deg,rgba(255,255,255,0.045)_1px,transparent_1px),linear-gradient(180deg,rgba(255,255,255,0.035)_1px,transparent_1px)] before:bg-[length:28px_28px] before:[mask-image:linear-gradient(180deg,transparent_0%,black_18%,black_82%,transparent_100%)]">
        <div className="flex h-8 items-center justify-between gap-3 border-b border-white/6 bg-black/42 px-3 text-xs font-semibold leading-none text-cream/75 sm:h-[34px] sm:px-[18px]">
          <div className="flex shrink-0 gap-[7px]" aria-hidden="true">
            <span className="size-2.5 rounded-full bg-[#ff5f57] shadow-[inset_0_0_0_1px_rgba(0,0,0,0.18)]" />
            <span className="size-2.5 rounded-full bg-[#febc2e] shadow-[inset_0_0_0_1px_rgba(0,0,0,0.18)]" />
            <span className="size-2.5 rounded-full bg-[#28c840] shadow-[inset_0_0_0_1px_rgba(0,0,0,0.18)]" />
          </div>
          <span className="max-w-[120px] truncate sm:max-w-none">Notchy Demo</span>
          <span>Sat 10:24</span>
        </div>

        <div className="pointer-events-none absolute left-1/2 top-0 z-40 flex h-[286px] w-[calc(100%-18px)] -translate-x-1/2 justify-center sm:w-[min(430px,78%)]">
          <div
            className="absolute left-1/2 top-0 h-[29px] w-[154px] -translate-x-1/2 rounded-b-[22px] bg-[#030303] shadow-[0_10px_24px_rgba(0,0,0,0.34),inset_0_0_0_1px_rgba(255,255,255,0.04)] sm:h-8 sm:w-44"
            aria-hidden="true"
          />
          <div className="absolute left-1/2 top-2 z-10 flex h-7 w-[92px] -translate-x-1/2 animate-pill-open items-center justify-center gap-2.5 rounded-b-[17px] bg-[#050505] text-cream shadow-[0_10px_22px_rgba(0,0,0,0.38),inset_0_0_0_1px_rgba(255,255,255,0.06)] sm:top-2.5 sm:h-[30px]">
            <AgentGlyph agent="Claude" />
            <StatusDot status="working" pill />
          </div>
          <div className="absolute top-[46px] w-[min(330px,100%)] origin-top animate-panel-reveal rounded-lg border border-white/12 bg-[#060707]/95 p-2.5 text-cream opacity-0 shadow-[0_26px_56px_rgba(0,0,0,0.46),inset_0_1px_0_rgba(255,255,255,0.08)] sm:top-[51px] sm:w-[min(386px,100%)] sm:p-[13px]">
            <div className="mb-2 flex items-center justify-between gap-2.5 text-[13px] font-bold leading-tight text-cream/72">
              <span>Live agent monitor</span>
              <Code2 className="size-[15px]" />
            </div>
            {agents.map((agent) => (
              <AgentRow agent={agent} key={agent.name} />
            ))}
          </div>
        </div>

        <div className="absolute inset-x-2.5 bottom-3 top-[70px] grid grid-cols-1 gap-4 lg:inset-x-[22px] lg:bottom-[22px] lg:top-[74px] lg:grid-cols-[minmax(0,1.42fr)_minmax(160px,0.78fr)]">
          <div className="min-w-0 overflow-hidden rounded-lg border border-white/10 bg-[#0c0d0c]/74 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]">
            <div className="flex h-[38px] min-w-0 items-center gap-[7px] border-b border-white/8 px-3">
              <span className="min-w-0 flex-1 truncate rounded-[7px] bg-white/[0.055] px-2 py-1.5 text-center text-xs font-semibold text-cream/78">
                App.swift
              </span>
              <span className="min-w-0 flex-1 truncate rounded-[7px] bg-white/[0.055] px-2 py-1.5 text-center text-xs font-semibold text-cream/78">
                usage.sh
              </span>
              <span className="hidden min-w-0 flex-1 truncate rounded-[7px] bg-white/[0.055] px-2 py-1.5 text-center text-xs font-semibold text-cream/78 sm:block">
                README.md
              </span>
            </div>
            <div className="grid gap-2.5 px-3.5 pb-4 pt-[220px] sm:gap-3 sm:px-[18px] sm:py-6">
              {Array.from({ length: 13 }).map((_, index) => (
                <span
                  className={codeLineClass(index)}
                  key={index}
                  style={{ width: `${58 + (index % 5) * 8}%` }}
                />
              ))}
            </div>
          </div>
          <div className="hidden min-w-0 flex-col justify-end gap-2.5 overflow-hidden rounded-lg border border-white/10 bg-[#0c0d0c]/74 p-[18px] font-mono text-[13px] leading-snug text-cream/66 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)] lg:flex">
            <span>$ claude code</span>
            <strong className="font-extrabold text-working">
              working on checkout-redesign
            </strong>
            <span>$ codex</span>
            <strong className="font-extrabold text-waiting">
              permission required
            </strong>
          </div>
        </div>
      </div>
    </div>
  );
}

function AgentRow({ agent }: { agent: Agent }) {
  const hasUsage =
    typeof agent.fiveHour === 'number' && typeof agent.weekly === 'number';

  return (
    <div className="grid grid-cols-1 gap-2 border-t border-white/9 py-2.5 sm:grid-cols-[minmax(0,1fr)_auto] sm:gap-x-3 sm:gap-y-2 sm:py-3">
      <div className="flex min-w-0 items-center gap-2.5">
        <AgentGlyph agent={agent.name} />
        <div className="grid min-w-0 gap-0.5">
          <strong className="text-xs font-extrabold leading-tight text-cream">
            {agent.label}
          </strong>
          <span className="min-w-0 truncate text-xs leading-tight text-cream/62">
            {agent.project}
          </span>
        </div>
      </div>
      <div className="flex items-center gap-[7px] justify-self-start whitespace-nowrap text-xs font-semibold leading-tight text-cream/70 sm:justify-self-auto">
        <StatusDot status={agent.status} />
        <span>{statusCopy[agent.status]}</span>
      </div>
      {hasUsage ? (
        <div className="col-span-full grid min-w-0 gap-[7px]">
          <UsageBar label="5h" value={agent.fiveHour!} />
          <UsageBar label="week" value={agent.weekly!} />
          <small className="text-xs leading-tight text-cream/56">
            {agent.reset}
          </small>
        </div>
      ) : (
        <small className="col-span-full w-fit rounded-[7px] border border-white/10 bg-white/6 px-2 py-1 text-xs font-bold leading-tight text-cream/70">
          status only
        </small>
      )}
    </div>
  );
}

function UsageBar({ label, value }: { label: string; value: number }) {
  return (
    <div className="flex min-w-0 items-center gap-2">
      <span className="w-8 shrink-0 text-xs font-bold leading-tight text-cream/72 sm:w-[34px]">
        {label}
      </span>
      <div
        className="h-2 min-w-10 flex-1 overflow-hidden rounded-full bg-white/13 shadow-[inset_0_0_0_1px_rgba(255,255,255,0.04)]"
        aria-label={`${label} usage ${value}%`}
      >
        <span
          className="block h-full rounded-full bg-linear-to-r from-working via-[#9adf5d] to-waiting shadow-[0_0_14px_rgba(64,211,107,0.28)]"
          style={{ width: `${value}%` }}
        />
      </div>
      <strong className="w-8 shrink-0 text-right text-xs font-extrabold leading-tight text-cream sm:w-[34px]">
        {value}%
      </strong>
    </div>
  );
}

function AgentGlyph({ agent }: { agent: string }) {
  const base =
    'inline-flex size-6 shrink-0 items-center justify-center rounded-[7px] text-[11px] font-extrabold leading-none tracking-normal';

  if (agent === 'Codex') {
    return <span className={`${base} bg-codex text-[#06160f]`}>C</span>;
  }

  if (agent === 'Antigravity') {
    return (
      <span className={`${base} bg-antigravity text-[#111a36]`}>
        <Sparkles className="size-3.5" />
      </span>
    );
  }

  return <span className={`${base} bg-claude text-[#32120a]`}>Cl</span>;
}

function StatusDot({
  pill = false,
  status,
}: {
  pill?: boolean;
  status: AgentState;
}) {
  return (
    <span
      className={`${pill ? 'size-[9px]' : 'size-[9px]'} shrink-0 rounded-full ${statusClasses[status]} shadow-[0_0_0_3px_rgba(255,255,255,0.08),0_0_12px_currentColor]`}
    />
  );
}

function DetailCard({
  children,
  icon: Icon,
  title,
}: {
  children: ReactNode;
  icon: typeof Apple;
  title: string;
}) {
  return (
    <article className={`${glassPanel} min-w-0 p-5`}>
      <Icon className="size-[22px] text-ink/90" />
      <h2 className="mt-3.5 text-lg font-bold leading-tight tracking-normal text-ink">
        {title}
      </h2>
      <p className="mt-2 text-[15px] leading-[1.55] text-ink/65">{children}</p>
    </article>
  );
}

function codeLineClass(index: number) {
  const base = 'block h-2.5 rounded-full';

  if (index % 3 === 0) {
    return `${base} bg-linear-to-r from-codex/32 to-cream/6`;
  }

  if (index % 4 === 1) {
    return `${base} bg-linear-to-r from-claude/30 to-cream/6`;
  }

  return `${base} bg-linear-to-r from-cream/24 to-cream/6`;
}

export default App;
