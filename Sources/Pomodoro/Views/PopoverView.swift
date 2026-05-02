import SwiftUI

struct PopoverView: View {
    var body: some View {
        VStack(spacing: 0) {
            TimerView()
            Divider()
            SettingsView()
            Divider()
            StatsView()
        }
        .frame(width: 300)
        .padding(.vertical, 8)
    }
}
