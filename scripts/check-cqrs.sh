#!/usr/bin/env bash
# CQRS guardrail check. See CQRS.md for the full rules; this script enforces
# the subset expressible as path + grep. It is intended to run locally
# (e.g. as a pre-commit hook) and in CI. Exits 0 on clean, non-zero on any
# violation. Output names the offending file and rule.
#
# OCS uses a package-by-aggregate layout: every aggregate lives at
# OCS/Domains/<Aggregate>/ with Model | Events | Write | Read subfolders.
# Top-level peers: Shared/ (shared kernel), Collaborators/ (cross-aggregate
# protocols), Persistence/, UI/, App/, Observability/.
#
# Type categories are identified by filename suffix:
#   - *Command.swift  under Domains/<X>/Write/
#   - *Query.swift    under Domains/<X>/Read/
#   - *Handler.swift  under Domains/<X>/{Write,Read}/
# Plus path-anchored categories: Domains/<X>/Model/, Events/, Shared/.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

SRC="OCS"
fail=0

say() { printf 'cqrs-lint: %s\n' "$*" >&2; fail=1; }

# Persistence/ is the target name; Database/ is the current name pre-rename.
# Both are accepted while the rename is pending.
persistence_paths=( "$SRC/Persistence" "$SRC/Database" )

# G17 carve-out: DeviceBootstrap is documented at App/DeviceBootstrap.swift and
# does direct GRDB writes to the `devices` table (no Command, no Handler, no
# Event). It is the only file outside Persistence/ permitted to import GRDB.
g17_grdb_exempt_files=( "$SRC/App/DeviceBootstrap.swift" )

grep_swift() {
  # $1 = pattern, remaining args = paths. Recurses; restricts to *.swift.
  local pattern="$1"; shift
  local paths=()
  for p in "$@"; do [ -d "$p" ] && paths+=( "$p" ); done
  [ "${#paths[@]}" -eq 0 ] && return 0
  grep -RnE --include='*.swift' "$pattern" "${paths[@]}" 2>/dev/null || true
}

#-------------------------------------------------------------------------------
# G3: Every Command has a Handler in the same folder.
#     Every Query has a Handler in the same folder.
#-------------------------------------------------------------------------------
if [ -d "$SRC/Domains" ]; then
  while IFS= read -r cmd; do
    handler="${cmd%Command.swift}Handler.swift"
    [ -f "$handler" ] || say "G3: missing handler $handler for $cmd"
  done < <(find "$SRC/Domains" -type f -path '*/Write/*Command.swift' 2>/dev/null)

  while IFS= read -r q; do
    handler="${q%Query.swift}Handler.swift"
    [ -f "$handler" ] || say "G3: missing handler $handler for $q"
  done < <(find "$SRC/Domains" -type f -path '*/Read/*Query.swift' 2>/dev/null)
fi

#-------------------------------------------------------------------------------
# G6: INSERT INTO event tables only inside EventStoreGRDB.swift, or in named
#     query files at queries/insert_*_event_*.sql which EventStoreGRDB loads.
#-------------------------------------------------------------------------------
if [ -d "$SRC" ]; then
  matches="$(grep -RnE --include='*.swift' --include='*.sql' \
            'INSERT[[:space:]]+INTO[[:space:]]+(entry_events|tag_events)' \
            "$SRC" 2>/dev/null \
            | grep -vE '/EventStoreGRDB\.swift:|/queries/insert_(entry|tag)_event_[a-z0-9_]+\.sql:' \
            || true)"
  if [ -n "$matches" ]; then
    say "G6: INSERT INTO event tables outside EventStoreGRDB.swift / queries/insert_*_event_*.sql:"
    printf '%s\n' "$matches" >&2
  fi
fi

#-------------------------------------------------------------------------------
# G7: INSERT INTO projection tables only inside Projector.swift, or in named
#     query files at queries/project_*.sql which Projector loads.
#-------------------------------------------------------------------------------
if [ -d "$SRC" ]; then
  matches="$(grep -RnE --include='*.swift' --include='*.sql' \
            'INSERT[[:space:]]+INTO[[:space:]]+(entries|tags|entry_tags)' \
            "$SRC" 2>/dev/null \
            | grep -vE '/Projector\.swift:|/queries/project_[a-z0-9_]+\.sql:' \
            || true)"
  if [ -n "$matches" ]; then
    say "G7: INSERT INTO projection tables outside Projector.swift / queries/project_*.sql:"
    printf '%s\n' "$matches" >&2
  fi
fi

