import Foundation

// MARK: - Nimbus R12: Collaboration & Team Notes

/// Team notebooks, collaborative editing, comments, guest access, review workflows
final class NimbusCollaborationService: ObservableObject {
    static let shared = NimbusCollaborationService()

    @Published var sharedNotebooks: [SharedNotebook] = []
    @Published var comments: [NoteComment] = []
    @Published var reviewRequests: [ReviewRequest] = []
    @Published var guestInvites: [GuestInvite] = []
    @Published var teamTemplates: [SharedTemplate] = []

    private init() { loadState() }

    // MARK: - Shared Notebooks

    func shareNotebook(_ notebookId: UUID, with member: NotebookMember) {
        let shared = SharedNotebook(id: UUID(), notebookId: notebookId, members: [member], permissions: [:], createdAt: Date())
        sharedNotebooks.append(shared)
        saveState()
    }

    func addComment(noteId: UUID, author: String, text: String, range: CommentRange?) -> NoteComment {
        let comment = NoteComment(id: UUID(), noteId: noteId, author: author, text: text, range: range, resolved: false, createdAt: Date())
        comments.append(comment)
        saveState(); return comment
    }

    func resolveComment(_ id: UUID) {
        guard let idx = comments.firstIndex(where: { $0.id == id }) else { return }
        comments[idx].resolved = true; saveState()
    }

    // MARK: - Review Workflows

    func submitForReview(noteId: UUID, reviewer: String) -> ReviewRequest {
        let req = ReviewRequest(id: UUID(), noteId: noteId, reviewer: reviewer, status: .pending, submittedAt: Date())
        reviewRequests.append(req); saveState(); return req
    }

    func approveReview(_ id: UUID) {
        guard let idx = reviewRequests.firstIndex(where: { $0.id == id }) else { return }
        reviewRequests[idx].status = .approved; saveState()
    }

    // MARK: - Guest Access

    func inviteGuest(notebookId: UUID, email: String, accessLevel: GuestAccessLevel) -> GuestInvite {
        let invite = GuestInvite(id: UUID(), notebookId: notebookId, email: email, accessLevel: accessLevel, expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()), createdAt: Date())
        guestInvites.append(invite); saveState(); return invite
    }

    // MARK: - Shared Templates

    func addTemplate(_ template: SharedTemplate) {
        teamTemplates.append(template); saveState()
    }

    // MARK: - Persistence

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nimbus/collaboration.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = NimbusCollabState(sharedNotebooks: sharedNotebooks, comments: comments, reviewRequests: reviewRequests, guestInvites: guestInvites, teamTemplates: teamTemplates)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(NimbusCollabState.self, from: data) else { return }
        sharedNotebooks = state.sharedNotebooks; comments = state.comments
        reviewRequests = state.reviewRequests; guestInvites = state.guestInvites
        teamTemplates = state.teamTemplates
    }
}

// MARK: - Models

struct SharedNotebook: Identifiable, Codable {
    let id: UUID; let notebookId: UUID
    var members: [NotebookMember]; var permissions: [UUID: NotebookPermission]
    var createdAt: Date
}

struct NotebookMember: Identifiable, Codable {
    let id: UUID; var name: String; var email: String; var role: NotebookRole
}

enum NotebookRole: String, Codable { case admin, editor, viewer }
enum NotebookPermission: String, Codable { case read, write, admin }

struct NoteComment: Identifiable, Codable {
    let id: UUID; let noteId: UUID; var author: String; var text: String
    var range: CommentRange?; var resolved: Bool; let createdAt: Date
}

struct CommentRange: Codable {
    var start: Int; var end: Int
}

struct ReviewRequest: Identifiable, Codable {
    let id: UUID; let noteId: UUID; let reviewer: String
    var status: ReviewStatus; let submittedAt: Date
}

enum ReviewStatus: String, Codable { case pending, approved, rejected }

struct GuestInvite: Identifiable, Codable {
    let id: UUID; let notebookId: UUID; var email: String
    var accessLevel: GuestAccessLevel; var expiresAt: Date?; let createdAt: Date
}

enum GuestAccessLevel: String, Codable { case readOnly, contributor }

struct SharedTemplate: Identifiable, Codable {
    let id: UUID; var name: String; var content: String; var version: Int
    var createdAt: Date
}

struct NimbusCollabState: Codable {
    var sharedNotebooks: [SharedNotebook]; var comments: [NoteComment]
    var reviewRequests: [ReviewRequest]; var guestInvites: [GuestInvite]
    var teamTemplates: [SharedTemplate]
}
