import AppKit
import Combine

struct AgentUsageWindow: Equatable {
    let label: String
    let pct: Double
    let resetUnix: Int
}

// MARK: - Usage model (dynamic windows with legacy 5h + weekly compatibility)

@MainActor
final class AgentUsageModel: ObservableObject {
    @Published private(set) var windows: [AgentUsageWindow] = []
    @Published private(set) var resetCreditCount: Int?
    @Published private(set) var resetCreditExpiryUnix: Int = 0

    private var fileSource: DispatchSourceFileSystemObject?
    private var pollTimer: Timer?
    private var lastMtime: Date?
    private let path: String

    init(path: String, createIfMissing: Bool = true) {
        self.path = path
        if createIfMissing { ensureFileExists() }
        reload()
        watchFile()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollIfChanged()
            }
        }
    }

    private func ensureFileExists() {
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: Data("0\t0\t0\t0\t0\t0\n".utf8))
        }
    }

    private func pollIfChanged() {
        let filePath = self.path
        let mtime = self.lastMtime
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
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

    func reload() {
        guard let raw = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        let parts = raw.trimmingCharacters(in: .newlines)
            .split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        if parts.first == "v2" {
            reloadVersionTwo(parts)
        } else {
            reloadLegacy(parts)
        }
    }

    private func reloadVersionTwo(_ parts: [String]) {
        guard parts.indices.contains(1),
              let windowCount = Int(parts[1]),
              windowCount > 0 else { return }

        var parsedWindows: [AgentUsageWindow] = []
        var index = 2
        for _ in 0..<windowCount {
            guard parts.indices.contains(index + 2),
                  let pct = Double(parts[index]),
                  let reset = Int(parts[index + 1]),
                  let minutes = Int(parts[index + 2]),
                  pct.isFinite,
                  (0...100).contains(pct),
                  reset > 0,
                  minutes > 0 else { return }
            parsedWindows.append(AgentUsageWindow(
                label: Self.label(forWindowMinutes: minutes),
                pct: pct,
                resetUnix: reset
            ))
            index += 3
        }

        var parsedCreditCount: Int?
        var parsedCreditExpiry = 0
        if parts.indices.contains(index), let count = Int(parts[index]), count >= 0 {
            parsedCreditCount = count
        }
        if parts.indices.contains(index + 1) {
            parsedCreditExpiry = Int(parts[index + 1]) ?? 0
        }

        windows = parsedWindows
        resetCreditCount = parsedCreditCount
        resetCreditExpiryUnix = parsedCreditExpiry
    }

    private func reloadLegacy(_ parts: [String]) {
        guard parts.count >= 4,
              let blockPct = Double(parts[0]),
              let blockReset = Int(parts[1]),
              let weeklyPct = Double(parts[2]),
              let weeklyReset = Int(parts[3]),
              blockPct.isFinite,
              weeklyPct.isFinite,
              (0...100).contains(blockPct),
              (0...100).contains(weeklyPct),
              blockReset > 0,
              weeklyReset > 0 else { return }
        windows = [
            AgentUsageWindow(
                label: "5h block",
                pct: blockPct,
                resetUnix: blockReset
            ),
            AgentUsageWindow(
                label: "This week",
                pct: weeklyPct,
                resetUnix: weeklyReset
            ),
        ]
        resetCreditCount = nil
        resetCreditExpiryUnix = 0
    }

    private static func label(forWindowMinutes minutes: Int) -> String {
        switch minutes {
        case 300: return "5h block"
        case 1_440: return "Today"
        case 10_080: return "This week"
        default:
            if minutes.isMultiple(of: 1_440) {
                return "\(minutes / 1_440)d window"
            }
            if minutes.isMultiple(of: 60) {
                return "\(minutes / 60)h window"
            }
            return "\(minutes)m window"
        }
    }

    static func resetDateLabel(
        for unix: Int,
        timeZone: TimeZone = .current,
        locale: Locale = .current
    ) -> String {
        guard unix > 0 else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(unix)))
    }

    private func watchFile() {
        fileSource?.cancel()
        fileSource = nil
        let fd = open(path, O_EVTONLY)
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
