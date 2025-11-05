#!/usr/bin/env bash
# 🦀 TDO - Rust CLI Todo App Installer
# Cross-platform setup with visual effects and color

set -e

# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- ASCII BANNER ---
clear
echo -e "${CYAN}"
echo "▄▄▄█████▓▓█████▄  ▒█████  "
echo "▓  ██▒ ▓▒▒██▀ ██▌▒██▒  ██▒"
echo "▒ ▓██░ ▒░░██   █▌▒██░  ██▒"
echo "░ ▓██▓ ░ ░▓█▄   ▌▒██   ██░"
echo "  ▒██▒ ░ ░▒████▓ ░ ████▓▒░"
echo "  ▒ ░░    ▒▒▓  ▒ ░ ▒░▒░▒░ "
echo "    ░     ░ ▒  ▒   ░ ▒ ▒░ "
echo "  ░       ░ ░  ░ ░ ░ ░ ▒  "
echo "            ░        ░ ░  "
echo "          ░               "
echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗"
echo -e "║             ${YELLOW}T D O${CYAN} CLI APP              ║"
echo -e "║           ${MAGENTA}Built in Rust 🦀${CYAN}             ║"
echo -e "╚══════════════════════════════════════╝${NC}"
sleep 0.8

# --- PROGRESS BAR FUNCTION ---
progress_bar() {
  local duration=${1}
  already_done() { for ((done=0; done<$elapsed; done++)); do printf "▰"; done }
  remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf "▱"; done }
  percentage() { printf "| %s%%" $(( ($elapsed*100)/$duration )); }

  for ((elapsed=1; elapsed<=duration; elapsed++)); do
    printf "\r"
    already_done; remaining; percentage
    sleep 0.05
  done
  printf "\n"
}

# --- OS DETECTION ---
OS="$(uname -s)"
echo -e "${YELLOW}🔍 Detected OS: ${OS}${NC}"
sleep 0.5

# --- BUILD APP ---
echo -e "${CYAN}⚙️  Building release (cargo build --release)...${NC}"
progress_bar 20
cargo build --release

BIN_PATH="target/release/tdo"
if [ ! -f "$BIN_PATH" ]; then
    echo -e "${RED}❌ Build failed. Binary not found.${NC}"
    exit 1
fi

# --- INSTALL LOGIC ---
case "$OS" in
    Linux*)
        echo -e "${CYAN}🐧 Installing on Linux...${NC}"
        INSTALL_DIR="$HOME/.local/bin"
        mkdir -p "$INSTALL_DIR"
        cp "$BIN_PATH" "$INSTALL_DIR/tdo"

        if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
            echo -e "${YELLOW}📦 Added ~/.local/bin to PATH (reload your terminal).${NC}"
        fi
        ;;
    MINGW*|CYGWIN*|MSYS*|Windows*)
        echo -e "${CYAN}🪟 Windows detected...${NC}"
        mkdir -p "$HOME/.tdo/bin"
        cp "$BIN_PATH.exe" "$HOME/.tdo/bin/tdo.exe"
        echo -e "${GREEN}✅ Installed to $HOME\\.tdo\\bin${NC}"
        echo -e "${YELLOW}⚠️  Add it to your PATH manually if not detected.${NC}"
        ;;
    *)
        echo -e "${RED}❌ Unsupported OS.${NC}"
        exit 1
        ;;
esac

# --- COMPLETION ---
echo ""
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo ""
echo -e "🎯 Try it out:"
echo -e "   ${YELLOW}tdo --help${NC}"
echo ""
echo -e "📝 Example usage:"
echo -e "   ${CYAN}tdo add \"Finish Rust CLI\" --due 2025-11-06${NC}"
echo -e "   ${CYAN}tdo list${NC}"
echo -e "   ${CYAN}tdo done <task_id>${NC}"
echo -e "   ${CYAN}tdo reset${NC}"
echo ""
echo -e "🌈 Enjoy your colorful Rust CLI experience!"
echo ""
