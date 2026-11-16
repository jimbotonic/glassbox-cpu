#!/usr/bin/env bash
# Install the Flutter SDK on Linux and fetch this project's dependencies.
#
# Usage:
#   bash scripts/install_flutter.sh [--dir PATH] [--channel stable|beta] [--linux-desktop] [--no-path]
#
#   --dir PATH        Where to put the SDK (default: $HOME/dev/flutter, or $FLUTTER_HOME)
#   --channel NAME    Flutter channel to clone (default: stable)
#   --linux-desktop   Also install the apt packages needed for `flutter run -d linux`
#                     (needs sudo; not needed for `flutter test` or web builds)
#   --no-path         Do not add the SDK to PATH in ~/.bashrc and ~/.profile
#
# The script can be run again safely: an existing SDK is upgraded instead of re-cloned.
set -euo pipefail

FLUTTER_DIR="${FLUTTER_HOME:-$HOME/dev/flutter}"
CHANNEL="stable"
LINUX_DESKTOP=0
UPDATE_PATH=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) FLUTTER_DIR="$2"; shift 2 ;;
    --channel) CHANNEL="$2"; shift 2 ;;
    --linux-desktop) LINUX_DESKTOP=1; shift ;;
    --no-path) UPDATE_PATH=0; shift ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

step() { printf '\n==> %s\n' "$*"; }

step "Checking required tools"
missing=()
for tool in git curl unzip xz tar which; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if (( ${#missing[@]} )); then
  echo "Missing tools: ${missing[*]}" >&2
  echo "On Debian/Ubuntu: sudo apt-get install -y git curl unzip xz-utils tar debianutils" >&2
  exit 1
fi

if [[ -x "$FLUTTER_DIR/bin/flutter" ]]; then
  step "Flutter already in $FLUTTER_DIR, upgrading on channel $CHANNEL"
  "$FLUTTER_DIR/bin/flutter" channel "$CHANNEL"
  "$FLUTTER_DIR/bin/flutter" upgrade
else
  step "Cloning Flutter ($CHANNEL) into $FLUTTER_DIR"
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  # Full history on one branch: shallow clones break `flutter --version`.
  git clone --branch "$CHANNEL" --single-branch https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

if (( UPDATE_PATH )); then
  step "Adding $FLUTTER_DIR/bin to PATH"
  line="export PATH=\"$FLUTTER_DIR/bin:\$PATH\""
  for rc in "$HOME/.bashrc" "$HOME/.profile"; do
    if [[ -f "$rc" ]] && grep -qF "$FLUTTER_DIR/bin" "$rc"; then
      echo "  already in $rc"
    else
      printf '\n# Flutter SDK (added by glassbox-cpu scripts/install_flutter.sh)\n%s\n' "$line" >> "$rc"
      echo "  added to $rc"
    fi
  done
fi

if (( LINUX_DESKTOP )); then
  step "Installing Linux desktop build dependencies (sudo)"
  sudo apt-get update
  sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
fi

step "Downloading the Dart SDK and tools"
flutter --disable-analytics >/dev/null 2>&1 || true
flutter --version

step "Fetching project dependencies"
if ! (cd "$PROJECT_DIR" && flutter pub get); then
  rm -f "$PROJECT_DIR"/flutter_*.log
  if [[ -f "$PROJECT_DIR/.dart_tool/package_config.json" ]]; then
    # Typical on network shares (CIFS/SMB): packages resolve, but Flutter cannot
    # create the plugin symlinks under <platform>/flutter/ephemeral/.
    echo "WARNING: packages were resolved, but Flutter could not finish (often: the" >&2
    echo "project folder does not support symlinks, e.g. a network share)." >&2
    echo "flutter test / analyze / run -d chrome still work; desktop builds need a local clone." >&2
  else
    echo "flutter pub get failed." >&2
    exit 1
  fi
fi

step "flutter doctor"
flutter doctor || true

cat <<EOF

Flutter is installed in $FLUTTER_DIR.
Open a new terminal (or run: export PATH="$FLUTTER_DIR/bin:\$PATH"), then:
  flutter test           # run the test suite
  flutter run -d chrome  # run the app in a browser
EOF
