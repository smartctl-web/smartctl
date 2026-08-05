#!/bin/sh
set -u

# CHANGE THIS:
BASE_URL="https://github.com/smartctl-web/smartctl/releases/latest/download"

TMP="${TMPDIR:-/tmp}/smartctl.$$"

cleanup() {
    rm -f "$TMP"
}
trap cleanup EXIT HUP INT TERM

OS_VERSION="$(/usr/bin/sw_vers -productVersion 2>/dev/null)"
OS_MAJOR="${OS_VERSION%%.*}"

case "$OS_MAJOR" in
    ''|*[!0-9]*)
        echo "Could not determine macOS version."
        exit 1
        ;;
esac

# Detect Apple Silicon hardware even if Terminal itself is running under Rosetta.
if [ "$(/usr/sbin/sysctl -n hw.optional.arm64 2>/dev/null)" = "1" ]; then
    if [ "$OS_MAJOR" -lt 11 ]; then
        echo "This requires macOS Big Sur 11 or newer on Apple Silicon."
        exit 1
    fi
    BINARY="smartctl-arm64"
else
    if [ "$OS_MAJOR" -lt 12 ]; then
        echo "This requires macOS Monterey 12 or newer on Intel."
        exit 1
    fi
    BINARY="smartctl-amd64"
fi

echo "Downloading smartctl..."

if ! /usr/bin/curl -fL --retry 3 --connect-timeout 20 \
    "$BASE_URL/$BINARY" \
    -o "$TMP"
then
    echo "Download failed."
    exit 1
fi

/bin/chmod 700 "$TMP"

echo "Starting smartctl..."
echo

# /dev/tty keeps interactive prompts working even when this wrapper itself
# was launched with: curl ... | /bin/sh
/usr/bin/caffeinate -i "$TMP" </dev/tty
STATUS=$?

exit "$STATUS"
