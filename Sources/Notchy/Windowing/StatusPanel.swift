import AppKit
import SwiftUI

// MARK: - Status panel

// NSPopover draws its own chrome — a hairline border and an arrow — over
// whatever the content puts down, so a black panel ends up outlined in grey and
// reading as a system menu. Drawing the shape ourselves brings back the
// seamless black slab from the notch era, now hung under the status item.
final class StatusPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 328, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovable = false
        level = .init(Int(CGWindowLevelForKey(.mainMenuWindow)) + 3)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        appearance = NSAppearance(named: .darkAqua)
    }

    // Buttons inside need clicks, but taking key away from the frontmost app
    // would make the panel feel like it stole focus.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - Panel shape

// The black slab itself. Kept here rather than in StatusPanelView so the panel
// owns its own edges and the content view stays about content.
struct StatusPanelChrome<Content: View>: View {
    private static var cornerRadius: CGFloat { 16 }

    let content: Content

    var body: some View {
        content
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }
}
