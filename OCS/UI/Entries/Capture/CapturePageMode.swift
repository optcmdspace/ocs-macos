import Foundation

@MainActor
enum CapturePageMode: Equatable {
    case idle
    case suggestions(SlashSuggestionState)
    case tagSuggestions(TagSuggestionState)
    case entries(EntriesListPageState)
    case findResults(EntriesListPageState)
}
