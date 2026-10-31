#!/bin/bash
# Point Casks/notchy.rb at a published release.
# Usage: scripts/bump-cask.sh [version]   (defaults to VERSION in build.sh)
# Run after the release's Notchy.pkg is uploaded, then commit the cask.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CASK="$ROOT/Casks/notchy.rb"
VERSION="${1:-$(sed -n 's/^VERSION="\(.*\)"$/\1/p' "$ROOT/build.sh")}"
URL="https://github.com/Rorogogogo/Notchy/releases/download/v$VERSION/Notchy.pkg"

SHA="$(curl -fsSL "$URL" | shasum -a 256 | awk '{print $1}')"

sed -i '' \
  -e "s/^  version \".*\"$/  version \"$VERSION\"/" \
  -e "s/^  sha256 \".*\"$/  sha256 \"$SHA\"/" \
  "$CASK"

echo "Casks/notchy.rb -> $VERSION ($SHA)"
