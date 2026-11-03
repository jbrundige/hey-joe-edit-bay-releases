#!/bin/bash
# Installs Hey Joe Edit Bay on a Mac. Paste this into Terminal:
#
#   curl -fsSL https://raw.githubusercontent.com/jbrundige/hey-joe-edit-bay-releases/main/install.sh | bash
#
# Run it again any time to repair or update. It puts the app in ~/Applications and the rest in
# ~/Library/Application Support/Hey Joe Edit Bay. Your projects, chats and settings are kept.
# Nothing needs an admin password. Files downloaded with curl aren't quarantined by macOS, so
# the app opens without the "unidentified developer" block.
#
# release.sh fills in the @...@ values for each release.
set -euo pipefail

VERSION="0.1.1"
CODE_URL="https://github.com/jbrundige/hey-joe-edit-bay-releases/releases/download/v0.1.1/code-0.1.1.tgz";   CODE_SHA="6bc8565163ae4422d2db66b111264355ef914bc4434c0affe5bb73b44c44e422"
TOOLS_URL="https://github.com/jbrundige/hey-joe-edit-bay-releases/releases/download/tools-1/tools-1.tgz"; TOOLS_SHA="ccc1247f6942e26440345cd1d8663d5af3360c05f3952cc5016f285f7bfeee42"; TOOLS_VERSION="1"
SHELL_URL="https://github.com/jbrundige/hey-joe-edit-bay-releases/releases/download/shell-33.4.11/shell-33.4.11.zip"; SHELL_SHA="db25c700177c8ae62459ee830e611981b1f1f03b9bbb6e9aba8d030543ab3e77"; SHELL_VERSION="33.4.11"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"; MODEL_SHA="1fc70f774d38eb169993ac391eea357ef47c88757ef72ee5943879b7e8e2bc69"

HOME_DIR="${EDITBAY_HOME:-$HOME/Library/Application Support/Hey Joe Edit Bay}"
APP="${EDITBAY_APP:-$HOME/Applications/Hey Joe Edit Bay.app}"

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31m%s\033[0m\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || fail "Hey Joe Edit Bay runs on a Mac."
[ "$(uname -m)" = arm64 ] || fail "Hey Joe Edit Bay needs a Mac with Apple silicon (M1 or newer)."

# An app at that spot that this installer didn't make is someone's own build: leave it alone.
if [ -d "$APP" ] && ! grep -qs EDITBAY_HOME "$APP/Contents/Resources/app/main.js"; then
    fail "There's already a Hey Joe Edit Bay app at $APP that this installer didn't make. Move it somewhere else and run this again."
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$HOME_DIR"

# fetch <url> <sha256> <file>: download, then check it's exactly the file that was published
fetch() {
    curl -fL --progress-bar --retry 3 -o "$3" "$1" || fail "The download didn't finish. Check the internet connection and run this again."
    [ "$(shasum -a 256 "$3" | cut -d' ' -f1)" = "$2" ] || fail "A download didn't match the published file. Run this again; if it keeps happening, tell Joe."
}
installed() { cat "$1" 2>/dev/null || true; }

say "Installing Hey Joe Edit Bay $VERSION"

if [ "$(installed "$HOME_DIR/tools/VERSION")" != "$TOOLS_VERSION" ]; then
    say "Downloading the video tools (about 50 MB)"
    fetch "$TOOLS_URL" "$TOOLS_SHA" "$TMP/tools.tgz"
    rm -rf "$HOME_DIR/tools.new"; mkdir -p "$HOME_DIR/tools.new"
    tar -xzf "$TMP/tools.tgz" -C "$HOME_DIR/tools.new"
    rm -rf "$HOME_DIR/tools"; mv "$HOME_DIR/tools.new" "$HOME_DIR/tools"
fi

MODEL="$HOME_DIR/models/ggml-large-v3-turbo.bin"
if [ ! -f "$MODEL" ]; then
    say "Downloading the transcription model (1.6 GB, the slow part)"
    mkdir -p "$HOME_DIR/models"
    fetch "$MODEL_URL" "$MODEL_SHA" "$MODEL.part"
    mv "$MODEL.part" "$MODEL"
fi

if [ "$(installed "$HOME_DIR/code/VERSION")" != "$VERSION" ]; then
    say "Downloading Edit Bay itself"
    fetch "$CODE_URL" "$CODE_SHA" "$TMP/code.tgz"
    rm -rf "$HOME_DIR/code.new"; mkdir -p "$HOME_DIR/code.new"
    tar -xzf "$TMP/code.tgz" -C "$HOME_DIR/code.new"
    rm -rf "$HOME_DIR/code" "$HOME_DIR/code.next"; mv "$HOME_DIR/code.new" "$HOME_DIR/code"
    # a server still running the old code stops, so the app starts the new one; not mid-edit
    PORT="${EDITBAY_PORT:-$(sed -n 's/.*"port": *\([0-9]*\).*/\1/p' "${EDITBAY_DATA:-$HOME_DIR/data}/settings.json" 2>/dev/null)}"
    PORT="${PORT:-4747}"
    if CHAT="$(curl -s -m 2 "http://localhost:$PORT/api/chat")"; then
        if printf '%s' "$CHAT" | grep -q '"busy": *true'; then
            echo "Claude is in the middle of an edit, so the old version keeps running until it's done."
            echo "Afterwards, choose Edit Bay > Restart Server in the app's menu."
        else
            kill $(lsof -ti "tcp:$PORT" -sTCP:LISTEN) 2>/dev/null || true
        fi
    fi
fi

if [ "$(installed "$APP/Contents/Resources/app/SHELL_VERSION")" != "$SHELL_VERSION" ]; then
    say "Downloading the app (about 100 MB)"
    fetch "$SHELL_URL" "$SHELL_SHA" "$TMP/shell.zip"
    ditto -x -k "$TMP/shell.zip" "$TMP/shell"
    # quit this copy of the app first: the window only. The server runs on the same binary and
    # keeps going, so a chat turn or upload isn't cut off.
    for pid in $(pgrep -f "$APP/Contents/MacOS/Electron" || true); do
        ps -o command= -p "$pid" | grep -q -E 'server\.js|editbay\.js' || kill "$pid" 2>/dev/null || true
    done
    sleep 1
    mkdir -p "$(dirname "$APP")"
    rm -rf "$APP"
    mv "$TMP/shell/Hey Joe Edit Bay.app" "$APP"
    echo "$SHELL_VERSION" > "$APP/Contents/Resources/app/SHELL_VERSION"
fi

# the loader: everything it needs to know is where the rest lives
printf '// written by install.sh\nprocess.env.EDITBAY_HOME = process.env.EDITBAY_HOME || %s;\nrequire(require("path").join(process.env.EDITBAY_HOME, "code", "desktop", "start.js"));\n' \
    "$(printf '%s' "$HOME_DIR" | sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/"/')" > "$APP/Contents/Resources/app/main.js"
xattr -cr "$APP" 2>/dev/null || true
codesign --force --deep --sign - "$APP" 2>/dev/null || true
touch "$APP"

say "Done. Opening Hey Joe Edit Bay."
echo "It will walk you through signing in to Claude the first time."
[ -n "${EDITBAY_NO_OPEN:-}" ] || open "$APP"
