// Placeholder — Backend agent will replace
import Foundation
import SwiftData

@Model
final class Streak {
    var category: StreakCategory = .overall
    var currentCount: Int = 0
    var longestCount: Int = 0
    var lastActiveDate: Date = Date()
    var momentumScore: Double = 0.0

    init(category: StreakCategory) {
        self.category = category
    }
}
