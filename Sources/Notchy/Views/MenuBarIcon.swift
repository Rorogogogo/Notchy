import AppKit
import SwiftUI

// MARK: - Status item icon

// The active agent's mark, tinted by its status. Idle has no tint and is
// rendered as a template image so it tracks the menu bar's own appearance.
@MainActor
enum MenuBarIcon {
    private static let box = CGSize(width: 19, height: 16)

    static func image(for snapshot: AgentSnapshot) -> NSImage? {
        let renderer = ImageRenderer(content: mark(snapshot))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        guard let image = renderer.nsImage else { return nil }
        image.isTemplate = snapshot.statusColor == nil
        return image
    }

    private static func mark(_ snapshot: AgentSnapshot) -> some View {
        // Template rendering ignores the colour, so idle can pass anything opaque.
        let tint = snapshot.statusColor ?? .black
        return Group {
            switch snapshot.kind {
            case .claude:      ClaudeCrabIcon(size: 12, color: tint, eyeColor: nil)
            case .codex:       CodexMark(size: 15, color: tint)
            case .antigravity: AntigravityMark(size: 14, color: tint)
            }
        }
        .frame(width: box.width, height: box.height)
    }
}
