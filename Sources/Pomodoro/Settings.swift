import Foundation
import SwiftUI

final class Settings: ObservableObject {
    @AppStorage("workMinutes") var workMinutes: Int = 25
    @AppStorage("shortBreakMinutes") var shortBreakMinutes: Int = 5
    @AppStorage("longBreakMinutes") var longBreakMinutes: Int = 15
    @AppStorage("sessionsUntilLongBreak") var sessionsUntilLongBreak: Int = 4
    @AppStorage("autoStartNextPhase") var autoStartNextPhase: Bool = true
    @AppStorage("playSound") var playSound: Bool = true
}
