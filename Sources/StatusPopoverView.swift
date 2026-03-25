import SwiftUI

struct StatusPopoverView: View {
    @ObservedObject var driveService: GoogleDriveService
    var onOpenMainWindow: () -> Void
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            QuickAccessTab(driveService: driveService, onOpenMainWindow: onOpenMainWindow)
                .tabItem {
                    Label("Files", systemImage: "folder")
                }
                .tag(0)

            DownloadsTab()
                .tabItem {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }
                .tag(1)

            SettingsTab(driveService: driveService)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .frame(width: 380, height: 420)
    }
}

// MARK: - Quick Access Tab

struct QuickAccessTab: View {
    @ObservedObject var driveService: GoogleDriveService
    var onOpenMainWindow: () -> Void
    @StateObject private var searchService = FileSearchService()
    @StateObject private var favoritesStore = FavoritesStore.shared
    @StateObject private var recentStore = RecentFilesStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                TextField("Search files...", text: $searchService.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { searchService.search() }
                if !searchService.query.isEmpty {
                    Button(action: { searchService.query = ""; searchService.results = [] }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: NSColor.controlBackgroundColor))

            Divider()

            // Content
            if searchService.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !searchService.query.isEmpty {
                searchResultsView
            } else {
                defaultContentView
            }
        }
    }

    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(searchService.results) { file in
                    QuickFileRowView(file: file, isFavorite: favoritesStore.isFavorite(file.id))
                }
            }
            .padding(8)
        }
    }

    private var defaultContentView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Quick actions
                HStack(spacing: 8) {
                    quickActionButton(icon: "folder", label: "My Drive", action: onOpenMainWindow)
                    quickActionButton(icon: "star", label: "Starred", action: {})
                    quickActionButton(icon: "clock", label: "Recent", action: {})
                    quickActionButton(icon: "trash", label: "Trash", action: {})
                }

                // Recent files
                if !recentStore.recentFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RECENT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.05)

                        ForEach(recentStore.recentFiles.prefix(5)) { file in
                            QuickFileRowView(file: file, isFavorite: favoritesStore.isFavorite(file.id))
                        }
                    }
                }

                // Favorites
                if !favoritesStore.favorites.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("STARRED")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.05)

                        ForEach(favoritesStore.favorites.prefix(5)) { file in
                            QuickFileRowView(file: file, isFavorite: true)
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - File Row View

struct QuickFileRowView: View {
    let file: DriveFile
    let isFavorite: Bool
    @ObservedObject private var downloadManager = DownloadManager.shared

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: file.icon)
                .resizable()
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(file.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                if !file.isFolder {
                    Text(file.formattedSize)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundColor(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)

            if !file.isFolder {
                Button(action: { downloadManager.download(file) }) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .onTapGesture(count: 2) {
            // Open file
        }
    }
}

// MARK: - Downloads Tab

struct DownloadsTab: View {
    @ObservedObject private var downloadManager = DownloadManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Downloads")
                    .font(.headline)
                Spacer()
                if !downloadManager.queue.isEmpty {
                    Button("Clear All") {
                        downloadManager.cancelAll()
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            Divider()

            if downloadManager.queue.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No downloads")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(downloadManager.queue) { item in
                            DownloadRowView(item: item)
                        }
                    }
                    .padding(12)
                }
            }
        }
    }
}

struct DownloadRowView: View {
    let item: DownloadItem
    @ObservedObject private var downloadManager = DownloadManager.shared

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: item.file.icon)
                .resizable()
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.file.name)
                    .font(.system(size: 12))
                    .lineLimit(1)

                HStack {
                    switch item.status {
                    case .pending:
                        Text("Pending")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    case .downloading:
                        ProgressView(value: item.progress)
                            .progressViewStyle(.linear)
                            .frame(width: 80)
                        Text("\(Int(item.progress * 100))%")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    case .completed:
                        Text("Completed")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    case .failed:
                        Text("Failed")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    case .cancelled:
                        Text("Cancelled")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if item.status == .downloading || item.status == .pending {
                Button(action: { downloadManager.cancelDownload(item.id) }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

// MARK: - Settings Tab

struct SettingsTab: View {
    @ObservedObject var driveService: GoogleDriveService

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Account
                if let user = driveService.currentUser {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACCOUNT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.05)

                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.system(size: 13, weight: .medium))
                                Text(user.email)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(nsColor: NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }

                    // Sign out
                    Button(action: { driveService.signOut() }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                // About
                VStack(alignment: .leading, spacing: 8) {
                    Text("ABOUT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.05)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nimbus")
                            .font(.system(size: 13, weight: .medium))
                        Text("Google Drive client for macOS")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            .padding(12)
        }
    }
}
