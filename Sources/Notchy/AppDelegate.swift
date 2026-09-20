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
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.imagePosition = .imageOnly
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        statusItem = item

        popover.behavior = .transient
        popover.animates = false
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
    }

    @objc private func togglePanel() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
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
