#!/usr/bin/env bash
# Version consistency checker for nvm
# Ensures all version references are in sync across files
# shellcheck disable=SC2034,SC2317

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}nvm Version Consistency Checker${NC}"
echo "================================"
echo ""

# Files that should contain version numbers
VERSIONED_FILES=(
  "nvm.sh"
  "install.sh"
  "README.md"
  "package.json"
)

# Track issues
ISSUES_FOUND=0

# Extract version from package.json
if [ ! -f "package.json" ]; then
  echo -e "${RED}Error: package.json not found${NC}"
  exit 1
fi

PACKAGE_VERSION=$(grep -oP '(?<="version": ")[^"]*' package.json | head -1)
if [ -z "$PACKAGE_VERSION" ]; then
  echo -e "${RED}Error: Could not extract version from package.json${NC}"
  exit 1
fi

echo -e "Reference version (from package.json): ${GREEN}${PACKAGE_VERSION}${NC}"
echo ""
echo "Checking version consistency across files..."
echo ""

# Function to check version in a file
check_file_version() {
  local file=$1
  local pattern=$2
  local context=$3

  if [ ! -f "$file" ]; then
    echo -e "${RED}✗${NC} $file - File not found"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    return 1
  fi

  # Search for version pattern
  local found_versions
  found_versions=$(grep -oP "$pattern" "$file" 2>/dev/null || true)

  if [ -z "$found_versions" ]; then
    echo -e "${RED}✗${NC} $file - No version found (pattern: $pattern)"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    return 1
  fi

  # Check each found version
  local all_match=true
  while IFS= read -r version; do
    if [ "$version" != "$PACKAGE_VERSION" ]; then
      all_match=false
      echo -e "${RED}✗${NC} $file - Version mismatch: found ${RED}$version${NC}, expected ${GREEN}$PACKAGE_VERSION${NC}"
      echo "   Context: $context"
      ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
  done <<< "$found_versions"

  if [ "$all_match" = true ]; then
    echo -e "${GREEN}✓${NC} $file - Version ${GREEN}$PACKAGE_VERSION${NC} ✓"
  fi
}

# Check nvm.sh - version command
if grep -q "nvm_echo '${PACKAGE_VERSION}'" nvm.sh; then
  echo -e "${GREEN}✓${NC} nvm.sh - Version ${GREEN}$PACKAGE_VERSION${NC} ✓"
else
  echo -e "${RED}✗${NC} nvm.sh - Version mismatch"
  echo "   Expected: nvm_echo '${PACKAGE_VERSION}'"
  grep "\"--version\"" nvm.sh -A 2 | head -3 | sed 's/^/   /'
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check install.sh - nvm_latest_version function
if grep -q "nvm_echo \"v${PACKAGE_VERSION}\"" install.sh; then
  echo -e "${GREEN}✓${NC} install.sh - Version ${GREEN}v$PACKAGE_VERSION${NC} ✓"
else
  echo -e "${RED}✗${NC} install.sh - Version mismatch"
  echo "   Expected: nvm_echo \"v${PACKAGE_VERSION}\""
  grep "nvm_latest_version" install.sh -A 2 | head -3 | sed 's/^/   /'
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check README.md - version badge
if grep -q "badge/version-v${PACKAGE_VERSION}-yellow" README.md; then
  echo -e "${GREEN}✓${NC} README.md - Badge version ${GREEN}v${PACKAGE_VERSION}${NC} ✓"
else
  echo -e "${RED}✗${NC} README.md - Badge version mismatch or not found"
  echo "   Expected: badge/version-v${PACKAGE_VERSION}-yellow"
  echo "   Found:"
  grep "badge/version-v" README.md | head -1 | sed 's/^/   /'
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check package.json explicitly (already checked but for completeness)
echo -e "${GREEN}✓${NC} package.json - Version ${GREEN}$PACKAGE_VERSION${NC} ✓"

echo ""
echo "================================"
echo ""

# Summary
if [ $ISSUES_FOUND -eq 0 ]; then
  echo -e "${GREEN}✓ All version references are consistent!${NC}"
  echo ""
  echo "Current version: ${GREEN}$PACKAGE_VERSION${NC}"
  exit 0
else
  echo -e "${RED}✗ Found $ISSUES_FOUND version consistency issue(s)${NC}"
  echo ""
  echo "To fix version inconsistencies:"
  echo "  1. Update all files to use version: $PACKAGE_VERSION"
  echo "  2. Or run: make TAG=$PACKAGE_VERSION release (maintainers only)"
  echo ""
  echo "Files to check:"
  for file in "${VERSIONED_FILES[@]}"; do
    echo "  - $file"
  done
  exit 1
fi
