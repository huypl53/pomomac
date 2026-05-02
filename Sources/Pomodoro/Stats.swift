import Foundation

final class Stats: ObservableObject {
    private let key = "completedWorkTimestamps"
    private let workMinutesKey = "totalWorkMinutes"

    @Published private(set) var completions: [Date] = []
    @Published private(set) var totalFocusMinutes: Int = 0

    init() {
        load()
    }

    func recordCompletedWork(durationMinutes: Int) {
        completions.append(Date())
        totalFocusMinutes += durationMinutes
        save()
    }

    func reset() {
        completions = []
        totalFocusMinutes = 0
        save()
    }

    var todayCount: Int {
        let cal = Calendar.current
        return completions.filter { cal.isDateInToday($0) }.count
    }

    var weekCount: Int {
        let cal = Calendar.current
        return completions.filter { cal.isDate($0, equalTo: Date(), toGranularity: .weekOfYear) }.count
    }

    var allTimeCount: Int { completions.count }

    var todayMinutes: Int {
        // Approximate: assume each session uses current default; we instead derive from total only for global.
        // For accuracy of "today minutes", we'd need per-session duration; we'll return todayCount * average.
        guard allTimeCount > 0 else { return 0 }
        let avg = Double(totalFocusMinutes) / Double(allTimeCount)
        return Int(Double(todayCount) * avg)
    }

    var weekMinutes: Int {
        guard allTimeCount > 0 else { return 0 }
        let avg = Double(totalFocusMinutes) / Double(allTimeCount)
        return Int(Double(weekCount) * avg)
    }

    private func load() {
        let d = UserDefaults.standard
        if let arr = d.array(forKey: key) as? [Date] {
            completions = arr
        }
        totalFocusMinutes = d.integer(forKey: workMinutesKey)
    }

    private func save() {
        let d = UserDefaults.standard
        d.set(completions, forKey: key)
        d.set(totalFocusMinutes, forKey: workMinutesKey)
    }
}
