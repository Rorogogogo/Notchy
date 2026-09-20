import AppKit
import Combine

// MARK: - Model

@MainActor
final class AgentStatusModel: ObservableObject {
    @Published var status: String = "idle"
    @Published var project: String = ""
    @Published var lastEventTs: Int = 0

    // "waiting" is a transient hook signal; treat a stale one as idle.
    private static let waitingGrace: TimeInterval = 3

    var effectiveStatus: String {
        if status == "waiting", waitingAge > Self.waitingGrace { return "idle" }
        return status
    }

    private var waitingAge: TimeInterval { Date().timeIntervalSince1970 - TimeInterval(lastEventTs) }

    private var fileSource: DispatchSourceFileSystemObject?
    private var pollTimer: Timer?
    private var tickTimer: Timer?
    private var lastMtime: Date?
    private let statePath: String

    init(path: String) {
        statePath = path
        ensureFileExists()
        reload()
        watchFile()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pollIfChanged() }
        }
        timer.tolerance = 0.25
        pollTimer = timer
    }

    private func pollIfChanged() {
        let path = self.statePath
        let mtime = self.lastMtime
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                  let newMtime = attrs[.modificationDate] as? Date else { return }
            if mtime != newMtime {
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.lastMtime = newMtime
                    self.reload()
                }
            }
        }
    }

    private func ensureFileExists() {
        let dir = (statePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: statePath) {
            FileManager.default.createFile(atPath: statePath, contents: Data("idle\t0\t\n".utf8))
        }
    }

    func reload() {
        guard let raw = try? String(contentsOfFile: statePath, encoding: .utf8) else { return }
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        if parts.indices.contains(0) { status = parts[0] }
        if parts.indices.contains(1) { lastEventTs = Int(parts[1]) ?? 0 }
        if parts.indices.contains(2) { project = parts[2] }
        
        // Republish once the grace period lapses so observers can retire the
        // waiting colour without another file write. Fire just past it, or the
        // age check still reads as inside the window.
        tickTimer?.invalidate()
        tickTimer = nil
        if status == "waiting" {
            let remaining = max(0.1, Self.waitingGrace + 0.1 - waitingAge)
            tickTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.objectWillChange.send() }
            }
        }
    }

    private func watchFile() {
        fileSource?.cancel()
        fileSource = nil
        let fd = open(statePath, O_EVTONLY)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .attrib, .delete, .rename],
            queue: .main
        )
        src.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = src.data
            self.reload()
            // If the file was unlinked or replaced, re-establish the watch on the new inode.
            if flags.contains(.delete) || flags.contains(.rename) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.ensureFileExists()
                    self.watchFile()
                }
            }
        }
        src.setCancelHandler { close(fd) }
        src.resume()
        fileSource = src
    }
}
