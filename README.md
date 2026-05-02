# Pomodoro

Lightweight macOS menu bar Pomodoro timer. Native Swift + SwiftUI, no dependencies, ~265KB binary, no dock icon.

## Features

- Lives in the menu bar — countdown always visible: `🍅 24:32`
- Native macOS notification with alert sound at the end of each session
- Configurable durations (work / short break / long break) and sessions-until-long-break
- Auto or manual phase switching
- Simple stats: today / this week / all time

## Requirements

- macOS 13+
- Xcode Command Line Tools (`xcode-select --install`) — does not need to open Xcode

## Build & run

```bash
./build.sh           # builds release Pomodoro.app
open Pomodoro.app    # launches; tomato icon appears in the menu bar
```

To run from source without bundling (no notifications, dock icon will appear):

```bash
swift run
```

## Usage

- **Left-click** the menu bar icon → popover with timer, settings, and stats.
- **Right-click** the menu bar icon → quick menu (Start/Pause, Reset, Quit).
- The first time you launch, macOS will ask for notification permission.

## Project layout

```
Sources/Pomodoro/
├── main.swift              # entry point, sets accessory activation policy
├── AppDelegate.swift       # status item, popover, right-click menu
├── PomodoroTimer.swift     # state machine + 1Hz tick
├── Settings.swift          # @AppStorage-backed preferences
├── Stats.swift             # completion log + derived counters
├── Notifier.swift          # UNUserNotificationCenter wrapper
└── Views/
    ├── PopoverView.swift
    ├── TimerView.swift
    ├── SettingsView.swift
    └── StatsView.swift
Resources/Info.plist        # LSUIElement (hides dock icon)
build.sh                    # swift build → .app bundle + ad-hoc sign
```

## Notes

- Notifications require a bundled `.app` (not a loose binary), which is why `build.sh` assembles one.
- All state (settings + completed-session timestamps) persists in `UserDefaults`.
