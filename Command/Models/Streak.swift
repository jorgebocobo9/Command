import Foundation
import SwiftData

@Model
final class Streak {
    var category: StreakCategory = StreakCategory.overall
    var currentCount: Int = 0
    var longestCount: Int = 0
    var lastActiveDate: Date = Date()
    var momentumScore: Double = 0.0

    init(category: StreakCategory) {
        self.category = category
    }

    func recordActivity() {
        let calendar = Calendar.current
        let isConsecutive = calendar.isDate(lastActiveDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: Date())!)
        let isSameDay = calendar.isDateInToday(lastActiveDate)

        if isSameDay { return }

        if isConsecutive {
            currentCount += 1
        } else {
            currentCount = 1
        }

        longestCount = max(longestCount, currentCount)
        lastActiveDate = Date()

        // Momentum: weighted rolling average favoring recent activity
        momentumScore = (momentumScore * 0.7) + (Double(min(currentCount, 10)) / 10.0 * 0.3)
    }
}
