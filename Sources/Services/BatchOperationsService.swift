import Foundation
import AppKit

/// Batch file operations service for Nimbus
/// Supports: move, copy, delete, rename, share, star/unstar multiple files
/// Note: Actual Drive API calls would be added to GoogleDriveService
final class BatchOperationsService {
    static let shared = BatchOperationsService()

    private let driveService = GoogleDriveService.shared

    private init() {}

    // MARK: - Batch Move

    func moveFiles(_ files: [DriveFile], toFolderId: String) async throws -> BatchResult {
        var succeeded: [String] = []
        var failed: [(file: DriveFile, error: String)] = []

        for file in files {
            do {
                try await driveService.moveFile(fileId: file.id, toFolderId: toFolderId)
                succeeded.append(file.id)
            } catch {
                failed.append((file: file, error: error.localizedDescription))
            }
        }

        return BatchResult(
            succeeded: succeeded.count,
            failed: failed.count,
            errors: failed.map { "\($0.file.name): \($0.error)" }
        )
    }

    // MARK: - Batch Copy

    func copyFiles(_ files: [DriveFile], toFolderId: String) async throws -> BatchResult {
        var succeeded: [String] = []
        var failed: [(file: DriveFile, error: String)] = []

        for file in files {
            do {
                try await driveService.copyFile(fileId: file.id, toFolderId: toFolderId)
                succeeded.append(file.id)
            } catch {
                failed.append((file: file, error: error.localizedDescription))
            }
        }

        return BatchResult(
            succeeded: succeeded.count,
            failed: failed.count,
            errors: failed.map { "\($0.file.name): \($0.error)" }
        )
    }

    // MARK: - Batch Delete

    func deleteFiles(_ files: [DriveFile]) async throws -> BatchResult {
        var succeeded: [String] = []
        var failed: [(file: DriveFile, error: String)] = []

        for file in files {
            do {
                try await driveService.deleteFile(fileId: file.id)
                succeeded.append(file.id)
            } catch {
                failed.append((file: file, error: error.localizedDescription))
            }
        }

        return BatchResult(
            succeeded: succeeded.count,
            failed: failed.count,
            errors: failed.map { "\($0.file.name): \($0.error)" }
        )
    }

    // MARK: - Batch Rename

    func renameFiles(_ files: [DriveFile], withPrefix prefix: String) async throws -> BatchResult {
        var succeeded: [String] = []
        var failed: [(file: DriveFile, error: String)] = []

        for file in files {
            let newName = "\(prefix)\(file.name)"
            do {
                try await driveService.renameFile(fileId: file.id, newName: newName)
                succeeded.append(file.id)
            } catch {
                failed.append((file: file, error: error.localizedDescription))
            }
        }

        return BatchResult(
            succeeded: succeeded.count,
            failed: failed.count,
            errors: failed.map { "\($0.file.name): \($0.error)" }
        )
    }

    // MARK: - Batch Star/Unstar

    func starFiles(_ files: [DriveFile]) async throws -> BatchResult {
        var succeeded: [String] = []
        var failed: [(file: DriveFile, error: String)] = []

        for file in files {
            do {
                try await driveService.starFile(fileId: file.id, starred: true)
                succeeded.append(file.id)
            } catch {
                failed.append((file: file, error: error.localizedDescription))
            }
        }

        return BatchResult(
            succeeded: succeeded.count,
            failed: failed.count,
            errors: failed.map { "\($0.file.name): \($0.error)" }
        )
    }

    func unstarFiles(_ files: [DriveFile]) async throws -> BatchResult {
        var succeeded: [String] = []
        var failed: [(file: DriveFile, error: String)] = []

        for file in files {
            do {
                try await driveService.starFile(fileId: file.id, starred: false)
                succeeded.append(file.id)
            } catch {
                failed.append((file: file, error: error.localizedDescription))
            }
        }

        return BatchResult(
            succeeded: succeeded.count,
            failed: failed.count,
            errors: failed.map { "\($0.file.name): \($0.error)" }
        )
    }
}

// MARK: - Batch Result

struct BatchResult {
    let succeeded: Int
    let failed: Int
    let errors: [String]

    var summary: String {
        if failed == 0 {
            return "All \(succeeded) operations succeeded"
        }
        return "\(succeeded) succeeded, \(failed) failed"
    }
}
