#!/usr/bin/env bash
# =============================================
# 🧹 TDO UNINSTALLER - Cross Platform
# - Removes installed tdo binary
# - Cleans PATH entries if needed
# =============================================

set -euo pipefail
IFS=$'\n\t'

# --- Colors ---
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

# --- Spinner ---
spinner_start() {
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
  printf "\b"
}

# --- Log helpers ---
info()  { printf "${CYAN}➜ %s${RESET}\n" "$1"; }
ok()    { printf "${GREEN}✔ %s${RESET}\n" "$1"; }
warn()  { printf "${YELLOW}⚠ %s${RESET}\n" "$1"; }
err()   { printf "${RED}✖ %s${RESET}\n" "$1"; }

# --- Banner ---
clear
echo -e "${CYAN}"
echo "========================================="
echo "     🧹 Uninstalling TDO CLI"
echo "========================================="
echo -e "${RESET}"
sleep 0.4

# --- OS detection ---
OS_NAME="$(uname -s)"
PLATFORM="unknown"
case "$OS_NAME" in
  Linux*)   PLATFORM="linux" ;;
  Darwin*)  PLATFORM="mac" ;;
  CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
esac

info "Detected platform: $PLATFORM"

# --- Common uninstall paths ---
USER_LOCAL="$HOME/.local/bin/tdo"
SYSTEM_BIN="/usr/local/bin/tdo"
WINDOWS_BIN="$HOME/.tdo/bin/tdo.exe"

FOUND=false

remove_file() {
  local f="$1"
  if [ -f "$f" ]; then
    (
      rm -f "$f"
    ) &
    pid=$!
    spinner_start "$pid"
    wait "$pid"
    ok "Removed: $f"
    FOUND=true
  fi
}

# --- Remove binaries ---
info "Checking common install locations..."
remove_file "$USER_LOCAL"
remove_file "$SYSTEM_BIN"
remove_file "$WINDOWS_BIN"

# --- Clean PATH entries in shell rc files ---
clean_path_entry() {
  local file="$1"
  local path="$2"
  if [ -f "$file" ]; then
    if grep -q "$path" "$file"; then
      sed -i.bak "/$path/d" "$file"
      ok "Removed PATH entry from $file"
    fi
  fi
}

if [ "$PLATFORM" != "windows" ]; then
  clean_path_entry "$HOME/.bashrc" "\$HOME/.local/bin"
  clean_path_entry "$HOME/.zshrc" "\$HOME/.local/bin"
  clean_path_entry "$HOME/.profile" "\$HOME/.local/bin"
else
  clean_path_entry "$HOME/.bashrc" "\$HOME/.tdo/bin"
fi

# --- Final message ---
if [ "$FOUND" = true ]; then
  ok "TDO successfully uninstalled!"
else
  warn "No TDO binary found on your system."
fi

echo
echo -e "${YELLOW}If you installed manually elsewhere, remove it manually with:${RESET}"
echo -e "  ${CYAN}sudo rm -f /usr/local/bin/tdo${RESET}"
echo
ok "Uninstall complete!"
exit 0
