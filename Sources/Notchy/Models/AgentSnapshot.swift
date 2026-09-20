import SwiftUI

struct AgentSnapshot: Identifiable {
    let kind: AgentKind
    let status: String
    let project: String
    let lastEventTs: Int
    let usage: AgentUsageModel?

    var id: String { kind.rawValue }
    var name: String { kind.displayName }

    // nil means "no tint": idle renders as a template image in the menu bar and
    // as the standard secondary label in the panel.
    var statusColor: Color? {
        switch status {
        case "working": return Color(red: 0.24, green: 0.72, blue: 0.38)
        case "waiting": return Color(red: 0.95, green: 0.68, blue: 0.11)
        case "error":   return Color(red: 0.90, green: 0.29, blue: 0.24)
        default:        return nil
        }
    }
}

@MainActor
func agentSnapshots(
    claudeStatus: AgentStatusModel,
    claudeUsage: AgentUsageModel,
    codexStatus: AgentStatusModel,
    codexUsage: AgentUsageModel,
    antigravityStatus: AgentStatusModel
) -> [AgentSnapshot] {
    [
        AgentSnapshot(kind: .claude, status: claudeStatus.effectiveStatus, project: claudeStatus.project, lastEventTs: claudeStatus.lastEventTs, usage: claudeUsage),
        AgentSnapshot(kind: .codex, status: codexStatus.effectiveStatus, project: codexStatus.project, lastEventTs: codexStatus.lastEventTs, usage: codexUsage),
        AgentSnapshot(kind: .antigravity, status: antigravityStatus.effectiveStatus, project: antigravityStatus.project, lastEventTs: antigravityStatus.lastEventTs, usage: nil),
    ]
}

extension Array where Element == AgentSnapshot {
    var mostRecent: AgentSnapshot { self.max { $0.lastEventTs < $1.lastEventTs } ?? self[0] }
}