#-------------------------------------------------------------------------------
# G5: import GRDB only in Persistence/ (or transitional Database/)
#-------------------------------------------------------------------------------
if [ -d "$SRC" ]; then
  matches="$(grep_swift '^import[[:space:]]+GRDB([[:space:]]|$)' "$SRC")"
  if [ -n "$matches" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      file="${line%%:*}"
      ok=0
      for p in "${persistence_paths[@]}"; do
        case "$file" in "$p"/*) ok=1; break;; esac
      done
      if [ "$ok" -eq 0 ]; then
        for f in "${g17_grdb_exempt_files[@]}"; do
          [ "$file" = "$f" ] && ok=1
        done
      fi
      [ "$ok" -eq 0 ] && say "G5: import GRDB outside Persistence/: $line"
    done <<< "$matches"
  fi
fi

#-------------------------------------------------------------------------------
# G5: AppKit/SwiftUI/UIKit must not appear in Domains/, Shared/, Collaborators/
#-------------------------------------------------------------------------------
forbidden_ui_paths=( "$SRC/Domains" "$SRC/Shared" "$SRC/Collaborators" )
matches="$(grep_swift '^import[[:space:]]+(AppKit|SwiftUI|UIKit)([[:space:]]|$)' "${forbidden_ui_paths[@]}")"
if [ -n "$matches" ]; then
  say "G5: AppKit/SwiftUI/UIKit imported in Domains/Shared/Collaborators:"
  printf '%s\n' "$matches" >&2
fi

#-------------------------------------------------------------------------------
# G8: Date() and UUID() must not appear in any *Handler.swift
#-------------------------------------------------------------------------------
if [ -d "$SRC/Domains" ]; then
  while IFS= read -r f; do
    if grep -nE '(Date\(\)|UUID\(\))' "$f" 2>/dev/null > /tmp/cqrs-handler-misuse.$$; then
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        say "G8: Date()/UUID() in handler ${f}: $line"
      done < /tmp/cqrs-handler-misuse.$$
    fi
    rm -f /tmp/cqrs-handler-misuse.$$
  done < <(find "$SRC/Domains" -type f -name '*Handler.swift' 2>/dev/null)
fi

#-------------------------------------------------------------------------------
# G1: Commands, Queries, Events must be struct/enum (no class). var stored
#     properties forbidden in the same set.
#-------------------------------------------------------------------------------
collect_value_files=()
if [ -d "$SRC/Domains" ]; then
  while IFS= read -r f; do collect_value_files+=( "$f" ); done \
    < <(find "$SRC/Domains" -type f -path '*/Write/*Command.swift' 2>/dev/null)
  while IFS= read -r f; do collect_value_files+=( "$f" ); done \
    < <(find "$SRC/Domains" -type f -path '*/Read/*Query.swift' 2>/dev/null)
  while IFS= read -r f; do collect_value_files+=( "$f" ); done \
    < <(find "$SRC/Domains" -type f -path '*/Events/*.swift' 2>/dev/null)
fi
if [ -d "$SRC/Shared/Events" ]; then
  while IFS= read -r f; do collect_value_files+=( "$f" ); done \
    < <(find "$SRC/Shared/Events" -type f -name '*.swift' 2>/dev/null)
fi

for f in "${collect_value_files[@]:-}"; do
  [ -z "${f:-}" ] && continue
  if grep -nE '^[[:space:]]*(public[[:space:]]+|internal[[:space:]]+|private[[:space:]]+|fileprivate[[:space:]]+)?(final[[:space:]]+)?class[[:space:]]+' "$f" 2>/dev/null > /tmp/cqrs-class.$$; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      say "G1: class declaration in value category ${f}: $line"
    done < /tmp/cqrs-class.$$
  fi
  rm -f /tmp/cqrs-class.$$

  if grep -nE '^[[:space:]]+var[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*[:=]' "$f" 2>/dev/null \
      | grep -vE '\{[[:space:]]*get' > /tmp/cqrs-var.$$ && [ -s /tmp/cqrs-var.$$ ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      say "G1: var stored property in value category ${f}: $line"
    done < /tmp/cqrs-var.$$
  fi
  rm -f /tmp/cqrs-var.$$
done

#-------------------------------------------------------------------------------
# G1: ReadModels (any .swift in Domains/<X>/Read/ that is neither Handler nor
#     Query) must use let for stored properties.
#-------------------------------------------------------------------------------
if [ -d "$SRC/Domains" ]; then
  while IFS= read -r f; do
    case "$(basename "$f")" in
      *Handler.swift|*Query.swift) continue ;;
    esac
    if grep -nE '^[[:space:]]+var[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*[:=]' "$f" 2>/dev/null \
        | grep -vE '\{[[:space:]]*get' > /tmp/cqrs-rmvar.$$ && [ -s /tmp/cqrs-rmvar.$$ ]; then
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        say "G1: var stored property in ReadModel ${f}: $line"
      done < /tmp/cqrs-rmvar.$$
    fi
    rm -f /tmp/cqrs-rmvar.$$
  done < <(find "$SRC/Domains" -type f -path '*/Read/*.swift' 2>/dev/null)
fi

#-------------------------------------------------------------------------------
# G5: UI must not reference any Events/ folder. (Path-based heuristic.)
#-------------------------------------------------------------------------------
if [ -d "$SRC/UI" ]; then
  matches="$(grep_swift '/Events/' "$SRC/UI")"
  if [ -n "$matches" ]; then
    say "G5: UI references an Events/ folder; UI deals in commands/queries only:"
    printf '%s\n' "$matches" >&2
  fi
fi

#-------------------------------------------------------------------------------
# Naming: a Command in Read/ is forbidden; a Query in Write/ is forbidden.
# Other filenames in Write/ and Read/ are allowed (aggregate-internal helpers,
# ReadModels, etc.); the matching-pair check above (G3) covers the cases that
# matter.
#-------------------------------------------------------------------------------
if [ -d "$SRC/Domains" ]; then
  while IFS= read -r f; do
    case "$(basename "$f")" in
      *Command.swift) say "G2: $f under Read/ must not be a Command. Commands belong in Write/." ;;
      *Query.swift)   ;; # queries can live in Read/ in principle, but our find filters Read/ only here
    esac
  done < <(find "$SRC/Domains" -type f -path '*/Read/*.swift' 2>/dev/null)

  while IFS= read -r f; do
    case "$(basename "$f")" in
      *Query.swift) say "G2: $f under Write/ must not be a Query. Queries belong in Read/." ;;
    esac
  done < <(find "$SRC/Domains" -type f -path '*/Write/*.swift' 2>/dev/null)
fi

#-------------------------------------------------------------------------------
# Done
#-------------------------------------------------------------------------------
if [ "$fail" -ne 0 ]; then
  printf '\ncqrs-lint: violations found. See CQRS.md for the full rules.\n' >&2
  exit 1
fi

printf 'cqrs-lint: ok\n'
exit 0
