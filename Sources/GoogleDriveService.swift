import Foundation
import AppKit
import Combine
import Security

// MARK: - Models

struct DriveFile: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let mimeType: String
    let size: Int64?
    let modifiedTime: Date?
    let createdTime: Date?
    let parents: [String]?
    let webContentLink: String?
    let webViewLink: String?
    let isFolder: Bool

    init(from file: GoogleDriveFile) {
        self.id = file.id
        self.name = file.name
        self.mimeType = file.mimeType
        self.size = file.size
        self.modifiedTime = ISO8601DateFormatter().date(from: file.modifiedTime ?? "")
        self.createdTime = ISO8601DateFormatter().date(from: file.createdTime ?? "")
        self.parents = file.parents
        self.webContentLink = file.webContentLink
        self.webViewLink = file.webViewLink
        self.isFolder = file.mimeType == "application/vnd.google-apps.folder"
    }

    init(id: String, name: String, mimeType: String, size: Int64? = nil, modifiedTime: Date? = nil, createdTime: Date? = nil, parents: [String]? = nil, webContentLink: String? = nil, webViewLink: String? = nil, isFolder: Bool = false) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.size = size
        self.modifiedTime = modifiedTime
        self.createdTime = createdTime
        self.parents = parents
        self.webContentLink = webContentLink
        self.webViewLink = webViewLink
        self.isFolder = isFolder
    }

    var icon: NSImage {
        if isFolder {
            return NSImage(systemSymbolName: "folder.fill", accessibilityDescription: "Folder") ?? NSImage()
        }
        return NSWorkspace.shared.icon(forFileType: (name as NSString).pathExtension) ?? NSImage()
    }

    var formattedSize: String {
        guard let size = size else { return "--" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedModified: String {
        guard let date = modifiedTime else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct GoogleDriveFile: Codable {
    let id: String
    let name: String
    let mimeType: String
    let size: Int64?
    let modifiedTime: String?
    let createdTime: String?
    let parents: [String]?
    let webContentLink: String?
    let webViewLink: String?
    var starred: Bool?

    init(id: String = "", name: String, mimeType: String, size: Int64? = nil, modifiedTime: String? = nil, createdTime: String? = nil, parents: [String]? = nil, webContentLink: String? = nil, webViewLink: String? = nil, starred: Bool? = nil) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.size = size
        self.modifiedTime = modifiedTime
        self.createdTime = createdTime
        self.parents = parents
        self.webContentLink = webContentLink
        self.webViewLink = webViewLink
        self.starred = starred
    }
}

struct DriveQuota: Codable {
    let used: Int64
    let total: Int64
    let limit: Int64?

    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
    }

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    var usageFraction: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
}

// MARK: - GoogleDriveService

class GoogleDriveService: ObservableObject {

    static let shared = GoogleDriveService()

    @Published var isAuthenticated = false
    @Published var currentUser: DriveUser?
    @Published var files: [DriveFile] = []
    @Published var currentPath: [DriveFile] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var quota: DriveQuota?

    private let keychainService = "com.nimbus.macos"
    private let clientID = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
    private let redirectURI = "com.nimbus.macos:/oauth2callback"
    private let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
    private let apiBase = URL(string: "https://www.googleapis.com/drive/v3")!
    private let authURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!

    private var accessToken: String? {
        get { keychainValue(for: "accessToken") }
        set {
            if let v = newValue {
                setKeychainValue(v, for: "accessToken")
            } else {
                removeKeychainValue(for: "accessToken")
            }
        }
    }

    private var refreshToken: String? {
        get { keychainValue(for: "refreshToken") }
        set {
            if let v = newValue {
                setKeychainValue(v, for: "refreshToken")
            } else {
                removeKeychainValue(for: "refreshToken")
            }
        }
    }

    private var tokenExpiry: Date? {
        get {
            guard let s = keychainValue(for: "tokenExpiry") else { return nil }
            return ISO8601DateFormatter().date(from: s)
        }
        set {
            if let v = newValue {
                setKeychainValue(ISO8601DateFormatter().string(from: v), for: "tokenExpiry")
            } else {
                removeKeychainValue(for: "tokenExpiry")
            }
        }
    }

    private func keychainValue(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func setKeychainValue(_ value: String, for account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    private func removeKeychainValue(for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private init() {
        checkAuthStatus()
    }

    // MARK: - Auth

    func checkAuthStatus() {
        if let token = accessToken, let expiry = tokenExpiry, expiry > Date() {
            isAuthenticated = true
            Task { await fetchUserInfo() }
        } else if refreshToken != nil {
            Task { await refreshAccessToken() }
        } else {
            isAuthenticated = false
        }
    }

    func authenticate() {
        let scope = "https://www.googleapis.com/auth/drive.readonly"
        var components = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        NSWorkspace.shared.open(components.url!)
        setupOAuthCallback()
    }

    private func setupOAuthCallback() {
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == "com.apple.Safari" else { return }

            // In production, use a custom URL scheme handler
            // For now, prompt user to paste the auth code
            self?.promptForAuthCode()
        }
    }

    private func promptForAuthCode() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Enter Authorization Code"
            alert.informativeText = "Paste the code from the browser URL (code=...):"
            alert.addButton(withTitle: "Verify")
            alert.addButton(withTitle: "Cancel")

            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
            textField.placeholderString = "Paste code here"
            alert.accessoryView = textField

            if alert.runModal() == .alertFirstButtonReturn {
                let code = textField.stringValue.trimmingCharacters(in: .whitespaces)
                Task { await self.exchangeCodeForTokens(code) }
            }
        }
    }

    private func exchangeCodeForTokens(_ code: String) async {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "code": code,
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]

        request.httpBody = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&").data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)
            await MainActor.run {
                self.accessToken = tokens.accessToken
                self.refreshToken = tokens.refreshToken
                let expiry = Date().addingTimeInterval(TimeInterval(tokens.expiresIn - 60))
                self.tokenExpiry = expiry
                self.isAuthenticated = true
            }
            await fetchUserInfo()
        } catch {
            await MainActor.run {
                self.error = "Auth failed: \(error.localizedDescription)"
            }
        }
    }

    private func refreshAccessToken() async {
        guard let refresh = refreshToken else { return }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "refresh_token": refresh,
            "client_id": clientID,
            "grant_type": "refresh_token"
        ]

        request.httpBody = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)
            await MainActor.run {
                self.accessToken = tokens.accessToken
                let expiry = Date().addingTimeInterval(TimeInterval(tokens.expiresIn - 60))
                self.tokenExpiry = expiry
                self.isAuthenticated = true
            }
            await fetchUserInfo()
        } catch {
            await MainActor.run {
                self.error = "Token refresh failed"
                self.isAuthenticated = false
            }
        }
    }

    func signOut() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        currentUser = nil
        files = []
        currentPath = []
        isAuthenticated = false
    }

    // MARK: - API

    private func authorizedRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")
        return request
    }

    func fetchUserInfo() async {
        let url = apiBase.appendingPathComponent("about").appending(queryItems: [
            URLQueryItem(name: "fields", value: "user(displayName,emailAddress),storageQuota")
        ])

        do {
            let (data, _) = try await URLSession.shared.data(for: authorizedRequest(for: url))
            let about = try JSONDecoder().decode(AboutResponse.self, from: data)
            await MainActor.run {
                self.currentUser = DriveUser(
                    name: about.user.displayName,
                    email: about.user.emailAddress
                )
                if let q = about.storageQuota {
                    self.quota = DriveQuota(
                        used: Int64(q.usage ?? "0") ?? 0,
                        total: Int64(q.limit ?? "0") ?? 0,
                        limit: Int64(q.limit ?? "0")
                    )
                }
            }
        } catch {
            print("Failed to fetch user info: \(error)")
        }
    }

    func listFiles(inFolder folderID: String? = nil) async {
        await MainActor.run { self.isLoading = true }

        var urlComponents = URLComponents(url: apiBase.appendingPathComponent("files"), resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "pageSize", value: "100"),
            URLQueryItem(name: "orderBy", value: "folder, name"),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,size,modifiedTime,createdTime,parents,webContentLink,webViewLink),nextPageToken")
        ]

        if let folderID = folderID {
            queryItems.append(URLQueryItem(name: "q", value: "'\(folderID)' in parents and trashed = false"))
        } else {
            queryItems.append(URLQueryItem(name: "q", value: "'root' in parents and trashed = false"))
        }

        urlComponents.queryItems = queryItems

        do {
            let (data, _) = try await URLSession.shared.data(for: authorizedRequest(for: urlComponents.url!))
            let response = try JSONDecoder().decode(FileListResponse.self, from: data)
            let driveFiles = response.files.map { DriveFile(from: $0) }
            await MainActor.run {
                self.files = driveFiles
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to list files: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func navigateToFolder(_ folder: DriveFile) {
        guard folder.isFolder else { return }
        currentPath.append(folder)
        Task { await listFiles(inFolder: folder.id) }
    }

    func navigateBack() {
        guard !currentPath.isEmpty else { return }
        currentPath.removeLast()
        if let last = currentPath.last {
            Task { await listFiles(inFolder: last.id) }
        } else {
            Task { await listFiles() }
        }
    }

    func navigateToRoot() {
        currentPath = []
        Task { await listFiles() }
    }

    func downloadFile(_ file: DriveFile, to destination: URL, progress: @escaping (Double) -> Void) async throws {
        guard let webContentLink = file.webContentLink,
              let url = URL(string: webContentLink) else {
            throw DriveError.noDownloadLink
        }

        var request = authorizedRequest(for: url)
        request.httpMethod = "GET"

        let (tempURL, response) = try await URLSession.shared.download(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.downloadFailed
        }

        let fileManager = FileManager.default
        try fileManager.moveItem(at: tempURL, to: destination)
    }

    func downloadToLocal(_ file: DriveFile) async throws -> URL {
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let nimbusDir = downloadsDir.appendingPathComponent("NIMBUS", isDirectory: true)

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: nimbusDir.path) {
            try fileManager.createDirectory(at: nimbusDir, withIntermediateDirectories: true)
        }

        let destination = nimbusDir.appendingPathComponent(file.name)
        try await downloadFile(file, to: destination) { _ in }

        return destination
    }

    func openInBrowser(_ file: DriveFile) {
        guard let urlString = file.webViewLink, let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    func openFile(_ file: DriveFile) {
        if file.isFolder {
            navigateToFolder(file)
        } else {
            Task {
                do {
                    let url = try await downloadToLocal(file)
                    await MainActor.run {
                        NSWorkspace.shared.open(url)
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to open file: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // MARK: - Batch Operations (R5)

    func moveFile(fileId: String, toFolderId: String) async throws {
        guard let accessToken = accessToken else { throw DriveError.notAuthenticated }

        let metadata = ["parents": [toFolderId]]
        let body = try JSONEncoder().encode(metadata)

        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?addParents=\(toFolderId)")!)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.downloadFailed
        }
    }

    func copyFile(fileId: String, toFolderId: String) async throws {
        guard let accessToken = accessToken else { throw DriveError.notAuthenticated }

        let metadata = GoogleDriveFile(name: "", mimeType: "", parents: [toFolderId])
        let body = try JSONEncoder().encode(metadata)

        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)/copy")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.downloadFailed
        }
    }

    func deleteFile(fileId: String) async throws {
        guard let accessToken = accessToken else { throw DriveError.notAuthenticated }

        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)")!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 || httpResponse.statusCode == 200 else {
            throw DriveError.downloadFailed
        }
    }

    func renameFile(fileId: String, newName: String) async throws {
        guard let accessToken = accessToken else { throw DriveError.notAuthenticated }

        let metadata = GoogleDriveFile(name: newName, mimeType: "")
        let body = try JSONEncoder().encode(metadata)

        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)")!)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.downloadFailed
        }
    }

    func starFile(fileId: String, starred: Bool) async throws {
        guard let accessToken = accessToken else { throw DriveError.notAuthenticated }

        let metadata = GoogleDriveFile(name: "", mimeType: "", starred: starred)
        let body = try JSONEncoder().encode(metadata)

        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)")!)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.downloadFailed
        }
    }
}

// MARK: - Response Types

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct DriveUser: Codable {
    let name: String
    let email: String
}

struct AboutResponse: Codable {
    let user: AboutUser
    let storageQuota: StorageQuota?

    enum CodingKeys: String, CodingKey {
        case user
        case storageQuota = "storageQuota"
    }
}

struct AboutUser: Codable {
    let displayName: String
    let emailAddress: String
}

struct StorageQuota: Codable {
    let usage: String?
    let limit: String?
}

struct FileListResponse: Codable {
    let files: [GoogleDriveFile]
    let nextPageToken: String?
}

// MARK: - Errors

enum DriveError: LocalizedError {
    case noDownloadLink
    case downloadFailed
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .noDownloadLink: return "No download link available"
        case .downloadFailed: return "Download failed"
        case .notAuthenticated: return "Not authenticated"
        }
    }
}
