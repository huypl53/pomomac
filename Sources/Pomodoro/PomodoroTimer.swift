import Foundation
import Combine

enum Phase: String {
    case work, shortBreak, longBreak

    var label: String {
        switch self {
        case .work: return "Work"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

enum TimerState {
    case idle, running, paused
}

final class PomodoroTimer: ObservableObject {
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var phase: Phase = .work
    @Published private(set) var remainingSeconds: Int = 25 * 60
    @Published private(set) var completedWorkInCycle: Int = 0

    private var ticker: Timer?
    private let settings: Settings
    private let stats: Stats
    private let notifier: Notifier

    init(settings: Settings, stats: Stats, notifier: Notifier) {
        self.settings = settings
        self.stats = stats
        self.notifier = notifier
        self.remainingSeconds = settings.workMinutes * 60
    }

    // MARK: - Controls

    func start() {
        guard state != .running else { return }
        state = .running
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        ticker?.invalidate()
        ticker = nil
    }

    func toggle() {
        switch state {
        case .running: pause()
        case .idle, .paused: start()
        }
    }

    func reset() {
        ticker?.invalidate()
        ticker = nil
        state = .idle
        phase = .work
        completedWorkInCycle = 0
        remainingSeconds = settings.workMinutes * 60
    }

    func skip() {
        ticker?.invalidate()
        ticker = nil
        advancePhase(completedNaturally: false)
    }

    /// Apply duration changes from Settings to the *current* idle phase only.
    func applyDurationsIfIdle() {
        guard state == .idle else { return }
        remainingSeconds = currentPhaseSeconds()
    }

    // MARK: - Internals

    private func tick() {
        guard remainingSeconds > 0 else {
            advancePhase(completedNaturally: true)
            return
        }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            advancePhase(completedNaturally: true)
        }
    }

    private func advancePhase(completedNaturally: Bool) {
        ticker?.invalidate()
        ticker = nil

        let endingPhase = phase

        if endingPhase == .work && completedNaturally {
            stats.recordCompletedWork(durationMinutes: settings.workMinutes)
            completedWorkInCycle += 1
        }

        // Determine next phase
        let nextPhase: Phase
        switch endingPhase {
        case .work:
            if completedWorkInCycle >= settings.sessionsUntilLongBreak {
                nextPhase = .longBreak
                completedWorkInCycle = 0
            } else {
                nextPhase = .shortBreak
            }
        case .shortBreak, .longBreak:
            nextPhase = .work
        }

        phase = nextPhase
        remainingSeconds = currentPhaseSeconds()

        if completedNaturally {
            notifier.notifyPhaseEnded(ended: endingPhase, next: nextPhase, playSound: settings.playSound)
        }

        if settings.autoStartNextPhase && completedNaturally {
            start()
        } else {
            state = .idle
        }
    }

    private func currentPhaseSeconds() -> Int {
        switch phase {
        case .work: return settings.workMinutes * 60
        case .shortBreak: return settings.shortBreakMinutes * 60
        case .longBreak: return settings.longBreakMinutes * 60
        }
    }

    var formattedRemaining: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
