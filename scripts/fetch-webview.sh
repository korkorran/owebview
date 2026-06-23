#!/usr/bin/env bash
# Vendor a single-header webview.h compatible with these stubs.
#
# The classic single-header API (~0.10/0.11) is what lib/webview_stubs.cpp
# targets. Newer webview releases split the header and changed signatures
# (functions now return webview_error_t); if you upgrade, adjust the stubs.
set -euo pipefail

VER="${1:-0.10.0}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/vendor"

mkdir -p "$DEST"
url="https://raw.githubusercontent.com/webview/webview/${VER}/webview.h"
echo "Fetching webview.h ($VER) -> $DEST/webview.h"
curl -fsSL "$url" -o "$DEST/webview.h"
echo "Done."
