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
    private let panel = StatusPanel()
    private var dismissMonitor: Any?
    private var panelHiddenAt: Date = .distantPast
    private var cancellables = Set<AnyCancellable>()
    private var iconKey: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installStatusItem()

        let host = NSHostingController(rootView: StatusPanelChrome(content: StatusPanelView(
            claudeStatus: claudeStatus,
            claudeUsage: claudeUsage,
            codexStatus: codexStatus,
            codexUsage: codexUsage,
            antigravityStatus: antigravityStatus
        )))
        host.sizingOptions = [.preferredContentSize]
        host.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = host

        // Each status file change republishes here; the models also fire when a
        // stale "waiting" ages out, which is what retires the yellow icon.
        for model in [claudeStatus, codexStatus, antigravityStatus] {
            model.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async { self?.refreshStatusItem() }
                }
                .store(in: &cancellables)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelDidResignKey(_:)),
            name: NSWindow.didResignKeyNotification,
            object: panel
        )

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
        if panel.isVisible {
            hidePanel()
            return
        }
        // Clicking the icon while the panel is open makes it resign key, which
        // closes it a moment before this fires. Without this the pair reads as
        // a close followed by an immediate reopen.
        guard Date().timeIntervalSince(panelHiddenAt) > 0.25 else { return }
        showPanel()
    }

    private func showPanel() {
        guard let button = statusItem?.button, let buttonWindow = button.window else { return }

        // Size to the content first: the readings grow and shrink as agents
        // report, so a fixed height would clip or leave a black margin.
        panel.setContentSize(panel.contentViewController?.view.fittingSize ?? panel.frame.size)

        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        var origin = CGPoint(
            x: anchor.midX - panel.frame.width / 2,
            y: anchor.minY - panel.frame.height - 6
        )
        if let visible = (buttonWindow.screen ?? NSScreen.main)?.visibleFrame {
            origin.x = min(max(visible.minX + 8, origin.x), visible.maxX - panel.frame.width - 8)
        }
        panel.setFrameOrigin(origin)
        // Without activating, the app never becomes frontmost and the first
        // click inside is spent waking it — the Quit button would swallow it.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        installDismissMonitor()
    }

    private func hidePanel() {
        // Recorded unconditionally: resigning key can leave the panel already
        // ordered out by the time this runs, and skipping the timestamp then
        // lets the click that dismissed it fall through and reopen it.
        panelHiddenAt = Date()
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        if let monitor = dismissMonitor {
            NSEvent.removeMonitor(monitor)
            dismissMonitor = nil
        }
    }

    // A borderless panel gets none of NSPopover's transient behaviour, so
    // dismissal is wired up by hand. Losing key covers every click that lands
    // in another app or on the desktop; the global monitor is a backstop for
    // clicks that never make the panel resign, such as another status item.
    private func installDismissMonitor() {
        guard dismissMonitor == nil else { return }
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.hidePanel() }
        }
    }

    @objc private func panelDidResignKey(_ notification: Notification) {
        guard (notification.object as? NSWindow) === panel else { return }
        hidePanel()
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
