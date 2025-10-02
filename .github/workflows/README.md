# GitHub Actions Workflows

This directory contains GitHub Actions workflows for continuous integration and automation in the nvm project.

## Overview

nvm uses GitHub Actions for automated testing, linting, and release management. The workflows ensure code quality, compatibility across shells and platforms, and streamline the release process.

## Workflows

### Core Testing Workflows

#### `tests.yml` - Main Test Suite
**Purpose:** Run comprehensive test suite across multiple shells and platforms.

**Triggers:**
- Pull requests
- Push to main branch
- Manual workflow dispatch

**What it does:**
- Tests nvm in bash, dash, zsh, sh
- Runs multiple test suites: fast, slow, sourcing, installation_node, installation_iojs
- Tests on Ubuntu (multiple versions)
- Matrix testing for thorough coverage

**Key features:**
- Uses `script` command for proper TTY simulation
- Tests install scripts separately
- Excludes install_script tests from non-bash shells
- Reports test failures with detailed logs

**When to check:** Failed tests here indicate core functionality issues.

---

#### `nvm-install-test.yml` - Installation Testing
**Purpose:** Verify the nvm installation process works correctly.

**Triggers:**
- Pull requests
- Push to main branch

**What it does:**
- Tests the installation script (`install.sh`)
- Verifies installation via different methods (curl, wget, git)
- Tests installation in various environments

**When to check:** Failed tests indicate issues with the installation process.

---

### Code Quality Workflows

#### `shellcheck.yml` - Shell Script Linting
**Purpose:** Lint shell scripts for common issues and POSIX compliance.

**Triggers:**
- Pull requests
- Push to main branch

**What it does:**
- Runs shellcheck on all shell scripts
- Tests against multiple shell targets (bash, sh, dash, ksh)
- Uses latest shellcheck version from Homebrew
- Fails on any shellcheck warnings or errors

**Common issues found:**
- Unquoted variables
- Non-POSIX syntax
- Potential security issues
- Logic errors

