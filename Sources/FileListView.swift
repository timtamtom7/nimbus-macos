import SwiftUI
import Quartz

struct MainBrowserView: View {

    @ObservedObject var driveService: GoogleDriveService
    @State private var selectedFile: DriveFile?
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 0) {
            BrowserToolbar(
                path: driveService.currentPath,
                onBack: { driveService.navigateBack() },
                onHome: { driveService.navigateToRoot() },
                onRefresh: {
                    if let last = driveService.currentPath.last {
                        Task { await driveService.listFiles(inFolder: last.id) }
                    } else {
                        Task { await driveService.listFiles() }
                    }
                },
                canGoBack: !driveService.currentPath.isEmpty
            )

            Divider()

            if driveService.isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if driveService.files.isEmpty {
                Spacer()
                VStack(spacing: Theme.spacingM) {
                    Image(systemName: "folder")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No files")
                        .font(.headline)
                    Text("This folder is empty")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                FileListView(
                    files: driveService.files,
                    selectedFile: $selectedFile,
                    onOpen: { file in
                        if file.isFolder {
                            driveService.navigateToFolder(file)
                        } else {
                            driveService.openFile(file)
                        }
                    },
                    onDownload: { file in
                        downloadFile(file)
                    },
                    onPreview: { file in
                        previewFile(file)
                    },
                    onShowInBrowser: { file in
                        driveService.openInBrowser(file)
                    }
                )
            }

            Divider()

            HStack {
                Text("\(driveService.files.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Theme.spacingXS)
        }
        .onAppear {
            if driveService.files.isEmpty {
                Task { await driveService.listFiles() }
            }
        }
        .onChange(of: errorMessage) { _, newValue in
            showError = newValue != nil
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .accessibilityLabel("File browser view")
    }

    private func downloadFile(_ file: DriveFile) {
        Task {
            do {
                let url = try await driveService.downloadToLocal(file)
                await MainActor.run {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func previewFile(_ file: DriveFile) {
        if !file.isFolder {
            Task {
                do {
                    let url = try await driveService.downloadToLocal(file)
                    await MainActor.run {
                        NSApp.activate(ignoringOtherApps: true)
                        let panel = QLPreviewPanel.shared()
                        panel?.makeKeyAndOrderFront(nil)
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

// MARK: - Browser Toolbar

struct BrowserToolbar: View {

    let path: [DriveFile]
    let onBack: () -> Void
    let onHome: () -> Void
    let onRefresh: () -> Void
    let canGoBack: Bool

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!canGoBack)
            .accessibilityLabel("Navigate back")

            Button(action: onHome) {
                Image(systemName: "house")
            }
            .accessibilityLabel("Go to home folder")

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .accessibilityLabel("Refresh file list")

            Divider()
                .frame(height: 20)

            BreadcrumbView(path: path)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, Theme.spacingS)
        .background(Theme.surface)
    }
}

// MARK: - Breadcrumb

struct BreadcrumbView: View {

    let path: [DriveFile]

    var body: some View {
        HStack(spacing: 2) {
            Text("Root")
                .font(.caption)
                .foregroundColor(path.isEmpty ? .primary : Theme.primary)

            ForEach(Array(path.enumerated()), id: \.element.id) { index, folder in
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(folder.name)
                    .font(.caption)
                    .foregroundColor(index == path.count - 1 ? .primary : Theme.primary)
            }
        }
    }
}

// MARK: - File List

struct FileListView: View {

    let files: [DriveFile]
    @Binding var selectedFile: DriveFile?
    let onOpen: (DriveFile) -> Void
    let onDownload: (DriveFile) -> Void
    let onPreview: (DriveFile) -> Void
    let onShowInBrowser: (DriveFile) -> Void

    var body: some View {
        List(selection: $selectedFile) {
            ForEach(files) { file in
                FileRowView(file: file)
                    .tag(file)
                    .contextMenu {
                        Button("Open") { onOpen(file) }
                        if !file.isFolder {
                            Divider()
                            Button("Download") { onDownload(file) }
                            Button("Preview") { onPreview(file) }
                        }
                        Button("Show in Browser") { onShowInBrowser(file) }
                    }
                    .onTapGesture(count: 2) {
                        onOpen(file)
                    }
            }
        }
        .listStyle(.inset)
    }
}

struct FileRowView: View {

    let file: DriveFile

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Image(nsImage: file.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .accessibilityLabel(file.isFolder ? "Folder icon" : "File icon: \(file.formattedSize)")

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: Theme.spacingM) {
                    Text(file.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(file.formattedModified)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !file.isFolder {
                        Text((file.name as NSString).pathExtension.uppercased())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Theme.spacingXS)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(Theme.cornerRadiusSmall)
                    } else {
                        Text("Folder")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Theme.spacingXS)
                            .padding(.vertical, 2)
                            .background(Theme.primary.opacity(0.2))
                            .cornerRadius(Theme.cornerRadiusSmall)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
