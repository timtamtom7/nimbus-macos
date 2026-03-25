import AppIntents
import Foundation

// MARK: - App Shortcuts Provider

struct NimbusShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchFilesIntent(),
            phrases: [
                "Search files in \(.applicationName)",
                "Find file with \(.applicationName)"
            ],
            shortTitle: "Search Files",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: GetRecentFilesIntent(),
            phrases: [
                "Get recent files in \(.applicationName)",
                "Recent files in \(.applicationName)"
            ],
            shortTitle: "Recent Files",
            systemImageName: "clock"
        )
    }
}

// MARK: - Search Files Intent

struct SearchFilesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Files"
    static var description = IntentDescription("Searches for files in Google Drive")

    @Parameter(title: "Search Query")
    var query: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search \(\.$query)")
    }

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let results = await NimbusState.shared.searchFiles(query: query)

        if results.isEmpty {
            return .result(dialog: "No files found for '\(query)'")
        }

        let topResults = Array(results.prefix(5))
        let names = topResults.map { $0.name }.joined(separator: ", ")
        let more = results.count > 5 ? " and \(results.count - 5) more" : ""

        return .result(dialog: "Found \(results.count) files: \(names)\(more)")
    }
}

// MARK: - Get Recent Files Intent

struct GetRecentFilesIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Recent Files"
    static var description = IntentDescription("Returns recently accessed files from Google Drive")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let recentFiles = await NimbusState.shared.getRecentFiles(limit: 5)

        if recentFiles.isEmpty {
            return .result(dialog: "No recent files found. Open Nimbus and browse your Drive first.")
        }

        let names = recentFiles.map { $0.name }.joined(separator: ", ")
        return .result(dialog: "Recent files: \(names)")
    }
}
