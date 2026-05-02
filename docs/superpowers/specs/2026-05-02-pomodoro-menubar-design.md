# Pomodoro Menu Bar App — Design

## Goal
Lightweight macOS menu bar Pomodoro timer with native notifications, configurable durations, auto/manual phase switching, and simple stats.

## Stack
- **Swift + SwiftUI**, native AppKit hosting (`NSStatusItem`, `NSPopover`).
- **SwiftPM executable** built from CLI; `build.sh` assembles a `.app` bundle (notifications require a bundled app).
- **No external dependencies.**

## UX
- Menu bar shows `🍅 MM:SS` while running, `🍅 Pomodoro` when idle, `🍅 ⏸ MM:SS` paused.
- **Left-click** status item → SwiftUI popover with timer / settings / stats.
- **Right-click** → minimal menu: Start/Pause, Reset, Quit.
- Dock icon hidden via `LSUIElement = YES` and `NSApp.setActivationPolicy(.accessory)`.

## Popover sections
1. **Timer** — big countdown, phase label "Work · 2 of 4", buttons Start/Pause/Reset/Skip.
2. **Settings** — work / short break / long break (minutes, steppers), sessions until long break, toggles for auto-start and sound.
3. **Stats** — today, this week, all-time pomodoro counts + focused minutes; reset button.

## Components
- `PomodoroTimer: ObservableObject` — state machine `{idle, running, paused}`, phase `{work, shortBreak, longBreak}`, completed-session counter, 1Hz `Timer`.
- `Settings: ObservableObject` — `@AppStorage`-backed durations and toggles.
- `Stats: ObservableObject` — array of completed-work timestamps in `UserDefaults`; derived today/week/all counts.
- `Notifier` — `UNUserNotificationCenter` permission + post; sound gated by setting; if auto-start off, includes "Start break/work" action button.
- `AppDelegate` — owns status item, popover, right-click menu, observes timer to update title.
- SwiftUI: `PopoverView`, `TimerView`, `SettingsView`, `StatsView`.

## Defaults
Work 25m / Short 5m / Long 15m / Sessions-until-long 4 / auto-start ON / sound ON.

## Persistence
Everything in `UserDefaults`. Stats stored as `[Date]` of completed work sessions; pruned/queried in-memory.

## Build
`./build.sh` → `swift build -c release` → assemble `Pomodoro.app/Contents/{MacOS/Pomodoro, Info.plist}`. Codesign ad-hoc for local notification entitlement.

## Out of scope (v1)
Daily history chart, custom sound files, keyboard shortcuts, multi-device sync, launch-at-login.
