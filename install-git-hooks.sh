#!/usr/bin/env bash
# Git hooks installation script for nvm development
# Sets up pre-commit hooks to catch issues before committing

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}nvm Git Hooks Installer${NC}"
echo "======================="
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
  echo -e "${RED}Error: Not in a git repository${NC}"
  echo "Please run this script from the root of the nvm repository."
  exit 1
fi

# Check if hooks directory exists
if [ ! -d ".git/hooks" ]; then
  echo -e "${YELLOW}Warning: .git/hooks directory not found${NC}"
  echo "Creating .git/hooks directory..."
  mkdir -p .git/hooks
fi

# Available hooks
declare -A AVAILABLE_HOOKS
AVAILABLE_HOOKS[pre-commit]="pre-commit-check.sh"

# Function to install a hook
install_hook() {
  local hook_name=$1
  local source_script=$2
  local hook_path=".git/hooks/${hook_name}"

  # Check if source script exists
  if [ ! -f "$source_script" ]; then
    echo -e "${RED}✗${NC} Source script not found: $source_script"
    return 1
  fi

  # Check if hook already exists
  if [ -f "$hook_path" ] || [ -L "$hook_path" ]; then
    echo -e "${YELLOW}⚠${NC}  Hook already exists: $hook_path"

    # Check if it's a symlink to our script
    if [ -L "$hook_path" ]; then
      local link_target
      link_target=$(readlink "$hook_path")
      if [ "$link_target" = "../../${source_script}" ]; then
        echo -e "   ${GREEN}✓${NC} Already linked correctly"
        return 0
      fi
    fi

    echo ""
    read -p "   Overwrite existing hook? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "   ${YELLOW}Skipped${NC}"
      return 0
    fi

    # Backup existing hook
    local backup
    backup="${hook_path}.backup.$(date +%s)"
    mv "$hook_path" "$backup"
    echo -e "   ${GREEN}✓${NC} Backed up to: $(basename "$backup")"
  fi

  # Create symlink
  ln -s "../../${source_script}" "$hook_path"
  chmod +x "$hook_path"

  echo -e "${GREEN}✓${NC} Installed: $hook_name -> $source_script"
  return 0
}

# Function to uninstall a hook
uninstall_hook() {
  local hook_name=$1
  local hook_path=".git/hooks/${hook_name}"

  if [ ! -f "$hook_path" ] && [ ! -L "$hook_path" ]; then
    echo -e "${YELLOW}⚠${NC}  Hook not installed: $hook_name"
    return 0
  fi

  # Check if it's our symlink
  if [ -L "$hook_path" ]; then
    local link_target
    link_target=$(readlink "$hook_path")
    if [[ "$link_target" == ../../* ]]; then
      rm "$hook_path"
      echo -e "${GREEN}✓${NC} Uninstalled: $hook_name"
      return 0
    fi
  fi

  echo -e "${YELLOW}⚠${NC}  Hook exists but is not managed by this script: $hook_name"
  echo ""
  read -p "   Remove it anyway? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm "$hook_path"
    echo -e "${GREEN}✓${NC} Removed: $hook_name"
  fi
}

# Function to list hooks
list_hooks() {
  echo "Available hooks:"
  echo ""

  for hook_name in "${!AVAILABLE_HOOKS[@]}"; do
    local source_script="${AVAILABLE_HOOKS[$hook_name]}"
    local hook_path=".git/hooks/${hook_name}"

    printf "  %-15s -> %-25s " "$hook_name" "$source_script"

    if [ -L "$hook_path" ]; then
      local link_target
      link_target=$(readlink "$hook_path")
      if [ "$link_target" = "../../${source_script}" ]; then
        echo -e "${GREEN}[installed]${NC}"
      else
        echo -e "${YELLOW}[installed, custom]${NC}"
      fi
    elif [ -f "$hook_path" ]; then
      echo -e "${YELLOW}[exists, not linked]${NC}"
    else
      echo -e "${RED}[not installed]${NC}"
    fi
  done
  echo ""
}

# Main menu
show_menu() {
  echo ""
  echo "What would you like to do?"
  echo ""
  echo "  1) Install all hooks"
  echo "  2) Install pre-commit hook only"
  echo "  3) Uninstall all hooks"
  echo "  4) Uninstall pre-commit hook"
  echo "  5) List hook status"
  echo "  6) Exit"
  echo ""
}

# Process user choice
process_choice() {
  read -r -p "Enter choice [1-6]: " choice
  echo ""

  case $choice in
    1)
      echo "Installing all hooks..."
      echo ""
      for hook_name in "${!AVAILABLE_HOOKS[@]}"; do
        install_hook "$hook_name" "${AVAILABLE_HOOKS[$hook_name]}"
      done
      echo ""
      echo -e "${GREEN}✓ Installation complete${NC}"
      ;;
    2)
      install_hook "pre-commit" "${AVAILABLE_HOOKS[pre-commit]}"
      ;;
    3)
      echo "Uninstalling all hooks..."
      echo ""
      for hook_name in "${!AVAILABLE_HOOKS[@]}"; do
        uninstall_hook "$hook_name"
      done
      echo ""
      echo -e "${GREEN}✓ Uninstallation complete${NC}"
      ;;
    4)
      uninstall_hook "pre-commit"
      ;;
    5)
      list_hooks
      return 1  # Return to menu
      ;;
    6)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice${NC}"
      return 1  # Return to menu
      ;;
  esac

  return 0
}

# Main execution
main() {
  # Check if running with arguments
  if [ $# -gt 0 ]; then
    case "$1" in
      install)
        echo "Installing all hooks..."
        echo ""
        for hook_name in "${!AVAILABLE_HOOKS[@]}"; do
          install_hook "$hook_name" "${AVAILABLE_HOOKS[$hook_name]}"
        done
        exit 0
        ;;
      uninstall)
        echo "Uninstalling all hooks..."
        echo ""
        for hook_name in "${!AVAILABLE_HOOKS[@]}"; do
          uninstall_hook "$hook_name"
        done
        exit 0
        ;;
      list)
        list_hooks
        exit 0
        ;;
      *)
        echo "Usage: $0 [install|uninstall|list]"
        echo ""
        echo "  install     Install all git hooks"
        echo "  uninstall   Uninstall all git hooks"
        echo "  list        List hook status"
        echo ""
        echo "Run without arguments for interactive menu."
        exit 1
        ;;
    esac
  fi

  # Interactive mode
  list_hooks

  while true; do
    show_menu
    if process_choice; then
      break
    fi
  done

  echo ""
  echo -e "${GREEN}Done!${NC}"
  echo ""
  echo "Note: You can bypass hooks with 'git commit --no-verify' if needed."
}

# Run main if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
