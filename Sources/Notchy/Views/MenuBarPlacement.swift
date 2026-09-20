import AppKit

// MARK: - Menu bar slot placement

// When the menu bar's right-hand strip is full, macOS accepts the status item
// and then parks it left of the notch, where it is never drawn. The item still
// exists, still updates its tooltip, and still answers Accessibility queries —
// it is simply invisible, with no error and no callback. A fresh install on a
// busy notched Mac hits this every time, so detect it and claim a real slot.
@MainActor
enum MenuBarPlacement {
    // AppKit registers an unnamed status item under "Item-0" at creation time
    // and reads its saved slot there. Assigning an autosaveName afterwards is
    // too late to change that, so write the slot where AppKit will look.
    private static let positionKey = "NSStatusItem Preferred Position Item-0"
    private static let warnedKey = "NotchyWarnedMenuBarFull"

    // Higher values sit further left, and macOS reserves a margin beside the
    // notch that it will not draw into — ask for too much and the item lands
    // there, invisible again. These are fractions of the screen width so the
    // first choice sits among the other third-party icons on any display, with
    // a more conservative second try if that still misses.
    private static let positionFractions: [Double] = [0.30, 0.16]

    static func preferredPosition(attempt: Int) -> Int {
        let width = NSScreen.main?.frame.width ?? 1512
        let fraction = positionFractions[min(attempt, positionFractions.count - 1)]
        return Int(width * fraction)
    }

    static var attemptCount: Int { positionFractions.count }

    // macOS draws status items only inside auxiliaryTopRightArea, and reserves a
    // margin of it next to the notch. A parked item lands far to the left of
    // that strip, so the midpoint test is enough to tell the two apart.
    static func isPlaced(_ item: NSStatusItem) -> Bool {
        guard let window = item.button?.window else { return false }
        let frame = window.frame
        guard frame.width > 0, frame.origin.y >= 0 else { return false }
        guard let strip = NSScreen.main?.auxiliaryTopRightArea else { return frame.origin.x > 0 }
        return frame.midX >= strip.minX && frame.midX <= strip.maxX
    }

    static var hasClaimedSlot: Bool {
        UserDefaults.standard.object(forKey: positionKey) != nil
    }

    static func claimSlot(attempt: Int) {
        UserDefaults.standard.set(preferredPosition(attempt: attempt), forKey: positionKey)
    }

    // Shown at most once per install: repeating it every launch would be worse
    // than the silence it replaces.
    static func warnMenuBarFullOnce() {
        guard !UserDefaults.standard.bool(forKey: warnedKey) else { return }
        UserDefaults.standard.set(true, forKey: warnedKey)

        let alert = NSAlert()
        alert.messageText = "Notchy has no room in the menu bar"
        alert.informativeText = """
            Your menu bar is full, so macOS is hiding Notchy's icon rather than \
            showing it — this is a macOS limit, not a crash. Notchy is running \
            normally behind the scenes.

            Quit or hide one other menu bar icon and Notchy will appear. You can \
            also ⌘-drag icons along the menu bar to rearrange them.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")

        // An .accessory app cannot put a modal alert on screen — runModal returns
        // without ever showing it. Become a regular app for the duration, which
        // is the only moment Notchy ever needs to be one.
        let policy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
        NSApp.setActivationPolicy(policy)
    }
}
