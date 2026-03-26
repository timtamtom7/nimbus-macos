import Foundation

// MARK: - Nimbus R12-R15 Models

struct ClipboardTeam: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [ClipboardMember]
    var sharedBoards: [SharedBoard]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        members: [ClipboardMember] = [],
        sharedBoards: [SharedBoard] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.members = members
        self.sharedBoards = sharedBoards
        self.createdAt = createdAt
    }
}

struct ClipboardMember: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var role: TeamRole
    var isOnline: Bool

    enum TeamRole: String, Codable {
        case admin
        case editor
        case viewer
    }

    init(id: UUID = UUID(), name: String, email: String, role: TeamRole = .viewer, isOnline: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.isOnline = isOnline
    }
}

struct SharedBoard: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [ClipboardItem]
    var memberIds: [UUID]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, items: [ClipboardItem] = [], memberIds: [UUID] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.items = items
        self.memberIds = memberIds
        self.createdAt = createdAt
    }
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    var content: ClipboardContent
    var tags: [String]
    var createdAt: Date
    var expiresAt: Date?

    init(id: UUID = UUID(), content: ClipboardContent, tags: [String] = [], createdAt: Date = Date(), expiresAt: Date? = nil) {
        self.id = id
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

enum ClipboardContent: Codable {
    case text(String)
    case image(Data)
    case file(URL)
    case url(String)

    enum CodingKeys: String, CodingKey {
        case type, value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let s):
            try container.encode("text", forKey: .type)
            try container.encode(s, forKey: .value)
        case .image:
            try container.encode("image", forKey: .type)
        case .file(let url):
            try container.encode("file", forKey: .type)
            try container.encode(url.path, forKey: .value)
        case .url(let s):
            try container.encode("url", forKey: .type)
            try container.encode(s, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(try container.decode(String.self, forKey: .value))
        case "image":
            self = .image(Data())
        case "file":
            let path = try container.decode(String.self, forKey: .value)
            self = .file(URL(fileURLWithPath: path))
        case "url":
            self = .url(try container.decode(String.self, forKey: .value))
        default:
            self = .text("")
        }
    }
}

struct CloudSync: Codable {
    var isEnabled: Bool
    var lastSyncDate: Date?
    var syncConflicts: [SyncConflict]
}

struct SyncConflict: Identifiable, Codable {
    let id: UUID
    var localItem: ClipboardItem
    var remoteItem: ClipboardItem
    var resolvedAt: Date?
}
