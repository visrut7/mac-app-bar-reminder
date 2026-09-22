import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private let store = TodoStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("TwoDo: applicationDidFinishLaunching fired")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        NSLog("TwoDo: statusItem created, isVisible=\(statusItem.isVisible)")
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "TwoDo")
            image?.isTemplate = true
            if image == nil {
                NSLog("TwoDo: SF Symbol 'checklist' failed to load, falling back to text title")
                button.title = "2D"
                button.font = .systemFont(ofSize: 12, weight: .bold)
            } else {
                NSLog("TwoDo: SF Symbol loaded OK")
                button.image = image
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
        } else {
            NSLog("TwoDo: statusItem.button was nil!")
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 380)
        popover.contentViewController = NSHostingController(rootView: ContentView(store: store))

        // Dismiss the popover on any click outside it.
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }

        // This is what makes it act like a login pop-up: the app itself is
        // the login item (see "Launch at Login" toggle in TodoStore), so
        // every launch — including the one macOS triggers at login — opens
        // straight into the popover near the menu bar, no click required.
        DispatchQueue.main.async { [weak self] in
            self?.showPopover()
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        guard popover.isShown else { return }
        popover.performClose(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
