# Contributing to yoru

First off, thank you for considering contributing! 🎉

This document provides guidelines for contributing to this project. Following these guidelines helps maintain code quality and makes the review process smoother.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

---

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## Getting Started

### Prerequisites

- **tmux** 3.0 or higher
- **Bash** 4.2 or higher
- **Git** for version control
- **bats-core** for running tests
- **ShellCheck** for linting (recommended)

### Quick Start

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/yoru.git
   cd yoru
   ```
3. Install dependencies:
   ```bash
   make install-deps
   ```
4. Run tests:
   ```bash
   make test
   ```

---

## Development Setup

### Installing Development Tools

```bash
# macOS
brew install bats-core shellcheck

# Ubuntu/Debian
sudo apt-get install bats shellcheck

# Fedora/RHEL
sudo yum install bats shellcheck
```

### Editor Configuration

The project includes an `.editorconfig` file. Install the EditorConfig plugin for your editor:

- **VSCode**: [EditorConfig for VS Code](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig)
- **Vim**: [editorconfig-vim](https://github.com/editorconfig/editorconfig-vim)
- **Sublime**: [EditorConfig](https://packagecontrol.io/packages/EditorConfig)

---

## Project Structure

```
yoru/
├── src/
│   ├── lib/              # Core library functions
│   │   ├── cpu/          # CPU-related functions
│   │   ├── gpu/          # GPU-related functions
│   │   ├── ram/          # Memory-related functions
│   │   ├── disk/         # Disk-related functions
│   │   ├── network/      # Network-related functions
│   │   ├── git/          # Git integration
│   │   ├── tmux/         # Tmux configuration
│   │   ├── ui/           # UI components and colors
│   │   ├── utils/        # Utility functions
│   │   └── widget/       # Widget framework
│   └── *-widget.sh       # Widget implementations
├── test/
│   ├── lib/              # Unit tests for libraries
│   ├── widgets/          # Integration tests for widgets
│   └── helpers.bash      # Test helpers and mocks
├── docs/                 # Additional documentation
└── tokyo-night.tmux      # Main entry point
```

For more details, see [ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Coding Standards

### Bash Style Guide

#### General Rules

1. **Use bash strict mode** (where appropriate):
   ```bash
   set -euo pipefail
   ```

2. **Use meaningful variable names**:
   ```bash
   # Good
   local cpu_usage
   cpu_usage=$(get_cpu_usage_percentage)

   # Bad
   local x
   x=$(get_cpu_usage_percentage)
   ```

3. **Quote variables**:
   ```bash
   # Good
   echo "${variable}"

   # Bad
   echo $variable
   ```

4. **Use `[[ ]]` for conditionals** (not `[ ]`):
   ```bash
   # Good
   if [[ "$value" -gt 0 ]]; then

   # Bad
   if [ "$value" -gt 0 ]; then
   ```

#### Function Guidelines

1. **Use descriptive function names** (verb + noun):
   ```bash
   get_cpu_usage()
   validate_percentage()
   format_output()
   ```

2. **Document complex functions**:
   ```bash
   get_cpu_usage_percentage() {
     # Calculates CPU usage as a percentage
     # Returns: Integer 0-100
     # Platform: macOS, Linux
     local os
     os="$(get_os)"
     # ...
   }
   ```

3. **Validate inputs**:
   ```bash
   validate_percentage() {
     local value="${1:-0}"
     
     if ! [[ "$value" =~ ^[0-9]+$ ]]; then
       echo "0"
       return
     fi
     
     clamp_value "$value" 0 100
   }
   ```

4. **Export functions** when needed by other scripts:
   ```bash
   export -f get_cpu_usage_percentage
   ```

#### Code Organization

1. **No comments in code** - Code should be self-documenting
2. **Follow SOLID principles** - Single Responsibility
3. **Follow DRY principles** - Don't Repeat Yourself
4. **Use consistent indentation** - 2 spaces (see `.editorconfig`)
5. **Maximum line length** - 120 characters
6. **No trailing whitespace**
7. **End files with newline**

---

## Testing Guidelines

### Writing Tests

Tests are written in [bats-core](https://github.com/bats-core/bats-core).

#### Test Structure

```bash
#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/system.sh"
}

