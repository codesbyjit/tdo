#!/usr/bin/env bash
# =============================================
# 🌟 TDO INSTALLER - Smart Cross-Platform Installer
# - Uses a local binary if present (target/release/tdo or ./tdo)
# - Else downloads from GitHub Releases
# - Else attempts to build with cargo if available
# - Installs to ~/.local/bin (user) or /usr/local/bin (system)
# =============================================

set -euo pipefail
IFS=$'\n\t'

# CONFIG — change these if your repo or release names differ
REPO="codesbyjit/tdo"
GITHUB_BASE="https://github.com/${REPO}/releases/latest/download"
LOCAL_BIN_NAMES=("tdo" "target/release/tdo" "./tdo")

# COLORS
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

# Spinner (runs while a background command runs)
spinner_start() {
  # usage: long_running_command & spinner_start $!
  local pid="$1"
  local delay=0.08
  local spinstr='|/-\'
  printf " "
  while kill -0 "$pid" 2>/dev/null; do
    for c in ${spinstr//?/ }; do
      printf "\b%c" "$c"
      sleep $delay
    done
  done
  printf "\b" # erase spinner char
}

# pretty log helpers
info()  { printf "${CYAN}➜ %s${RESET}\n" "$1"; }
ok()    { printf "${GREEN}✔ %s${RESET}\n" "$1"; }
warn()  { printf "${YELLOW}⚠ %s${RESET}\n" "$1"; }
err()   { printf "${RED}✖ %s${RESET}\n" "$1"; }

# banner
clear
echo -e "${CYAN}"
echo "========================================="
echo "     🚀 Installing TDO CLI (tdo)"
echo "========================================="
echo -e "${RESET}"
sleep 0.4

# OS detection
OS_NAME="$(uname -s)"
PLATFORM=""
case "$OS_NAME" in
  Linux*)   PLATFORM="linux" ;;
  Darwin*)  PLATFORM="mac" ;;
  CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
  *)        PLATFORM="unknown" ;;
esac

info "Detected platform: $PLATFORM"

# pick install target for Unix-like; try user-local first
USER_INSTALL_DIR="$HOME/.local/bin"
SYSTEM_INSTALL_DIR="/usr/local/bin"

# helper: check for local binary (returns path or empty)
find_local_binary() {
  for p in "${LOCAL_BIN_NAMES[@]}"; do
    if [ -f "$p" ] && [ -x "$p" ]; then
      printf "%s" "$p"
      return 0
    fi
    # also check target/release/tdo relative path
    if [ -f "$p" ]; then
      # try make it executable
      chmod +x "$p" 2>/dev/null || true
      if [ -x "$p" ]; then
        printf "%s" "$p"
        return 0
      fi
    fi
  done
  return 1
}

# Try local binary first
LOCAL_BIN_PATH=""
if BIN=$(find_local_binary); then
  LOCAL_BIN_PATH="$BIN"
  ok "Found local binary: $LOCAL_BIN_PATH"
fi

# If no local, try downloading from GitHub Releases
DOWNLOAD_PATH=""
if [ -z "$LOCAL_BIN_PATH" ]; then
  info "No local binary found. Trying to download prebuilt release from GitHub..."
  # choose asset name by platform
  if [ "$PLATFORM" = "windows" ]; then
    ASSET_NAME="tdo.exe"
  else
    ASSET_NAME="tdo"
  fi

  TMP_DL="$(mktemp -t tdo_installer.XXXXXX)"
  # run curl in background so spinner works
  (
    set -x
    curl -fSL -o "$TMP_DL" "${GITHUB_BASE}/${ASSET_NAME}"
  ) &
  pid=$!
  spinner_start "$pid"
  wait "$pid" || {
    warn "Download from GitHub failed or asset not found."
    rm -f "$TMP_DL"
    TMP_DL=""
  }

  if [ -n "$TMP_DL" ] && [ -f "$TMP_DL" ]; then
    chmod +x "$TMP_DL" || true
    DOWNLOAD_PATH="$TMP_DL"
    ok "Downloaded binary to temporary path"
  fi
fi

