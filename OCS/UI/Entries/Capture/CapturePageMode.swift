import Foundation

@MainActor
enum CapturePageMode: Equatable {
    case idle
    case suggestions(SlashSuggestionState)
    case entries(EntriesListPageState)
}