teardown() {
  cleanup_test_environment
}

@test "system.sh - safe_divide returns correct value" {
  result=$(safe_divide "10" "2")
  [[ "$result" == "5" ]]
}

@test "system.sh - safe_divide returns default when denominator is zero" {
  result=$(safe_divide "10" "0" "999")
  [[ "$result" == "999" ]]
}
```

#### Test Guidelines

1. **Test descriptions** - Use clear, descriptive names
2. **One assertion per test** - Keep tests focused
3. **Use mocks** - Isolate external dependencies
4. **Test edge cases** - Empty strings, zero values, negative numbers
5. **Test platform-specific code** - Use `MOCK_UNAME_S` for OS detection

### Running Tests

```bash
# Run all tests
make test

# Run specific test suite
make test-lib
make test-widgets

# Run individual test file
bats test/lib/system.bats

# Run with verbose output
make test-verbose
```

---

## Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no functional changes)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Test changes
- `chore`: Build process or auxiliary tool changes

### Examples

```bash
# Good commits
feat(system): add memory pressure monitoring for macOS
fix(git): correctly parse branch names with slashes
docs(readme): update installation instructions
perf(cache): optimize widget caching strategy

# Bad commits
update stuff
fixed bug
WIP
```

### Scope Guidelines

Use these scopes:
- `system`, `git`, `network`, `context` - Widget names
- `cache`, `color`, `format`, `ui` - Component names
- `test`, `docs`, `ci` - Infrastructure

---

## Pull Request Process

### Before Submitting

1. **Update your branch**:
   ```bash
   git fetch upstream
   git rebase upstream/master
   ```

2. **Run tests**:
   ```bash
   make test
   ```

3. **Run linter**:
   ```bash
   shellcheck src/**/*.sh
   ```

4. **Update documentation** if needed

### PR Checklist

- [ ] Tests pass locally
- [ ] Code follows style guidelines
- [ ] No shellcheck warnings
- [ ] Documentation updated
- [ ] CHANGELOG entry added (if applicable)
- [ ] Commit messages follow conventions

### Review Process

1. At least one maintainer must approve
2. All CI checks must pass
3. No unresolved conversations
4. Branch is up-to-date with master

---

## Reporting Bugs

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.yml) and include:

- **Description**: Clear description of the bug
- **Steps to reproduce**: Detailed steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: OS, tmux version, bash version
- **Configuration**: Relevant `.tmux.conf` settings
- **Logs**: Error messages or output

---

## Suggesting Features

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.yml) and include:

- **Problem statement**: What problem does this solve?
- **Proposed solution**: How should it work?
- **Alternatives**: Other solutions considered
- **Priority**: How important is this?

---

## Development Workflow

### Typical Workflow

```bash
# 1. Create feature branch
git checkout -b feat/my-feature

# 2. Make changes
vim src/lib/cpu/cpu.sh

# 3. Add tests
vim test/lib/cpu.bats

# 4. Run tests
make test

# 5. Commit changes
git add .
git commit -m "feat(cpu): add new CPU metric"

# 6. Push to your fork
git push origin feat/my-feature

# 7. Create Pull Request on GitHub
```

### Debugging

See [DEBUGGING.md](docs/DEBUGGING.md) for debugging tips.

---

## Questions?

- Open a [Discussion](https://github.com/gufranco/yoru-revamped-tmux-revamped-tmux/discussions)
- Join our community (if applicable)
- Check existing [Issues](https://github.com/gufranco/yoru-revamped-tmux-revamped-tmux/issues)

---

## License

By contributing, you agree that your contributions will be licensed under the same [MIT License](LICENSE.md) as the project.

---

Thank you for contributing! 🙏

