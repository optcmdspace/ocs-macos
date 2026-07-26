# Changelog

All notable changes to OCS are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Add entries under [Unreleased] in these groups, in this order:
Added, Changed, Deprecated, Removed, Fixed, Security.
On release, rename [Unreleased] to [x.y.z] - YYYY-MM-DD and start a new [Unreleased].
-->

## [Unreleased]

## [0.3.0] - 2026-07-26

### Added

- Due dates. Type a date while capturing (`tomorrow`, `next friday`, `jul 12`, `in 3 days`) and it is set on the entry and highlighted as you type.
- `d` on a selected list entry to set, change, or clear its due date.
- `/due` shows an agenda of dated entries grouped by overdue, today, this week, and later.

### Changed

- The list is ordered by due date: overdue and today first, then upcoming, then undated by recency, with done last.
- Past-due entries collapse into a single `N earlier` row; the right arrow expands it.
- Long entries wrap to multiple lines in the list instead of being truncated.

## [0.2.0] - 2026-05-09

### Added

- Hashtags in capture: `#tag` is parsed into a separate tag set on save and rendered as colored chips in the list.
- Inline tag suggestions as you type `#`.
- `t` on a selected list entry opens a tag picker.
- `/find <text> #tags` slash command, with results streaming as you type and the matching substring chipped on each row.
- `/set` namespace for settings. `/sound on|off` moved under `/set sound on|off`.
- Slash autocomplete descends a tree (`/`, `/set`, `/set sound`) and tints the input cursor amber when the leading token matches a known command.
- App adds itself to Login Items on first launch.
- Homebrew install via `brew install --cask ocs` using tap.

### Changed

- `/list` is gone, replaced by `/find`.
- UUIDv7 emission is monotonic, so fold order matches emission order across peers.

### Fixed

- Tag name collisions in the projector resolve to the lower id; the loser is demoted and its `entry_tags` migrate to the winner.

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

[Unreleased]: https://github.com/optcmdspace/ocs-macos/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/optcmdspace/ocs-macos/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/optcmdspace/ocs-macos/releases/tag/v0.1.0
