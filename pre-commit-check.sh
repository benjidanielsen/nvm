#!/usr/bin/env bash
# Pre-commit validation script for nvm development
# This script runs quick checks to catch common issues before committing

set -e

echo "Running pre-commit checks..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Track if any checks failed
FAILED=0

# Function to print status
print_status() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}✓${NC} $2"
  else
    echo -e "${RED}✗${NC} $2"
    FAILED=1
  fi
}

# Check 1: Ensure shellcheck is available
echo ""
echo "Checking for required tools..."
if command -v shellcheck >/dev/null 2>&1; then
  print_status 0 "shellcheck is installed"
else
  print_status 1 "shellcheck is not installed (install it for better validation)"
  SHELLCHECK_AVAILABLE=0
fi

# Check 2: Verify staged files exist and are readable
echo ""
echo "Checking staged files..."
STAGED_SH_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.(sh)$|^(nvm\.sh|install\.sh|nvm-exec|bash_completion)$' || true)

if [ -z "$STAGED_SH_FILES" ]; then
  echo "No shell script files staged for commit"
else
  echo "Shell scripts to validate:"
  echo "$STAGED_SH_FILES" | sed 's/^/  - /'
fi

# Check 3: Run shellcheck on staged shell script files
if [ -n "$STAGED_SH_FILES" ] && [ "${SHELLCHECK_AVAILABLE:-1}" -eq 1 ]; then
  echo ""
  echo "Running shellcheck on staged shell scripts..."
  SHELLCHECK_FAILED=0
  
  for file in $STAGED_SH_FILES; do
    if [ -f "$file" ]; then
      # Determine the shell dialect based on file
      SHELL_DIALECT="bash"
      if [ "$file" = "nvm.sh" ] || [ "$file" = "install.sh" ] || [ "$file" = "nvm-exec" ]; then
        SHELL_DIALECT="bash"
      fi
      
      if shellcheck -s "$SHELL_DIALECT" "$file" >/dev/null 2>&1; then
        print_status 0 "shellcheck passed for $file"
      else
        print_status 1 "shellcheck failed for $file"
        echo -e "${YELLOW}Run: shellcheck -s $SHELL_DIALECT $file${NC}"
        SHELLCHECK_FAILED=1
      fi
    fi
  done
  
  if [ $SHELLCHECK_FAILED -ne 0 ]; then
    FAILED=1
  fi
fi

# Check 4: Check for common mistakes
echo ""
echo "Checking for common mistakes..."

# Check for unquoted variables in staged shell scripts
if [ -n "$STAGED_SH_FILES" ]; then
  for file in $STAGED_SH_FILES; do
    if [ -f "$file" ]; then
      # Look for potentially unquoted $VAR (excluding specific patterns)
      UNQUOTED=$(grep -n '\$[A-Z_][A-Z_0-9]*[^"]' "$file" | grep -v '^\s*#' | grep -v '\$\$' | grep -v '\${' | head -5 || true)
      if [ -n "$UNQUOTED" ]; then
        echo -e "${YELLOW}⚠${NC}  Warning: Possibly unquoted variables in $file:"
        echo "$UNQUOTED" | sed 's/^/    /'
      fi
    fi
  done
fi

# Check for trailing whitespace
TRAILING_WS=$(git diff --cached --check 2>&1 | head -10 || true)
if [ -n "$TRAILING_WS" ]; then
  print_status 1 "Trailing whitespace detected"
  echo "$TRAILING_WS" | sed 's/^/  /'
else
  print_status 0 "No trailing whitespace"
fi

# Check 5: Verify test files have executable permissions
echo ""
echo "Checking test file permissions..."
STAGED_TEST_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep '^test/.*[^/]$' | grep -v -E '\.(sh|txt|json|js|log)$' | grep -v '^test/fixtures/' | grep -v '^test/mocks/' || true)

if [ -z "$STAGED_TEST_FILES" ]; then
  print_status 0 "No test files to check"
else
  EXEC_CHECK_FAILED=0
  for file in $STAGED_TEST_FILES; do
    if [ -f "$file" ] && [ ! -x "$file" ]; then
      print_status 1 "Test file not executable: $file"
      echo -e "${YELLOW}Run: chmod +x $file${NC}"
      EXEC_CHECK_FAILED=1
    fi
  done
  
  if [ $EXEC_CHECK_FAILED -eq 0 ]; then
    print_status 0 "All test files have correct permissions"
  else
    FAILED=1
  fi
fi

# Check 6: Ensure VERSIONED_FILES are in sync if any are changed
echo ""
echo "Checking version consistency..."
VERSIONED_FILES="nvm.sh install.sh README.md package.json"
VERSIONED_CHANGED=$(git diff --cached --name-only | grep -E '(nvm\.sh|install\.sh|README\.md|package\.json)' || true)

if [ -n "$VERSIONED_CHANGED" ]; then
  # Extract version from nvm.sh if it changed
  if echo "$VERSIONED_CHANGED" | grep -q "nvm.sh"; then
    echo "Version file changed - ensure versions are consistent across:"
    echo "$VERSIONED_FILES" | tr ' ' '\n' | sed 's/^/  - /'
  fi
fi

# Summary
echo ""
echo "================================"
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}All pre-commit checks passed!${NC}"
  exit 0
else
  echo -e "${RED}Some pre-commit checks failed!${NC}"
  echo ""
  echo "You can:"
  echo "  1. Fix the issues and try again"
  echo "  2. Run 'make lint' to check all files"
  echo "  3. Skip this check with 'git commit --no-verify' (not recommended)"
  exit 1
fi