# If neither local nor download succeeded, try to build if cargo available
BUILT_PATH=""
if [ -z "$LOCAL_BIN_PATH" ] && [ -z "$DOWNLOAD_PATH" ]; then
  if command -v cargo >/dev/null 2>&1; then
    info "No prebuilt binary available — building from source with cargo..."
    (cargo build --release) &
    pid=$!
    spinner_start "$pid"
    wait "$pid"
    # expected path
    if [ -f "target/release/tdo" ]; then
      chmod +x target/release/tdo || true
      BUILT_PATH="target/release/tdo"
      ok "Built binary at $BUILT_PATH"
    else
      err "Build finished but binary not found at target/release/tdo"
    fi
  else
    err "No cargo available to build from source."
  fi
fi

# Choose final source binary
SRC_BIN="${LOCAL_BIN_PATH:-${DOWNLOAD_PATH:-${BUILT_PATH:-}}}"

if [ -z "$SRC_BIN" ]; then
  err "Installation failed: no binary available (tried local, download, build)."
  exit 1
fi

# Install step (Unix-like / macOS)
if [ "$PLATFORM" = "linux" ] || [ "$PLATFORM" = "mac" ]; then
  # Prefer user install (< no sudo) unless user wants system install (detect if running as root)
  if [ "$(id -u)" -eq 0 ]; then
    # root -> install system wide
    info "Installing system-wide to ${SYSTEM_INSTALL_DIR} (running as root)"
    cp "$SRC_BIN" "${SYSTEM_INSTALL_DIR}/tdo"
    chmod 755 "${SYSTEM_INSTALL_DIR}/tdo"
    ok "Installed to ${SYSTEM_INSTALL_DIR}/tdo"
  else
    # try user local dir
    mkdir -p "$USER_INSTALL_DIR"
    info "Installing to ${USER_INSTALL_DIR}"
    cp "$SRC_BIN" "${USER_INSTALL_DIR}/tdo"
    chmod 755 "${USER_INSTALL_DIR}/tdo"
    ok "Installed to ${USER_INSTALL_DIR}/tdo"
    # ensure PATH contains it
    if ! echo "$PATH" | tr ':' '\n' | grep -qx "$USER_INSTALL_DIR"; then
      SHELL_RC=""
      # prefer bash, then zsh
      if [ -n "${BASH_VERSION:-}" ]; then SHELL_RC="$HOME/.bashrc"
      elif [ -n "${ZSH_VERSION:-}" ]; then SHELL_RC="$HOME/.zshrc"
      else SHELL_RC="$HOME/.profile"
      fi
      echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
      warn "Updated ${SHELL_RC} to include ~/.local/bin. Reload or open a new shell to use 'tdo'."
    fi
  fi

# Windows handling (msys/cygwin)
elif [ "$PLATFORM" = "windows" ]; then
  DEST="$HOME/.tdo/bin"
  mkdir -p "$DEST"
  info "Installing to $DEST"
  if [[ "$SRC_BIN" == *.exe ]] || file "$SRC_BIN" | grep -qi 'executable'; then
    cp "$SRC_BIN" "$DEST/tdo.exe"
    ok "Installed to $DEST/tdo.exe"
  else
    # if we downloaded a non-exe on windows, still copy and warn
    cp "$SRC_BIN" "$DEST/tdo.exe"
    ok "Installed to $DEST/tdo.exe"
  fi
  # add to PATH for bash-like shells
  SHELL_RC="$HOME/.bashrc"
  if ! grep -q 'HOME/.tdo/bin' "$SHELL_RC" 2>/dev/null; then
    echo 'export PATH="$HOME/.tdo/bin:$PATH"' >> "$SHELL_RC"
    warn "Added $DEST to PATH in $SHELL_RC. Restart terminal or add to Windows PATH manually."
  fi

else
  err "Unsupported platform: $PLATFORM"
  exit 1
fi

echo
ok "Installation finished. Try: tdo --help"

# clean temporary download if present and not the chosen local/built path
if [ -n "${DOWNLOAD_PATH:-}" ] && [ "$DOWNLOAD_PATH" != "$SRC_BIN" ]; then
  rm -f "$DOWNLOAD_PATH"
fi

exit 0
