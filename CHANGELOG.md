# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of compiler-diagnostic project
- Parser diagnostic module with 5 error codes (E0001-E0005)
- Sema diagnostic module with 4 error codes (E1001-E1004)
- JSON diagnostic output (LSP compatible)
- Text diagnostic output
- Performance benchmark framework (stub)
- 27 test files (UT: 6, HLT: 11, LLT: 10)

### Changed
- Core data structures merged into Diagnostics.cj to avoid circular dependencies

### Fixed
- JSON output array bounds bug (C001)

## [0.1.0] - 2026-09-01

### Added
- Initial project structure
- Error code definitions
- Diagnostic builder pattern
- Output formatters (JSON, Text)
- Basic test suite

[Unreleased]: https://github.com/example/compiler-diagnostic/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/example/compiler-diagnostic/releases/tag/v0.1.0
