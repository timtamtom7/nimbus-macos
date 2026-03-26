import Foundation

// MARK: - Nimbus R13: Enterprise & Knowledge Management

/// Wiki/Knowledge Base, Permission Hierarchies, Compliance, SSO
final class NimbusEnterpriseService: ObservableObject {
    static let shared = NimbusEnterpriseService()

    @Published var wikiSpaces: [WikiSpace] = []
    @Published var auditLog: [AuditEntry] = []
    @Published var contentExpirations: [ContentExpiration] = []
    @Published var ssoConfig: SSOConfig?

    struct WikiSpace: Identifiable, Codable {
        let id: UUID; var name: String; var sections: [WikiSection]; var permissions: [UUID: String]
        var createdAt: Date
    }

    struct WikiSection: Identifiable, Codable {
        let id: UUID; var name: String; var pages: [WikiPage]
    }

    struct WikiPage: Identifiable, Codable {
        let id: UUID; var title: String; var content: String; var tags: [String]
    }

    struct AuditEntry: Identifiable, Codable {
        let id: UUID; let action: AuditAction; let user: String; let noteId: UUID?
        var detail: String; let timestamp: Date
    }

    enum AuditAction: String, Codable {
        case noteViewed, noteEdited, noteShared, commentAdded, exported
    }

    struct ContentExpiration: Identifiable, Codable {
        let id: UUID; let noteId: UUID; var reviewDate: Date; var notified: Bool
    }

    struct SSOConfig: Codable {
        var provider: SSOProvider; var enabled: Bool
    }

    enum SSOProvider: String, Codable { case okta, azureAD, googleWorkspace }

    private init() { loadState() }

    func createSpace(name: String) -> WikiSpace {
        let space = WikiSpace(id: UUID(), name: name, sections: [], permissions: [:], createdAt: Date())
        wikiSpaces.append(space); saveState(); return space
    }

    func logAccess(action: AuditAction, user: String, noteId: UUID?, detail: String) {
        let entry = AuditEntry(id: UUID(), action: action, user: user, noteId: noteId, detail: detail, timestamp: Date())
        auditLog.insert(entry, at: 0); saveState()
    }

    func setExpiration(noteId: UUID, reviewDate: Date) {
        let exp = ContentExpiration(id: UUID(), noteId: noteId, reviewDate: reviewDate, notified: false)
        contentExpirations.append(exp); saveState()
    }

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nimbus/enterprise.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = NimbusEnterpriseState(wikiSpaces: wikiSpaces, auditLog: auditLog, contentExpirations: contentExpirations, ssoConfig: ssoConfig)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(NimbusEnterpriseState.self, from: data) else { return }
        wikiSpaces = state.wikiSpaces; auditLog = state.auditLog
        contentExpirations = state.contentExpirations; ssoConfig = state.ssoConfig
    }
}

struct NimbusEnterpriseState: Codable {
    var wikiSpaces: [NimbusEnterpriseService.WikiSpace]
    var auditLog: [NimbusEnterpriseService.AuditEntry]
    var contentExpirations: [NimbusEnterpriseService.ContentExpiration]
    var ssoConfig: NimbusEnterpriseService.SSOConfig?
}
