import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private let store = TodoStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpMainMenu()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "TwoDo")
            image?.isTemplate = true
            if let image {
                button.image = image
            } else {
                button.title = "2D"
                button.font = .systemFont(ofSize: 12, weight: .bold)
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 420)
        popover.contentViewController = NSHostingController(rootView: ContentView(store: store))

        // Dismiss the popover on any click outside it.
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }

        // A daily schedule coming due while the app is already running
        // should surface the popover, same as the login auto-show below.
        store.onScheduledTrigger = { [weak self] in
            self?.showPopover()
        }

        // This is what makes it act like a login pop-up: the app itself is
        // the login item (see "Launch at Login" toggle in TodoStore), so
        // every launch — including the one macOS triggers at login — opens
        // straight into the popover near the menu bar, no click required.
        //
        // The delay matters: at login, several other login-item apps are
        // typically launching and activating themselves at the same time.
        // A `.transient` NSPopover auto-closes the instant its owning app
        // loses active status, so showing it immediately risks it being
        // stolen-focus-closed before it's ever perceived. Waiting lets that
        // initial login-time activation churn settle first.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showPopover()
        }
    }

    /// A menu-bar-only (`.accessory`) app has no visible menu bar, but
    /// without *any* NSMenu set as `mainMenu`, standard text-editing key
    /// equivalents (⌘A select-all, ⌘C/⌘V/⌘X, ⌘Z undo) silently stop
    /// reaching text fields. This menu is never shown on screen — it just
    /// restores that key-equivalent routing.
    private func setUpMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit TwoDo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
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
        // Activate *before* showing — a transient popover shown by an
        // inactive app is more likely to be immediately closed if another
        // app grabs activation right after.
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
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
