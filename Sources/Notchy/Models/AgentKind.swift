enum AgentKind: String {
    case claude
    case codex
    case antigravity

    var displayName: String {
        switch self {
        case .claude:      return "Claude"
        case .codex:       return "Codex"
        case .antigravity: return "Antigravity"
        }
    }
}
