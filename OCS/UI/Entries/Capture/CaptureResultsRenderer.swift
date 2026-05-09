import AppKit
import Foundation

@MainActor
enum CaptureResultsRenderer {
    enum View: Equatable {
        case clear
        case loading
        case rows([TerminalRow.Spec])
    }

    static func view(
        for page: CapturePageMode,
        fieldText: String,
        singlePreview: EntryListItem?,
        sessionItems: [EntryListItem],
        previewLoading: Bool,
        freshSavedId: UUID?,
        now: Date
    ) -> View {
        let trailingMinWidth = Applied.Capture.outputTimestampMinWidth
        switch page {
        case .idle:
            if !sessionItems.isEmpty {
                return .rows(sessionItems.map {
                    CaptureRows.preview($0, now: now, trailingMinWidth: trailingMinWidth, highlighted: $0.id == freshSavedId)
                })
            }
            if let single = singlePreview {
                return .rows([CaptureRows.preview(single, now: now, trailingMinWidth: trailingMinWidth)])
            }
            if fieldText.isEmpty, previewLoading {
                return .loading
            }
            return .clear
        case .suggestions(let s):
            return .rows(s.list.renderedRows(CaptureRows.suggestion))
        case .tagSuggestions(let t):
            if t.list.isEmpty {
                return .rows([.message("create tag #\(t.prefix)")])
            }
            return .rows(t.list.renderedRows { CaptureRows.tagSuggestion($0, trailingMinWidth: 0) })
        case .entries(let e):
            if e.list.isEmpty {
                if e.hasError {
                    return .rows([.message("could not load entries")])
                }
                if e.isLoadingMore {
                    if e.loadingVisible { return .loading }
                    // Bridge the spinner-suppression window so the panel doesn't blank into list mode.
                    if e.scope == .active {
                        if !sessionItems.isEmpty {
                            return .rows(sessionItems.map {
                                CaptureRows.preview($0, now: now, trailingMinWidth: trailingMinWidth, highlighted: $0.id == freshSavedId)
                            })
                        }
                        if let single = singlePreview {
                            return .rows([CaptureRows.preview(single, now: now, trailingMinWidth: trailingMinWidth)])
                        }
                    }
                    // Hold the empty state for ~100ms so a fast query never flashes a spinner.
                    return .clear
                }
                let empty: String
                if let tag = e.tagFilter {
                    empty = "no captures with #\(tag.value)"
                } else if e.scope == .active {
                    empty = "nothing on your mind"
                } else {
                    empty = "no captures yet"
                }
                return .rows([.message(empty)])
            }
            var rows: [TerminalRow.Spec] = []
            if e.list.hiddenAbove > 0 {
                rows.append(.message("↑ \(e.list.hiddenAbove) more"))
            }
            rows.append(contentsOf: e.list.renderedItems {
                CaptureRows.entry($0, now: now, trailingMinWidth: trailingMinWidth)
            })
            // Until exhausted, hiddenBelow is a lower bound, the count would jump as pages land.
            if e.exhausted {
                if e.list.hiddenBelow > 0 {
                    rows.append(.message("↓ \(e.list.hiddenBelow) more"))
                }
            } else {
                rows.append(.message("↓ more"))
            }
            return .rows(rows)
        }
    }

    static func apply(_ view: View, to layout: CapturePanelLayout) {
        switch view {
        case .clear:
            layout.clearResults()
        case .loading:
            layout.results.setLoading()
            layout.showDivider(true)
        case .rows(let specs):
            layout.results.setRows(specs)
            layout.showDivider(true)
        }
    }
}
