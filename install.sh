#!/usr/bin/env bash
# ============================================================
#  live-host installer
#  Supports: Ubuntu/Debian, Fedora/RHEL, Arch, macOS (Homebrew)
#  Usage:
#    Auto  : curl -fsSL https://raw.githubusercontent.com/apeart30/live-host/master/install.sh | bash
#    Manual: bash install.sh --manual
# ============================================================

set -e

REPO_RAW="https://raw.githubusercontent.com/apeart30/live-host/master/live-host.py"
INSTALL_DIR="$HOME/tools"
SCRIPT_NAME="live-host.py"
ALIAS_LINE="alias live-host='python3 \$HOME/tools/live-host.py'"

# ── colours ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
  echo -e "${CYAN}${BOLD}"
  echo "  ██╗     ██╗██╗   ██╗███████╗    ██╗  ██╗ ██████╗ ███████╗████████╗"
  echo "  ██║     ██║██║   ██║██╔════╝    ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝"
  echo "  ██║     ██║██║   ██║█████╗      ███████║██║   ██║███████╗   ██║   "
  echo "  ██║     ██║╚██╗ ██╔╝██╔══╝      ██╔══██║██║   ██║╚════██║   ██║   "
  echo "  ███████╗██║ ╚████╔╝ ███████╗    ██║  ██║╚██████╔╝███████║   ██║   "
  echo "  ╚══════╝╚═╝  ╚═══╝  ╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   "
  echo -e "${NC}"
  echo -e "  ${BOLD}Fast multithreaded subnet host discovery${NC}"
  echo "  github.com/apeart30/live-host"
  echo ""
}

info()    { echo -e "  ${GREEN}[+]${NC} $*"; }
warn()    { echo -e "  ${YELLOW}[!]${NC} $*"; }
error()   { echo -e "  ${RED}[✗]${NC} $*"; exit 1; }
section() { echo -e "\n  ${CYAN}──────────────────────────────────────${NC}\n  ${BOLD}$*${NC}"; }

# ── manual instructions ─────────────────────────────────────
manual_mode() {
  banner
  section "Manual Installation Guide"
  echo ""
  echo -e "  ${BOLD}Step 1 — Ensure Python 3 is installed${NC}"
  echo ""
  echo "    Linux (Debian/Ubuntu):  sudo apt install -y python3"
  echo "    Linux (Fedora/RHEL):    sudo dnf install -y python3"
  echo "    Linux (Arch):           sudo pacman -S python"
  echo "    macOS (Homebrew):       brew install python3"
  echo ""
  echo -e "  ${BOLD}Step 2 — Create tools directory & download script${NC}"
  echo ""
  echo "    mkdir -p \$HOME/tools"
  echo "    curl -fsSL $REPO_RAW -o \$HOME/tools/$SCRIPT_NAME"
  echo "    chmod +x \$HOME/tools/$SCRIPT_NAME"
  echo ""
  echo -e "  ${BOLD}Step 3 — Add alias to your shell${NC}"
  echo ""
  echo "    # For bash:"
  echo "    echo \"$ALIAS_LINE\" >> ~/.bashrc && source ~/.bashrc"
  echo ""
  echo "    # For zsh:"
  echo "    echo \"$ALIAS_LINE\" >> ~/.zshrc  && source ~/.zshrc"
  echo ""
  echo -e "  ${BOLD}Step 4 — Run it${NC}"
  echo ""
  echo "    live-host 192.168.1.0/24"
  echo ""
  echo -e "  ${BOLD}One-liner auto installer (does all the above)${NC}"
  echo ""
  echo -e "  ${YELLOW}curl -fsSL $REPO_RAW | bash${NC}"
  echo ""
  echo -e "  Or with wget:"
  echo -e "  ${YELLOW}bash <(wget -qO- https://raw.githubusercontent.com/apeart30/live-host/master/install.sh)${NC}"
  echo ""
  exit 0
}

# ── detect os/pkg manager ───────────────────────────────────
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian|linuxmint|pop)   OS="debian" ;;
      fedora|rhel|centos|rocky|alma) OS="fedora" ;;
      arch|manjaro|endeavouros)      OS="arch"   ;;
      *)                             OS="unknown" ;;
    esac
  else
    OS="unknown"
  fi
}

