import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    private let settings = Settings()
    private let stats = Stats()
    private let notifier = Notifier.shared
    private lazy var timer = PomodoroTimer(settings: settings, stats: stats, notifier: notifier)

    func applicationDidFinishLaunching(_ notification: Notification) {
        notifier.requestAuthorization()

        // Status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🍅 Pomodoro"
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Popover with SwiftUI root
        popover = NSPopover()
        popover.behavior = .transient
        let host = NSHostingController(
            rootView: PopoverView()
                .environmentObject(timer)
                .environmentObject(settings)
                .environmentObject(stats)
        )
        // Let SwiftUI's intrinsic size drive the popover from the very first show,
        // so it doesn't appear detached and then snap to the menu bar.
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host

        // Update menu bar title on every timer change
        timer.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.updateStatusTitle() }
            .store(in: &cancellables)

        // React to duration changes while idle
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.timer.applyDurationsIfIdle() }
            .store(in: &cancellables)

        updateStatusTitle()
    }

    private func updateStatusTitle() {
        guard let button = statusItem.button else { return }
        switch timer.state {
        case .idle:
            button.title = "🍅 \(timer.formattedRemaining)"
        case .running:
            button.title = "🍅 \(timer.formattedRemaining)"
        case .paused:
            button.title = "🍅 ⏸ \(timer.formattedRemaining)"
        }
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            stopMonitor()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            startMonitor()
        }
    }

    private func startMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.popover.performClose(nil)
            self?.stopMonitor()
        }
    }

    private func stopMonitor() {
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
        eventMonitor = nil
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let toggleTitle: String = {
            switch timer.state {
            case .running: return "Pause"
            case .paused: return "Resume"
            case .idle: return "Start"
            }
        }()
        menu.addItem(withTitle: toggleTitle, action: #selector(menuToggle), keyEquivalent: "")
        menu.addItem(withTitle: "Reset", action: #selector(menuReset), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Pomodoro", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) {
            item.target = self
        }
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // detach so left-click goes back to popover
    }

    @objc private func menuToggle() { timer.toggle() }
    @objc private func menuReset() { timer.reset() }
}
