# Development Guide

This guide will help you get started with developing and testing nvm.

## Quick Start

### Prerequisites

nvm is a POSIX-compliant shell script project that works across multiple shells. You'll need:

- A Unix-like environment (Linux, macOS, or WSL2 on Windows)
- Git
- Node.js and npm (for dev dependencies)
- Multiple shells for testing: bash, sh/dash, zsh (optional: ksh)

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/nvm-sh/nvm.git
   cd nvm
   ```

2. **Install development dependencies**
   ```bash
   npm install
   ```
   
   This installs testing and linting tools:
   - `urchin` - Test framework for shell scripts
   - `semver` - Semantic version parser
   - `replace` - String replacement utility
   - `eclint` - EditorConfig linter
   - `doctoc` - Markdown TOC generator
   - `shellcheck` - Shell script linter (install separately)

3. **Install required shells (if not already present)**
   
   **Ubuntu/Debian:**
   ```bash
   sudo apt-get update
   sudo apt-get install bash zsh dash
   ```
   
   **macOS:**
   ```bash
   # bash and zsh come pre-installed
   brew install dash
   ```

### Development Workflow

#### Running Tests

```bash
# Run all tests in all shells
make test

# Run tests in a specific shell
make test-bash
make test-zsh
make test-dash
make test-sh

# Run fast tests only (quick feedback loop)
make test-fast
npm run test/fast

# Run specific test suites
npm run test/slow
npm run test/install_script
npm run test/sourcing
```

#### Linting and Code Quality

```bash
# Run all linters
make lint

# Run shellcheck on main scripts
shellcheck -s bash nvm.sh
shellcheck -s bash install.sh
shellcheck -s bash nvm-exec

# Run editorconfig linter
npm run eclint

# Check Dockerfile
npm run dockerfile_lint
```

#### Cleaning Up

```bash
# Remove test artifacts and caches
make clean

# Manual cleanup
rm -rf test/bak .urchin.log .urchin_stdout
rm -rf v* src alias versions
```

## Project Structure

```
nvm/
├── nvm.sh              # Main nvm script (core functionality)
├── install.sh          # Installation script
├── nvm-exec            # Execution wrapper for running commands
├── bash_completion     # Bash completion support
├── Makefile            # Build and test automation
├── package.json        # Dev dependencies and npm scripts
├── test/               # Test suites
│   ├── fast/           # Quick unit tests
│   ├── slow/           # Integration tests
│   ├── sourcing/       # Shell sourcing tests
│   ├── install_script/ # Installation tests
│   ├── installation_node/  # Node installation tests
│   ├── installation_iojs/  # io.js installation tests
│   └── common.sh       # Shared test utilities
└── docs/               # Documentation
```

## Testing Guidelines

### Writing Tests

- Tests are shell scripts in the `test/` directory
- Use the urchin test framework
- Tests must work across all supported shells
- Name test files descriptively (they become test names)
- Include cleanup functions

**Example test structure:**
```bash
#!/bin/sh

\. ../../nvm.sh

die() { echo "$@"; exit 1; }

cleanup() {
  # Clean up test artifacts
}

# Test logic here
[ "$expected" = "$actual" ] || die "expected $expected, got $actual"

cleanup
```

### Test Requirements

- Include tests for any new functionality
- Ensure tests pass in bash, sh/dash, zsh
- Tests should be idempotent and clean up after themselves
- Mock external dependencies when possible

## Code Style

### Shell Script Guidelines

- Use 2-space indentation
- Follow POSIX compliance for portability
- Prefix internal functions with `nvm_`
- Use `nvm_echo` instead of `echo` for output
- Use `nvm_err` for error messages
- Quote all variables: `"${VAR}"` not `$VAR`
- Avoid bash-specific features in core functionality

### Commit Messages

Follow Conventional Commits format:

```
<type>(<optional-scope>): <short imperative summary>

WHY: <1-2 lines explaining reasoning/impact>
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`

**Example:**
```
fix(install): handle spaces in installation path

WHY: Users with spaces in their home directory path were unable
to install nvm due to unquoted variable expansion.
```

## Common Development Tasks

### Adding a New Command

1. Add the command implementation in `nvm.sh`
2. Add command to the help text in `nvm()` function
3. Add tests in appropriate test suite
4. Update bash completion in `bash_completion`
5. Update README.md documentation

### Debugging

1. **Enable verbose mode:**
   ```bash
   set -x
   source nvm.sh
   # your commands
   set +x
   ```

2. **Use nvm debug command:**
   ```bash
   nvm debug
   ```

3. **Check for shell-specific issues:**
   ```bash
   bash -c "source nvm.sh && nvm --version"
   zsh -c "source nvm.sh && nvm --version"
   ```

## Release Process

Releases are managed by maintainers. To prepare for a release:

1. Ensure all tests pass in all shells
2. Update version in `VERSIONED_FILES` (handled by Makefile)
3. Create release notes
4. Tag release (maintainers only)

```bash
make TAG=<version> release
```

## Getting Help

- Check [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines
- Review [README.md](./README.md) for user documentation
- Look at existing tests for examples
- Open an issue for questions or clarifications

## Useful Makefile Targets

| Target | Description |
|--------|-------------|
| `make test` | Run all test suites in all shells |
| `make test-bash` | Run tests in bash only |
| `make test-fast` | Quick test run (fast suite in bash) |
| `make lint` | Run all linters (shellcheck + eclint) |
| `make clean` | Remove test artifacts and caches |
| `make list` | List all available Makefile targets |

## Additional Resources

- [Shellcheck Wiki](https://www.shellcheck.net/wiki/) - Shell script best practices
- [POSIX Shell Spec](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [Urchin Test Framework](https://github.com/tlevine/urchin)
- [EditorConfig](https://editorconfig.org/) - Code style configuration
