import Foundation

@main
struct AgentUsageModelTests {
    @MainActor
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("notchy-agent-usage-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let usageFile = directory.appendingPathComponent("usage")
        try "v2\t1\t83\t1784988328\t10080\t3\t1785109621\n"
            .write(to: usageFile, atomically: true, encoding: .utf8)

        let model = AgentUsageModel(path: usageFile.path, createIfMissing: false)
        precondition(model.windows.count == 1)
        precondition(model.windows[0].label == "This week")
        precondition(model.windows[0].pct == 83)
        precondition(model.windows[0].resetUnix == 1784988328)
        precondition(model.resetCreditCount == 3)
        precondition(model.resetCreditExpiryUnix == 1785109621)

        try "52\t1778767200\t33\t1779087600\n"
            .write(to: usageFile, atomically: true, encoding: .utf8)
        model.reload()
        precondition(model.windows.count == 2)
        precondition(model.windows[0].label == "5h block")
        precondition(model.windows[0].pct == 52)
        precondition(model.windows[1].label == "This week")
        precondition(model.windows[1].pct == 33)
        precondition(model.resetCreditCount == nil)
        precondition(model.resetCreditExpiryUnix == 0)

        let previousWindows = model.windows
        try "v2\t1\tnot-a-percent\t1784988328\t10080\t3\t1785109621\n"
            .write(to: usageFile, atomically: true, encoding: .utf8)
        model.reload()
        precondition(model.windows == previousWindows)
        precondition(model.resetCreditCount == nil)

        try "bad\t1778767200\t33\t1779087600\n"
            .write(to: usageFile, atomically: true, encoding: .utf8)
        model.reload()
        precondition(model.windows == previousWindows)

        let utc = TimeZone(secondsFromGMT: 0)!
        let english = Locale(identifier: "en_US_POSIX")
        precondition(
            AgentUsageModel.resetDateLabel(
                for: 1_788_912_000,
                timeZone: utc,
                locale: english
            ) == "Sep 9, 2026 at 12:00 AM"
        )
        precondition(
            AgentUsageModel.resetDateLabel(for: 0, timeZone: utc, locale: english) == "—"
        )

        print("agent usage model test passed")
    }
}
