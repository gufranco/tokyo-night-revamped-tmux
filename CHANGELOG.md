# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions CI/CD workflows for automated testing
  - Multi-platform testing (Ubuntu, macOS)
  - Multi-version testing (Bash 4.4-5.2, tmux 3.0-3.4)
  - Shellcheck linting
  - Markdown linting
  - Automated releases
- `.editorconfig` for consistent code formatting across editors
- `.shellcheckrc` for shell script linting configuration
- GitHub issue templates for bug reports and feature requests
- Pull request template for consistent PR submissions
- `CONTRIBUTING.md` with comprehensive development guidelines
- `docs/ARCHITECTURE.md` documenting system architecture and design decisions
- `docs/DEBUGGING.md` with troubleshooting and debugging guides
- Retry logic with exponential backoff (`src/lib/utils/retry.sh`)
  - `retry_with_backoff()` - Retry with configurable backoff
  - `retry_command()` - Simple retry wrapper
  - `retry_with_timeout()` - Retry with timeout
- Circuit breaker pattern for external services
  - `circuit_breaker_check()` - Check if service is available
  - `circuit_breaker_record_failure()` - Record failures
  - `circuit_breaker_reset()` - Reset circuit breaker
- Comprehensive test suite for retry logic

### Changed
- Standardized all test descriptions to English
- Improved test setup with proper dependency loading
- Updated README to remove obsolete system widget features
- Enhanced error handling and logging throughout codebase

### Fixed
- Test setup issues in `color-scale.bats` (added missing dependencies)
- Inconsistent test descriptions (Portuguese/English mix)
- Inline test comments standardized to English

### Documentation
- Added architectural documentation
- Added debugging guide
- Added contribution guidelines
- Added code of conduct references
- Improved README clarity and accuracy

### Developer Experience
- Added comprehensive CI/CD pipeline
- Improved code quality with linting
- Standardized commit message format
- Added automated release workflow
- Enhanced debugging capabilities

---

## [Previous Releases]

For changes in previous releases, see the [GitHub Releases](https://github.com/gufranco/tokyo-night-revamped-tmux/releases) page.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

## Support

- 📝 [Report a Bug](https://github.com/gufranco/tokyo-night-revamped-tmux/issues/new?template=bug_report.yml)
- ✨ [Request a Feature](https://github.com/gufranco/tokyo-night-revamped-tmux/issues/new?template=feature_request.yml)
- 💬 [Ask a Question](https://github.com/gufranco/tokyo-night-revamped-tmux/discussions)