**Note:** zsh is not tested due to [shellcheck limitations](https://github.com/koalaman/shellcheck/issues/809).

**When to check:** Failed checks indicate code quality issues that should be fixed.

---

#### `lint.yml` - General Linting
**Purpose:** Run additional linting and formatting checks.

**Triggers:**
- Pull requests
- Push to main branch

**What it does:**
- Runs eclint for EditorConfig compliance
- Checks code formatting
- Validates file consistency

**When to check:** Failed checks indicate formatting or style issues.

---

#### `toc.yml` - Table of Contents
**Purpose:** Ensure README table of contents is up to date.

**Triggers:**
- Pull requests
- Push to main branch

**What it does:**
- Runs doctoc to check if README TOC is current
- Fails if TOC needs updating

**Fix:**
```bash
npm run doctoc
git add README.md
git commit -m "docs: update table of contents"
```

---

### Platform-Specific Workflows

#### `windows-npm.yml` - Windows Testing
**Purpose:** Test nvm compatibility on Windows via WSL2 and Cygwin.

**Triggers:**
- Scheduled (regular intervals)
- Manual workflow dispatch

**What it does:**
- Tests nvm on Windows environments
- Validates WSL2 compatibility
- Tests Cygwin compatibility

**When to check:** Failed tests indicate Windows-specific issues.

---

#### `latest-npm.yml` - Latest npm Testing
**Purpose:** Test with the latest npm versions.

**Triggers:**
- Scheduled (regular intervals)
- Manual workflow dispatch

**What it does:**
- Tests nvm with newest npm releases
- Validates forward compatibility
- Catches breaking changes early

**When to check:** Failed tests may indicate incompatibility with new npm versions.

---

### Automation Workflows

#### `release.yml` - Release Automation
**Purpose:** Automate the release process.

**Triggers:**
- Manual workflow dispatch (maintainers only)

**What it does:**
- Creates GitHub releases
- Generates release notes
- Tags versions
- Updates documentation

**Access:** Maintainers only.

---

#### `rebase.yml` - Automatic Rebase
**Purpose:** Help keep pull requests up to date.

**Triggers:**
- Comment on PR with `/rebase`

**What it does:**
- Automatically rebases PR on target branch
- Resolves simple conflicts

**Usage:** Comment `/rebase` on a PR to trigger.

---

#### `require-allow-edits.yml` - PR Configuration Check
**Purpose:** Ensure PRs allow maintainer edits.

**Triggers:**
- Pull request opened or updated

**What it does:**
- Checks if "Allow edits from maintainers" is enabled
- Posts a comment if not enabled
- Helps maintainers push fixes directly to PRs

**Fix:** Enable "Allow edits from maintainers" when creating PR.

---

## Workflow Best Practices

### For Contributors

1. **Before pushing:**
   ```bash
   # Run checks locally
   make lint
   make test-fast
   ./pre-commit-check.sh
   ```

2. **If CI fails:**
   - Check the specific workflow that failed
   - Read the error logs carefully
   - Refer to [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md)
   - Fix locally and push again

3. **Common fixes:**
   ```bash
   # Shellcheck failures
   shellcheck -s bash nvm.sh
   
   # Lint failures
   npm run eclint
   
   # TOC outdated
   npm run doctoc
   
   # Test failures
   make test-bash
   ```

### For Maintainers

1. **Monitoring workflows:**
   - Check GitHub Actions tab regularly
   - Review failed workflow runs
   - Update workflows as needed for new dependencies

2. **Adding new workflows:**
   - Use existing workflows as templates
   - Test workflows in a fork first
   - Document the workflow in this README
   - Add appropriate triggers

3. **Updating workflows:**
   - Keep action versions up to date
   - Test changes thoroughly
   - Document breaking changes

## Workflow Configuration

### Matrix Strategy

Many workflows use matrix testing to test multiple configurations:

```yaml
strategy:
  matrix:
    shell: [bash, dash, zsh, sh]
    test-suite: [fast, slow, sourcing]
```

This creates a job for each combination, ensuring thorough coverage.

### Caching

Workflows use caching to speed up runs:
- npm dependencies
- Shell installations
- Test artifacts

### Secrets and Variables

Some workflows require secrets (maintainers only):
- `GITHUB_TOKEN` - Automatically provided
- Release signing keys (for releases)

## Debugging Failed Workflows

### 1. Read the logs

Click on the failed workflow run and read the complete logs.

### 2. Reproduce locally

Most CI failures can be reproduced locally:

```bash
# Set up similar environment
env -i TERM="$TERM" bash -lc "make test"

# Run specific test suite
make TEST_SUITE=fast test-bash

# Check shellcheck
shellcheck -s bash nvm.sh
```

### 3. Check recent changes

```bash
# See what changed
git log --oneline -10
git show HEAD
```

### 4. Common issues

| Error | Cause | Fix |
|-------|-------|-----|
| shellcheck failures | Code quality issues | Fix code to pass shellcheck |
| Test failures | Breaking changes | Fix code or update tests |
| TOC out of date | README changes | Run `npm run doctoc` |
| Permission denied | Missing execute bit | `chmod +x test/path/to/file` |
| Module not found | Missing dependencies | `npm install` |

## Adding New Tests

When adding new test files:

1. **Make executable:**
   ```bash
   chmod +x test/fast/your_new_test
   ```

2. **Test locally first:**
   ```bash
   make test-fast
   ```

3. **Ensure compatibility:**
   - Test in bash, dash, zsh
   - Use POSIX-compliant syntax
   - Source nvm correctly

4. **Check CI passes:**
   - Push changes
   - Monitor GitHub Actions
   - Fix any failures

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [nvm DEVELOPMENT.md](../../DEVELOPMENT.md)
- [nvm TROUBLESHOOTING.md](../../TROUBLESHOOTING.md)

## Maintenance Notes

### Updating Action Versions

Periodically update GitHub Actions to latest versions:

```yaml
# Old
- uses: actions/checkout@v2

# New
- uses: actions/checkout@v4
```

### Deprecation Warnings

Monitor for deprecation warnings in workflow runs and address them promptly.

### Performance Optimization

If workflows become slow:
- Review caching strategies
- Optimize test execution
- Consider parallel jobs
- Remove redundant steps

---

*Last updated: 2025-10-02*
