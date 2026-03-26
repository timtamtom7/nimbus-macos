import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var mainWindow: NSWindow?
    private var eventMonitor: Any?
    private let driveService = GoogleDriveService.shared
    private let settingsStore = SettingsStore.shared
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = NimbusCollaborationService.shared
        _ = NimbusEnterpriseService.shared
        _ = NimbusiOSService.shared
        NimbusAPIService.shared.start()

        setupStatusItem()
        setupPopover()
        setupEventMonitor()

        settingsStore.loadSettings()
    }

    func applicationWillTerminate(_ notification: Notification) {
        NimbusAPIService.shared.stop()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "Nimbus")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 300)
        popover.behavior = .transient
        popover.animates = true

        let contentView = StatusPopoverView(
            driveService: driveService,
            onOpenMainWindow: { [weak self] in
                self?.openMainWindow()
            }
        )
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    // MARK: - Main Window

    func openMainWindow() {
        popover.performClose(nil)

        if mainWindow == nil {
            let contentView = MainBrowserView(driveService: driveService)
            let hostingController = NSHostingController(rootView: contentView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Nimbus"
            window.setContentSize(NSSize(width: 800, height: 600))
            window.minSize = NSSize(width: 600, height: 400)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.center()
            window.isReleasedWhenClosed = false

            mainWindow = window
        }

        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Event Monitor

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }
}

// MARK: - NimbusState

@MainActor
final class NimbusState {
    static let shared = NimbusState()

    var recentFiles: [DriveFile] = []
    var favorites: [String] = []

    private init() {}

    func searchFiles(query: String) -> [DriveFile] {
        // Search is done through GoogleDriveService
        return []
    }

    func getRecentFiles(limit: Int) -> [DriveFile] {
        return Array(recentFiles.prefix(limit))
    }
}
