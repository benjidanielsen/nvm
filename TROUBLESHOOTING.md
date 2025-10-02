# Development Troubleshooting Guide

This guide covers common issues encountered during nvm development and testing, along with their solutions.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Test Failures](#test-failures)
- [Shell-Specific Issues](#shell-specific-issues)
- [Build and Lint Issues](#build-and-lint-issues)
- [Environment Issues](#environment-issues)
- [CI/CD Issues](#cicd-issues)

---

## Installation Issues

### npm install fails

**Problem:** `npm install` command fails with various errors.

**Solutions:**

1. **Clear npm cache:**
   ```bash
   npm cache clean --force
   rm -rf node_modules
   npm install
   ```

2. **Check Node.js version:**
   ```bash
   node --version  # Should be reasonably recent
   npm --version
   ```

3. **Permission issues (don't use sudo with npm):**
   ```bash
   # Fix npm permissions
   mkdir -p ~/.npm-global
   npm config set prefix '~/.npm-global'
   export PATH=~/.npm-global/bin:$PATH
   ```

### Shells not installed

**Problem:** Tests fail because required shells (bash, zsh, dash) are not installed.

**Solution:**

Run the installation helper:
```bash
./install-test-shells.sh
```

Or install manually based on your OS (see [DEVELOPMENT.md](./DEVELOPMENT.md)).

---

## Test Failures

### "urchin: command not found"

**Problem:** The urchin test framework is not found.

**Solution:**

```bash
# Install dev dependencies
npm install

# Verify urchin is available
which urchin
# or
node_modules/.bin/urchin --version
```

### Tests fail with "permission denied"

**Problem:** Test files don't have execute permissions.

**Solution:**

```bash
# Fix permissions for all test files
find test -type f ! -name "*.sh" ! -name "*.txt" ! -name "*.json" \
  -path "test/fast/*" -exec chmod +x {} \;

# Or for specific file
chmod +x "test/fast/Unit tests/nvm_version"
```

### Tests fail with "nvm: command not found"

**Problem:** nvm.sh is not properly sourced in the test environment.

**Solution:**

Ensure the test file sources nvm correctly:
```bash
#!/bin/sh

# Correct way to source nvm.sh
\. ../../nvm.sh  # Use \. instead of source for POSIX compatibility

# Or with full path
\. "$(cd ../.. && pwd)/nvm.sh"
```

### Test cleanup issues - "versions" or "v*" directories remain

**Problem:** Test artifacts remain after test runs, causing subsequent tests to fail.

**Solution:**

```bash
# Clean test artifacts
make clean

# Or manually
rm -rf test/bak .urchin.log .urchin_stdout
rm -rf v* src alias versions current

# Nuclear option (careful!)
git clean -fdx
```

### "Resource temporarily unavailable" errors

**Problem:** Too many processes or files open during tests.

**Solution:**

```bash
# Check limits
ulimit -a

# Increase file descriptor limit temporarily
ulimit -n 4096

# Or add to ~/.bashrc or ~/.zshrc
echo "ulimit -n 4096" >> ~/.bashrc
```

---

## Shell-Specific Issues

### Tests pass in bash but fail in zsh

**Problem:** zsh has different default settings that can break tests.

**Solution:**

Tests should use `setopt local_options` to ensure POSIX compliance:

```bash
#!/bin/zsh

# At the top of the test
if type setopt >/dev/null 2>&1; then
  setopt local_options nonomatch markdirs
fi
```

### Tests fail in dash with "syntax error"

**Problem:** dash doesn't support bash-specific syntax.

**Common Issues:**
- `source` command (use `. ` instead)
- `==` in tests (use `=` instead)
- Arrays (use positional parameters instead)
- `local` keyword (declare and assign separately)

**Solution:**

```bash
# ❌ Bash-specific
source nvm.sh
[ "$var" == "value" ]
local VAR="value"

# ✅ POSIX-compliant
. nvm.sh
[ "$var" = "value" ]
local VAR
VAR="value"
```

### "ksh: not found" warnings

**Problem:** ksh is not installed (it's optional).

**Solution:**

ksh support is experimental. You can safely ignore these warnings:
```bash
# Tests will skip ksh automatically if not found
make test  # Will show warning but continue
```

To install ksh:
```bash
# Ubuntu/Debian
sudo apt-get install ksh

# macOS
brew install ksh
```

---

## Build and Lint Issues

### shellcheck reports many errors

**Problem:** shellcheck finds issues in shell scripts.

**Common Issues:**

1. **Unquoted variables:**
   ```bash
   # ❌ Wrong
   echo $VAR
   
   # ✅ Correct
   echo "$VAR"
   echo "${VAR}"
   ```

2. **SC2039 - POSIX compatibility:**
   ```bash
   # Some bash features need to be disabled for POSIX mode
   # shellcheck disable=SC2039
   local VAR="value"
   ```

3. **SC2086 - Word splitting:**
   ```bash
   # ❌ Wrong
   rm $FILES
   
   # ✅ Correct
   rm "$FILES"
   ```

**Solution:**

Run shellcheck with appropriate shell dialect:
```bash
shellcheck -s bash nvm.sh
shellcheck -s sh nvm.sh  # For POSIX compliance
```

### eclint reports formatting issues

**Problem:** Files don't match .editorconfig settings.

**Solution:**

```bash
# Check which files have issues
npm run eclint

# Common issues:
# - Trailing whitespace (remove it)
# - Wrong indentation (use 2 spaces)
# - Missing final newline (add it)
# - Wrong line endings (use LF, not CRLF)

# Fix trailing whitespace
sed -i 's/[[:space:]]*$//' filename.sh
```

---

## Environment Issues

### NVM_DIR is already set

**Problem:** Tests use existing NVM_DIR instead of test environment.

**Solution:**

```bash
# Unset NVM variables before testing
for v in $(set | awk -F'=' '$1 ~ "^NVM_" { print $1 }'); do 
  unset $v
done

# Or run tests in clean environment
make test  # Makefile handles this automatically
```

### PATH is polluted with multiple nvm paths

**Problem:** Multiple nvm paths in PATH cause conflicts.

**Solution:**

```bash
# Check PATH
echo $PATH | tr ':' '\n' | grep nvm

# Deactivate nvm
nvm deactivate

# Or unload completely
nvm unload

# Start fresh shell
exec $SHELL
```

### Tests interfere with system node

**Problem:** Tests modify system node installation.

**Solution:**

```bash
# Set NVM_DIR to test location
export NVM_DIR="$(pwd)/test_nvm_dir"
mkdir -p "$NVM_DIR"

# Or use isolated test environment
env -i TERM="$TERM" bash -c "source nvm.sh && nvm --version"
```

---

## CI/CD Issues

### GitHub Actions tests fail but pass locally

**Problem:** CI environment differs from local environment.

**Common Causes:**

1. **Missing shells:**
   - CI might not have all shells installed
   - Check workflow YAML for shell installation steps

2. **Environment variables:**
   - CI has different environment variables
   - Use `nvm debug` to compare environments

3. **Network issues:**
   - CI might have limited network access
   - Mock external dependencies in tests

**Solution:**

```bash
# Debug CI environment
nvm debug

# Run tests in CI-like environment
env -i TERM="$TERM" bash -lc "make test"

# Check GitHub Actions logs for specific errors
```

### Travis CI vs GitHub Actions differences

**Problem:** Tests pass in one CI but fail in another.

**Solution:**

Check for environment-specific variables:
```bash
# Travis CI
if [ -n "$TRAVIS_BUILD_DIR" ]; then
  # Travis-specific logic
fi

# GitHub Actions
if [ -n "$GITHUB_ACTIONS" ]; then
  # GitHub Actions-specific logic
fi
```

---

## Performance Issues

### Tests are very slow

**Problem:** Full test suite takes a long time to run.

**Solutions:**

1. **Run fast tests only:**
   ```bash
   make test-fast
   npm run test/fast
   ```

2. **Test in single shell:**
   ```bash
   make test-bash  # Only bash
   ```

3. **Test specific suite:**
   ```bash
   make TEST_SUITE=fast test-bash
   ```

4. **Parallel testing (experimental):**
   ```bash
   # Not officially supported, use with caution
   make test-bash & make test-zsh & wait
   ```

---

## Debugging Tips

### Enable verbose output

```bash
# Shell debugging
set -x        # Enable tracing
set -v        # Verbose mode
set +x        # Disable tracing

# Run command with tracing
bash -x nvm.sh
```

### Debug specific test

```bash
# Run single test with debug output
bash -x "test/fast/Unit tests/nvm_version"

# Or with urchin
node_modules/.bin/urchin -f 'test/fast/Unit tests/nvm_version'
```

### Check what nvm sees

```bash
# Source nvm and check
. nvm.sh
nvm debug          # Show environment info
nvm ls             # Show installed versions
nvm which node     # Show node path
type nvm           # Show nvm function definition
```

### Test in isolated environment

```bash
# Create isolated test
mkdir -p /tmp/nvm_test
cd /tmp/nvm_test
export NVM_DIR="$(pwd)/.nvm"

# Copy and source nvm
cp /path/to/nvm/nvm.sh .
. nvm.sh
```

---

## Getting Help

If you're still stuck after trying these solutions:

1. **Check existing issues:**
   - Search [GitHub Issues](https://github.com/nvm-sh/nvm/issues)
   - Look for similar problems and solutions

2. **Review documentation:**
   - [README.md](./README.md) - User documentation
   - [DEVELOPMENT.md](./DEVELOPMENT.md) - Development guide
   - [CONTRIBUTING.md](./CONTRIBUTING.md) - Contribution guidelines

3. **Ask for help:**
   - Open a new issue with:
     - Output of `nvm debug`
     - Steps to reproduce
     - Expected vs actual behavior
     - Your environment (OS, shell, versions)

4. **Run diagnostics:**
   ```bash
   # Gather diagnostic info
   echo "=== Environment ==="
   uname -a
   echo "=== Shells ==="
   bash --version
   zsh --version
   dash --version
   echo "=== Node/npm ==="
   node --version
   npm --version
   echo "=== NVM Debug ==="
   . nvm.sh && nvm debug
   ```

---

## Quick Fixes Checklist

When encountering issues, try these in order:

- [ ] Run `npm install` to ensure dependencies are up to date
- [ ] Run `make clean` to remove test artifacts
- [ ] Check that all required shells are installed (`./install-test-shells.sh`)
- [ ] Verify file permissions on test files
- [ ] Unset NVM environment variables
- [ ] Try in a fresh shell session (`exec $SHELL`)
- [ ] Check for conflicting nvm installations
- [ ] Review recent changes with `git diff`
- [ ] Run tests in isolation (`make test-fast`)
- [ ] Check GitHub Actions logs if CI is failing

---

## Additional Resources

- [Shellcheck Wiki](https://www.shellcheck.net/wiki/) - Common shell script issues
- [POSIX Shell Tutorial](https://www.grymoire.com/Unix/Sh.html) - Shell compatibility guide
- [nvm GitHub Issues](https://github.com/nvm-sh/nvm/issues) - Community support
