import AppKit
import SwiftUI

// MARK: - Popover contents

struct StatusPanelView: View {
    @ObservedObject var claudeStatus: AgentStatusModel
    @ObservedObject var claudeUsage: AgentUsageModel
    @ObservedObject var codexStatus: AgentStatusModel
    @ObservedObject var codexUsage: AgentUsageModel
    @ObservedObject var antigravityStatus: AgentStatusModel
    @StateObject private var repoStats = GitHubRepoStatsModel()
    // Countdowns would otherwise freeze at whatever they read when the view was
    // last built. A minute is the finest granularity any label here shows.
    @State private var now = Date()
    private let tick = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var snapshots: [AgentSnapshot] {
        agentSnapshots(
            claudeStatus: claudeStatus,
            claudeUsage: claudeUsage,
            codexStatus: codexStatus,
            codexUsage: codexUsage,
            antigravityStatus: antigravityStatus
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(snapshots) { snapshot in
                if snapshot.kind != .claude {
                    Divider()
                }
                agentRow(snapshot)
            }
            footerControls
                .padding(.top, 2)
        }
        .padding(14)
        .frame(width: 300)
        .onReceive(tick) { now = $0 }
        // Opaque black, like the old notch pill — not the translucent system
        // popover material, which lets the desktop bleed through the readings.
        .background(Color.black)
    }

    private func agentRow(_ snapshot: AgentSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                switch snapshot.kind {
                case .claude:      ClaudeCrabIcon(size: 12)
                case .codex:       CodexMark(size: 13, color: .primary)
                case .antigravity: AntigravityMark(size: 12)
                }
                Text(snapshot.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                if !snapshot.project.isEmpty {
                    Text(snapshot.project)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                Text(snapshot.status)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(snapshot.statusColor ?? .secondary)
            }

            if let usage = snapshot.usage {
                ForEach(Array(usage.windows.enumerated()), id: \.offset) { _, window in
                    usageRow(label: window.label, pct: window.pct, reset: window.resetUnix)
                }
                if let resetCount = usage.resetCreditCount {
                    resetCreditRow(count: resetCount, expiry: usage.resetCreditExpiryUnix)
                }
            }
        }
    }

    private func usageRow(label: String, pct: Double, reset: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            // The reading sits beside the bar it describes: the segments are a
            // fixed 126pt, so on their own line they left a wide gap while the
            // numbers crowded the label above.
            HStack {
                UsageBar(pct: pct, segmentCount: 16, showPercent: false)
                Spacer()
                Text("\(Int(max(0, 100 - pct).rounded()))% left · resets in \(AgentUsageModel.resetCountdownLabel(for: reset, now: now))")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private func resetCreditRow(count: Int, expiry: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "arrow.counterclockwise.circle")
                .font(.system(size: 9, weight: .semibold))
            Text(count == 1 ? "1 manual reset" : "\(count) manual resets")
            if expiry > 0 {
                Text("· next expires in \(AgentUsageModel.resetCountdownLabel(for: expiry, now: now))")
            }
        }
        .font(.system(size: 9.5, weight: .medium, design: .rounded))
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }

    private var footerControls: some View {
        HStack(spacing: 8) {
            repoButton { openGitHub() }
            Spacer(minLength: 8)
            footerButton(title: "Quit", systemImage: "xmark") {
                NSApp.terminate(nil)
            }
        }
    }

    private static let githubMarkImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "github", withExtension: "svg"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.isTemplate = true
        return image
    }()

    private func repoButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Group {
                        if let mark = Self.githubMarkImage {
                            Image(nsImage: mark)
                                .resizable()
                                .interpolation(.high)
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 9.5, weight: .semibold))
                        }
                    }
                    .frame(width: 11, height: 11)
                    Text(repoStats.repoName)
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }

                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 1, height: 12)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.16))
                    Text(repoStats.starsText)
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(capsuleBackground)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Open GitHub")
    }

    private func footerButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 9.5, weight: .semibold))
                Text(title)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(capsuleBackground)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(title)
    }

    private var capsuleBackground: some View {
        Capsule()
            .fill(Color.primary.opacity(0.07))
            .overlay(Capsule().stroke(Color.primary.opacity(0.10), lineWidth: 0.5))
    }

    private func openGitHub() {
        guard let url = URL(string: repoStats.repoURL) else { return }
        NSWorkspace.shared.open(url)
    }
}
