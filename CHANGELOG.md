# Changelog

All notable changes to OCS are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Add entries under [Unreleased] in these groups, in this order:
Added, Changed, Deprecated, Removed, Fixed, Security.
On release, rename [Unreleased] to [x.y.z] - YYYY-MM-DD and start a new [Unreleased].
-->

## [Unreleased]

## [0.1.0] - 2026-05-09

### Added

- Global hotkey (⌥⌘Space) opens a Spotlight-style capture panel from any app. Type and hit Enter to save.
- Local SQLite storage at `~/Library/Application Support/OCS/` with an append-only event log.
- List view of past captures with arrow-key navigation, inline edit, and delete.
- History recall and session stack to step through and restore prior text.
- Draft restore: unsubmitted text comes back the next time the panel opens.
- Done entries dim over time.
- Runs as an accessory app: no Dock icon, no menu bar item.
- Signed and notarized DMG distribution.

[Unreleased]: https://github.com/optcmdspace/ocs-macos/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/optcmdspace/ocs-macos/releases/tag/v0.1.0
