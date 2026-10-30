cask "notchy" do
  version "1.6.3"
  sha256 "e2576bb2046c6f6488a4c908659ee328a99b4af8280798c0c318b68c4e88d8e1"

  url "https://github.com/Rorogogogo/Notchy/releases/download/v#{version}/Notchy.pkg"
  name "Notchy"
  desc "Menu bar status indicator for Claude Code, Codex and Antigravity"
  homepage "https://github.com/Rorogogogo/Notchy"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on formula: "jq"
  depends_on macos: :sonoma

  pkg "Notchy.pkg"

  uninstall launchctl: "com.notchy.app",
            quit:      "com.notchy.app",
            pkgutil:   "com.notchy.app"

  zap trash: [
    "~/.claude/notchy",
    "~/.codex/notchy",
    "~/.gemini/notchy",
    "~/Library/LaunchAgents/com.notchy.app.plist",
  ]

  caveats <<~EOS
    Restart any running Claude Code, Codex or Antigravity sessions so the
    Notchy hooks load.

    Uninstalling leaves the Notchy hook entries in ~/.claude/settings.json,
    ~/.codex/hooks.json and ~/.gemini/config/hooks.json. See the README's
    Uninstall section to remove them.
  EOS
end
