# Contributing to OCS

Pull requests, issues, and discussions are welcome.

For open-ended questions, use [Discussions](https://github.com/optcmdspace/ocs-macos/discussions). For bugs and feature requests, use [Issues](https://github.com/optcmdspace/ocs-macos/issues/new/choose).

## Before you open a PR

For anything beyond a typo or a one-line fix, open an issue or a discussion first. It's faster than rewriting a PR that's gone in the wrong direction. Bug fixes with a clear repro can skip this.

If a task seems to require breaking one of the rules below, surface the conflict instead of working around it. The maintainer decides whether to amend the rule or restructure the task.

## Build

```
xcodebuild -scheme OCS -configuration Debug build
```

Or open `OCS.xcodeproj` in Xcode and press ⌘R.

Requires macOS 14 (Sonoma) and Xcode 26.4 or later. SwiftLint is required for the build phase that enforces the architecture rules:

```
brew install swiftlint
```

## The map

```
OCS/
├── App/                 entry point, dependency wiring, system collaborators
├── UI/                  AppKit on the capture hot path, SwiftUI elsewhere
├── Domains/             one folder per aggregate (Entries, Tags, Devices, Sync)
│   └── <Aggregate>/
│       ├── Model/       value objects and invariants
│       ├── Events/      past-tense events emitted by the write side
│       ├── Write/       Commands and their Handlers
│       └── Read/        Queries, Handlers, ReadModels, per-Query store protocols
├── Shared/              shared kernel: types every aggregate may reference
├── Collaborators/       system-level protocols (closed set: EventStore, Clock, IDs)
├── Persistence/         GRDB lives here and only here
└── Observability/       leaf signposters and log handles
```

The codebase is laid out package-by-aggregate. Everything that touches one aggregate's state lives in one folder.

## Architecture

OCS is local-first. The data model is two append-only event logs (`entry_events`, `tag_events`) as the source of truth. Every other table is a projection that can be dropped and rebuilt by replaying events.

The application code follows CQRS over that event store:

- **Commands** are imperative intents (`CaptureEntryCommand`). Their **Handlers** validate, decide which events to emit, and ask the EventStore to append them atomically. Commands return acknowledgement, never data.
- **Events** are statements of fact (`EntryCaptured`). Past tense, immutable, never modified once emitted.
- **Queries** are imperative read requests (`ListEntriesByBinQuery`). Their **Handlers** read projection tables and return ReadModels. Pure, no side effects.
- **ReadModels** are DTOs shaped for one view need. Decoupled from write-side types, disposable.
- **Projector** folds events into projection tables atomically, inside the same transaction as the event append.

The capture hot path is AppKit-only. SwiftUI is permitted elsewhere when it makes the code clearer.

The architecture follows SOLID strictly. The handful of approved exceptions are documented and require explicit approval to extend.

## Hard rules

These will fail code review or the architecture lint. They exist for reasons; the patterns repeat once you've read them.

- **One Command, one Handler, one file.** Same for Queries. The folder is the index; the file is the unit.
- **Handlers have a single entry point.** No second public method, no overloads, no exposed helpers. Helpers are private functions or extracted collaborators.
- **Handlers never call other handlers.** Reuse goes through pure functions or typed collaborators. Handler-to-handler calls re-enable god-class drift.
- **Time and id generation are injected, never read from process globals.** Reading the wall clock or minting an id directly from a handler breaks deterministic replay across devices and tests. Take a `Clock` or `IDs` collaborator.
- **The database driver is scoped to the persistence layer.** Domains, Shared, Collaborators, and UI never import it. Read Handlers depend on a per-Query store protocol; its implementation lives in `Persistence/` and never leaks out.
- **Commands, Queries, Events, ReadModels are immutable value types.** `struct` with `let` properties only. No `var`, no closures or callbacks as properties.
- **Events are append-only.** Never edit, delete, or rewrite an existing event. Backward compatibility is forever. Add a new event kind; deprecate the old one for new emissions but fold both the same way.
- **One writer per table family.** Event-log inserts happen only in the EventStore implementation. Projection-table inserts happen only in the Projector. No other file writes into either set.
- **UI deals in Commands and Queries, not Events.** Events are an internal write-side concept and the UI never imports them.
- **One protocol per file, one method per protocol** in Collaborators and per-Query stores. The consumer that needs only one method should not see the other nine.
- **Sync goes through the dispatcher.** Inbound peer events arrive as a Command; outbound sync is a Query against the event log. The sync engine never writes the event log or reads projections directly.

## Naming

| Type      | Pattern                          | Examples                              |
| --------- | -------------------------------- | ------------------------------------- |
| Command   | imperative + `Command` suffix    | `CaptureEntryCommand`                 |
| Event     | past-tense, no suffix            | `EntryCaptured`, `TagRenamed`         |
| Query     | imperative + `Query` suffix      | `ListEntriesByBinQuery`               |
| ReadModel | descriptive noun, no suffix      | `EntryListItem`, `TagSuggestion`      |
| Handler   | type name + `Handler`            | `CaptureEntryHandler`                 |

Properties and locals use camelCase with single-cap initialisms: `deviceId`, `entryId`, not `deviceID`. Types use PascalCase; established initialisms inside type names stay all-caps: `UUID`, `IDs`, `URL`.

## SQL

No inline SQL in Swift. SQL lives in `OCS/Database/queries/<name>.sql` and is loaded via the `Queries` namespace. Filename convention:

- Event-log inserts: `insert_<entry|tag>_event_<kind>.sql`
- Projection writes: `project_<aggregate>_<kind>.sql`
- Read-side queries: `select_<aggregate>_<purpose>.sql`

snake_case filename, camelCase symbol in `Queries.swift`.

## Style

SwiftLint runs with only the project's architectural rules enabled, not default style rules. Match the surrounding code for everything else. Value types (`struct`) by default; `class` is reserved for Handlers, Stores, Projectors, and UI controllers. Async/await over completion handlers. All Commands, Queries, Events, ReadModels, value objects, collaborators, handlers, stores, and projectors are `Sendable`.

## Comments

Default: none. Treat comments as tech debt.

Add one only when the WHY is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug. One line.

Don't write Xcode-style file headers, lines that restate WHAT the code does, references to the current task or PR, or multi-paragraph docstrings. When in doubt, delete.

## Lint

After any change under `OCS/Domains/`, `OCS/Shared/`, `OCS/Collaborators/`, or `OCS/Persistence/`:

```
bash scripts/check-cqrs.sh
```

It must exit zero. The script verifies the rules expressible as path-and-grep: Command/Handler pairing, event-table write isolation, GRDB import boundaries, the no-`Date()`-in-handlers rule, and so on.

## Tests

There are no tests yet. The design is moving fast enough that tests would lock in choices that haven't settled. If a fix is non-obvious, a small repro in the PR description is enough.

## The capture hot path

The path from hotkey press to event committed is budgeted at **p99 < 50 ms** on commodity Apple Silicon. That budget is the contract: regressions beyond it are bugs, not optimisations to defer.

`os_signpost` regions are required at panel show, text field active, command dispatch, handler enter and exit, and store append enter and exit. Signposts are for measurement, not just tracing.

Saves are local SQLite and sub-millisecond. There is no spinner on save. If a write ever blocks, queue and dismiss optimistically. The user should never see latency on the hot path.

## UX principles

These bind product decisions, not just code:

- **The hotkey is the entire surface.** No dock icon, no menu bar item, no preferences window.
- **One field, no modes.** Resist tag pickers, bin dropdowns, date pickers. Each one is a mode. Inline parsing keeps the surface flat.
- **No confirmations, ever.** Replace every "are you sure?" with "did it, here's undo."
- **No nags, no streaks, no badges.** Extrinsic gamification corrodes trust. Glance numbers are fine; targets, goals, and shame counters are not.
- **Trust the inbox.** Saves are silent and instant. No spinner, no toast that demands acknowledgement.
- **Aging is visual, never a counter.** Dim color over time, not a guilt number.

If a feature request grows the surface, it's likely declined. Surface a discussion before doing the work.

## Schema evolution

Schema changes are additive. Adding behaviour is:

1. A new event kind in `Domains/<Aggregate>/Events/` (or `Shared/Events/` for the rare cross-aggregate event).
2. Adding the kind to the `CHECK` constraint on `entry_events.kind` or `tag_events.kind` via a migration.
3. A new fold rule in `Projector.swift`.
4. A migration in `Persistence/migrations/` if a projection column is needed.

Old events are never rewritten, deleted, or upgraded in place. If a field's meaning changes, add a new event kind; deprecate the old one for new emissions but fold both the same way.

## Pull requests

- One concern per PR.
- Run the lint and the build before opening.
- For UI changes, exercise the path manually. The hotkey flow can't be automated precisely; if you can't test it, say so in the PR.
- Conventional-commit subjects: `feat(panel): ...`, `fix(db): ...`. Keep under ~70 chars.

## Dependencies

Don't add a Swift Package without opening an issue first. List the candidates and the tradeoffs. Implementations under ~50 lines that rarely change (small parsers, UUIDv7 generators, etc.) stay in-tree.

## Reporting bugs and security issues

For security vulnerabilities, see [SECURITY.md](SECURITY.md). For everything else, open an issue.

## License of contributions

By submitting a contribution, you agree it is licensed under the MIT License (see [LICENSE](LICENSE)).

## Code of conduct

Participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).