# ── ensure python3 ──────────────────────────────────────────
ensure_python() {
  if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1)
    info "Python found: $PY_VER"
    return
  fi
  warn "Python 3 not found — installing..."
  case "$OS" in
    debian) sudo apt-get update -qq && sudo apt-get install -y python3 ;;
    fedora) sudo dnf install -y python3 ;;
    arch)   sudo pacman -Sy --noconfirm python ;;
    macos)
      if ! command -v brew &>/dev/null; then
        warn "Homebrew not found — installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew install python3
      ;;
    *)
      error "Cannot auto-install Python on this OS. Run with --manual for instructions."
      ;;
  esac
  command -v python3 &>/dev/null || error "Python 3 installation failed."
  info "Python installed: $(python3 --version)"
}

# ── ensure curl or wget ─────────────────────────────────────
ensure_downloader() {
  if command -v curl &>/dev/null; then
    DOWNLOADER="curl"
  elif command -v wget &>/dev/null; then
    DOWNLOADER="wget"
  else
    warn "Neither curl nor wget found — installing curl..."
    case "$OS" in
      debian) sudo apt-get install -y curl ;;
      fedora) sudo dnf install -y curl ;;
      arch)   sudo pacman -Sy --noconfirm curl ;;
      macos)  brew install curl ;;
      *)      error "Cannot install curl. Install it manually and re-run." ;;
    esac
    DOWNLOADER="curl"
  fi
  info "Downloader: $DOWNLOADER"
}

# ── download script ─────────────────────────────────────────
download_script() {
  mkdir -p "$INSTALL_DIR"
  info "Downloading live-host.py to $INSTALL_DIR ..."
  if [[ "$DOWNLOADER" == "curl" ]]; then
    curl -fsSL "$REPO_RAW" -o "$INSTALL_DIR/$SCRIPT_NAME"
  else
    wget -qO "$INSTALL_DIR/$SCRIPT_NAME" "$REPO_RAW"
  fi
  chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
  info "Script saved: $INSTALL_DIR/$SCRIPT_NAME"
}

# ── verify script runs ──────────────────────────────────────
verify_install() {
  if python3 "$INSTALL_DIR/$SCRIPT_NAME" 2>&1 | grep -qi "usage"; then
    info "Smoke test passed — script responds correctly."
  else
    warn "Smoke test inconclusive (expected usage line). Script may still work fine."
  fi
}

# ── add alias to shell rc files ──────────────────────────────
add_alias() {
  local added=0
  for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$RC" ]]; then
      if grep -q "live-host" "$RC"; then
        info "Alias already present in $RC — skipping."
      else
        echo "" >> "$RC"
        echo "# live-host — fast subnet scanner" >> "$RC"
        echo "$ALIAS_LINE" >> "$RC"
        info "Alias added to $RC"
        added=1
      fi
    fi
  done
  # create .bashrc with alias if neither existed
  if [[ $added -eq 0 ]] && ! grep -q "live-host" "$HOME/.bashrc" 2>/dev/null; then
    echo "$ALIAS_LINE" >> "$HOME/.bashrc"
    info "Alias added to $HOME/.bashrc (created)"
  fi
}

# ── final instructions ───────────────────────────────────────
print_done() {
  section "Installation complete"
  echo ""
  echo -e "  ${BOLD}Reload your shell, then run:${NC}"
  echo ""
  echo -e "    ${GREEN}source ~/.bashrc${NC}   # or: source ~/.zshrc"
  echo -e "    ${GREEN}live-host 192.168.1.0/24${NC}"
  echo ""
  echo -e "  Or run directly without reloading:"
  echo -e "    ${GREEN}python3 ~/tools/live-host.py 192.168.1.0/24${NC}"
  echo ""
}

# ── entry point ──────────────────────────────────────────────
main() {
  if [[ "${1:-}" == "--manual" || "${1:-}" == "-m" ]]; then
    manual_mode
  fi

  banner
  section "Auto Installer"
  detect_os
  info "Detected OS type: $OS"
  ensure_python
  ensure_downloader
  download_script
  verify_install
  add_alias
  print_done
}

main "$@"
