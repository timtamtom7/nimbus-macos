import SwiftUI

struct StatusPopoverView: View {

    @ObservedObject var driveService: GoogleDriveService
    var onOpenMainWindow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "cloud.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Nimbus")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            // Content
            if driveService.isAuthenticated {
                AuthenticatedView(driveService: driveService, onOpenMainWindow: onOpenMainWindow)
            } else {
                UnauthenticatedView(driveService: driveService)
            }

            Divider()

            // Footer
            HStack {
                Text("Nimbus R1")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
        }
        .frame(width: 380, height: 300)
    }
}

struct AuthenticatedView: View {

    @ObservedObject var driveService: GoogleDriveService
    var onOpenMainWindow: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            // User info
            if let user = driveService.currentUser {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }

            // Quota
            if let quota = driveService.quota {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    HStack {
                        Text("Storage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(quota.formattedUsed) of \(quota.formattedTotal)")
                            .font(.caption)
                    }
                    ProgressView(value: quota.usageFraction)
                        .progressViewStyle(.linear)
                }
                .padding(.horizontal)
            }

            // Actions
            HStack(spacing: Theme.spacingM) {
                Button(action: onOpenMainWindow) {
                    Label("Open NIMBUS", systemImage: "folder.badge.gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { driveService.signOut() }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct UnauthenticatedView: View {

    @ObservedObject var driveService: GoogleDriveService

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Not Connected")
                .font(.headline)

            Text("Sign in to access your Google Drive files")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { driveService.authenticate() }) {
                Label("Sign in with Google", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
    }
}
