import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate, MenuBarContentViewDelegate {
    private var statusItem: NSStatusItem!
    private var menuBarContent: MenuBarContentView!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    private let settings = Settings()
    private let stats = Stats()
    private let notifier = Notifier.shared
    private let launchAtLogin = LaunchAtLogin.shared
    private lazy var timer = PomodoroTimer(settings: settings, stats: stats, notifier: notifier)

    func applicationDidFinishLaunching(_ notification: Notification) {
        notifier.requestAuthorization()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = ""
            button.image = nil
            installMenuBarContent(in: button)
        }

        popover = NSPopover()
        popover.behavior = .transient
        let host = NSHostingController(
            rootView: PopoverView()
                .environmentObject(timer)
                .environmentObject(settings)
                .environmentObject(stats)
                .environmentObject(launchAtLogin)
                .environmentObject(notifier)
        )
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host

        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.timer.applyDurationsIfIdle() }
            .store(in: &cancellables)

        // Mirror timer state into the AppKit menu bar view.
        timer.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.refreshMenuBar() }
            .store(in: &cancellables)
        refreshMenuBar()
    }

    private func installMenuBarContent(in button: NSStatusBarButton) {
        let view = MenuBarContentView()
        view.delegate = self
        button.subviews.forEach { $0.removeFromSuperview() }
        button.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            view.topAnchor.constraint(equalTo: button.topAnchor),
            view.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])
        menuBarContent = view
        syncStatusItemWidth()
    }

    private func refreshMenuBar() {
        guard let menuBarContent else { return }
        let suffix: String
        switch timer.state {
        case .paused: suffix = " ⏸"
        default: suffix = ""
        }
        menuBarContent.setLabel("🍅 \(timer.formattedRemaining)\(suffix)")
        menuBarContent.setPauseSymbol(isRunning: timer.state == .running)
    }

    private func syncStatusItemWidth() {
        statusItem.length = menuBarContent.intrinsicContentSize.width
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            stopMonitor()
        } else {
            notifier.refreshStatus()
            launchAtLogin.refresh()
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
        statusItem.menu = nil
    }

    @objc private func menuToggle() { timer.toggle() }
    @objc private func menuReset() { timer.reset() }

    // MARK: - MenuBarContentViewDelegate

    func menuBarTogglePlay() { timer.toggle() }
    func menuBarSkip() { timer.skip() }
    func menuBarReset() { timer.reset() }
    func menuBarLabelClicked() { togglePopover() }
    func menuBarRightClicked() { showContextMenu() }
    func menuBarContentSizeDidChange() { syncStatusItemWidth() }
}
