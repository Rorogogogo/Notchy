import AppKit
import Combine
import SwiftUI

// MARK: - App delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let claudeStatus = AgentStatusModel(path: "\(NSHomeDirectory())/.claude/state/status")
    let claudeUsage = AgentUsageModel(path: "\(NSHomeDirectory())/.claude/state/usage")
    let codexStatus = AgentStatusModel(path: "\(NSHomeDirectory())/.codex/notchy/status")
    let codexUsage = AgentUsageModel(path: "\(NSHomeDirectory())/.codex/notchy/usage")
    let antigravityStatus = AgentStatusModel(path: "\(NSHomeDirectory())/.gemini/notchy/status")
    // (no antigravityUsage — status-only)

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var cancellables = Set<AnyCancellable>()
    private var iconKey: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installStatusItem()

        popover.behavior = .transient
        popover.animates = false
        // The panel reads as the old black notch pill rather than a system
        // popover: force dark so the semantic colours below invert with it.
        popover.appearance = NSAppearance(named: .darkAqua)
        let host = NSHostingController(rootView: StatusPanelView(
            claudeStatus: claudeStatus,
            claudeUsage: claudeUsage,
            codexStatus: codexStatus,
            codexUsage: codexUsage,
            antigravityStatus: antigravityStatus
        ))
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host

        // Each status file change republishes here; the models also fire when a
        // stale "waiting" ages out, which is what retires the yellow icon.
        for model in [claudeStatus, codexStatus, antigravityStatus] {
            model.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async { self?.refreshStatusItem() }
                }
                .store(in: &cancellables)
        }

        refreshStatusItem()

        // The item has no window frame until AppKit has laid the menu bar out,
        // so the placement check has to wait a beat rather than run inline.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.verifyPlacement(attempt: 0)
        }
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.imagePosition = .imageOnly
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        statusItem = item
    }

    // macOS hides an overflowed status item silently, so a fresh install on a
    // full menu bar looks like a dead app: the item exists and keeps updating,
    // it is just never drawn. Book a real slot, stepping rightwards if the
    // first ask still lands in the margin beside the notch.
    private func verifyPlacement(attempt: Int) {
        guard let item = statusItem else { return }
        guard !MenuBarPlacement.isPlaced(item) else { return }
        guard attempt < MenuBarPlacement.attemptCount else {
            MenuBarPlacement.warnMenuBarFullOnce()
            return
        }
        // A slot the user positioned by hand is theirs; do not fight it.
        guard attempt > 0 || !MenuBarPlacement.hasClaimedSlot else {
            MenuBarPlacement.warnMenuBarFullOnce()
            return
        }

        // Order matters: AppKit clears a status item's saved slot when the item
        // is removed, so book the slot only once the old one is gone.
        NSStatusBar.system.removeStatusItem(item)
        statusItem = nil
        MenuBarPlacement.claimSlot(attempt: attempt)
        installStatusItem()
        // A new button starts with no image; the cache key would suppress it.
        iconKey = nil
        refreshStatusItem()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.verifyPlacement(attempt: attempt + 1)
        }
    }

    @objc private func togglePanel() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // The popover's own frame view draws the translucent material and the
        // arrow, so it has to be painted too or the black content sits inside a
        // grey surround.
        if let frameView = popover.contentViewController?.view.superview {
            frameView.wantsLayer = true
            frameView.layer?.backgroundColor = NSColor.black.cgColor
        }
    }

    private func refreshStatusItem() {
        let snapshot = agentSnapshots(
            claudeStatus: claudeStatus,
            claudeUsage: claudeUsage,
            codexStatus: codexStatus,
            codexUsage: codexUsage,
            antigravityStatus: antigravityStatus
        ).mostRecent

        let key = "\(snapshot.kind.rawValue)-\(snapshot.status)"
        guard key != iconKey else { return }
        iconKey = key

        statusItem?.button?.image = MenuBarIcon.image(for: snapshot)
        statusItem?.button?.toolTip = "\(snapshot.name) · \(snapshot.status)"
    }
}
