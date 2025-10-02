#!/usr/bin/env bash
# Shell installation helper script for nvm test environments
# This script helps set up all required shells for testing nvm

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}nvm Test Shell Installation Helper${NC}"
echo "===================================="
echo ""
echo "This script will help you install the shells required for testing nvm:"
echo "  - bash (usually pre-installed)"
echo "  - zsh"
echo "  - dash"
echo "  - sh (usually a symlink to bash or dash)"
echo "  - ksh (optional, experimental support)"
echo ""

# Detect OS
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
  elif [ "$(uname)" = "Darwin" ]; then
    OS="macos"
    OS_VERSION=$(sw_vers -productVersion)
  else
    OS="unknown"
  fi
  
  echo -e "Detected OS: ${GREEN}${OS}${NC} ${OS_VERSION:-}"
  echo ""
}

# Check which shells are already installed
check_installed_shells() {
  echo "Checking installed shells..."
  echo ""
  
  SHELLS_TO_INSTALL=""
  
  if command -v bash >/dev/null 2>&1; then
    BASH_VERSION=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    echo -e "  ${GREEN}✓${NC} bash ${BASH_VERSION}"
  else
    echo -e "  ${RED}✗${NC} bash (not found)"
    SHELLS_TO_INSTALL="$SHELLS_TO_INSTALL bash"
  fi
  
  if command -v zsh >/dev/null 2>&1; then
    ZSH_VERSION=$(zsh --version | grep -oE '[0-9]+\.[0-9]+' || echo "unknown")
    echo -e "  ${GREEN}✓${NC} zsh ${ZSH_VERSION}"
  else
    echo -e "  ${RED}✗${NC} zsh (not found)"
    SHELLS_TO_INSTALL="$SHELLS_TO_INSTALL zsh"
  fi
  
  if command -v dash >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} dash"
  else
    echo -e "  ${RED}✗${NC} dash (not found)"
    SHELLS_TO_INSTALL="$SHELLS_TO_INSTALL dash"
  fi
  
  if command -v sh >/dev/null 2>&1; then
    SH_TARGET=$(readlink -f "$(command -v sh)" 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✓${NC} sh (${SH_TARGET})"
  else
    echo -e "  ${YELLOW}⚠${NC}  sh (not found, but usually available)"
  fi
  
  if command -v ksh >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} ksh (optional)"
  else
    echo -e "  ${YELLOW}⚠${NC}  ksh (not found, optional)"
  fi
  
  echo ""
}

# Install shells based on OS
install_shells_ubuntu() {
  echo -e "${BLUE}Installing shells on Ubuntu/Debian...${NC}"
  echo ""
  
  if [ -z "$SHELLS_TO_INSTALL" ]; then
    echo "All required shells are already installed!"
    return 0
  fi
  
  echo "Shells to install:$SHELLS_TO_INSTALL"
  echo ""
  
  echo "This will run:"
  echo "  sudo apt-get update"
  echo "  sudo apt-get install -y$SHELLS_TO_INSTALL"
  echo ""
  
  read -p "Continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
  fi
  
  echo ""
  sudo apt-get update -qq
  sudo apt-get install -y $SHELLS_TO_INSTALL
  
  echo ""
  echo -e "${GREEN}Installation complete!${NC}"
}

install_shells_macos() {
  echo -e "${BLUE}Installing shells on macOS...${NC}"
  echo ""
  
  # Check if Homebrew is installed
  if ! command -v brew >/dev/null 2>&1; then
    echo -e "${RED}Error: Homebrew is not installed.${NC}"
    echo ""
    echo "Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    exit 1
  fi
  
  if [ -z "$SHELLS_TO_INSTALL" ]; then
    echo "All required shells are already installed!"
    return 0
  fi
  
  echo "Shells to install:$SHELLS_TO_INSTALL"
  echo ""
  
  echo "This will run:"
  echo "  brew install$SHELLS_TO_INSTALL"
  echo ""
  
  read -p "Continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
  fi
  
  echo ""
  for shell in $SHELLS_TO_INSTALL; do
    brew install "$shell"
  done
  
  echo ""
  echo -e "${GREEN}Installation complete!${NC}"
}

# Verify installation
verify_installation() {
  echo ""
  echo "Verifying installation..."
  echo ""
  
  ALL_OK=1
  
  for shell in bash zsh dash; do
    if command -v "$shell" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} $shell is available"
      
      # Test that the shell works
      if $shell -c "echo test" >/dev/null 2>&1; then
        echo -e "    ${GREEN}✓${NC} $shell executes correctly"
      else
        echo -e "    ${RED}✗${NC} $shell fails to execute"
        ALL_OK=0
      fi
    else
      echo -e "  ${RED}✗${NC} $shell is not available"
      ALL_OK=0
    fi
  done
  
  echo ""
  
  if [ $ALL_OK -eq 1 ]; then
    echo -e "${GREEN}All required shells are installed and working!${NC}"
    echo ""
    echo "You can now run tests with:"
    echo "  make test          # Test in all shells"
    echo "  make test-bash     # Test in bash"
    echo "  make test-zsh      # Test in zsh"
    echo "  make test-dash     # Test in dash"
    echo "  npm test           # Default test"
    return 0
  else
    echo -e "${RED}Some shells are missing or not working properly.${NC}"
    echo "Please install them manually or check the error messages above."
    return 1
  fi
}

# Main execution
main() {
  detect_os
  check_installed_shells
  
  if [ -z "$SHELLS_TO_INSTALL" ]; then
    echo -e "${GREEN}All required shells are already installed!${NC}"
    verify_installation
    exit 0
  fi
  
  case "$OS" in
    ubuntu|debian)
      install_shells_ubuntu
      ;;
    macos)
      install_shells_macos
      ;;
    fedora|centos|rhel)
      echo -e "${YELLOW}Note: Installation on ${OS} requires manual steps.${NC}"
      echo ""
      echo "Please install the shells manually:"
      echo "  sudo dnf install$SHELLS_TO_INSTALL"
      echo "or"
      echo "  sudo yum install$SHELLS_TO_INSTALL"
      exit 1
      ;;
    *)
      echo -e "${RED}Unsupported OS: ${OS}${NC}"
      echo ""
      echo "Please install the following shells manually:"
      echo " $SHELLS_TO_INSTALL"
      exit 1
      ;;
  esac
  
  verify_installation
}

# Run main if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
