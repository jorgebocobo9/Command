import Foundation
import SwiftData

@MainActor final class StreakService {
    func recordCompletion(category: MissionCategory, context: ModelContext) {
        let streakCategory: StreakCategory = switch category {
        case .school: .school
        case .work: .work
        case .personal: .personal
        }

        updateStreak(streakCategory, context: context)
        updateStreak(.overall, context: context)
    }

    private func updateStreak(_ category: StreakCategory, context: ModelContext) {
        let descriptor = FetchDescriptor<Streak>(
            predicate: #Predicate { $0.category == category }
        )

        if let streak = try? context.fetch(descriptor).first {
            streak.recordActivity()
        } else {
            let streak = Streak(category: category)
            streak.recordActivity()
            context.insert(streak)
        }

        try? context.save()
    }

    func getStreaks(context: ModelContext) -> [Streak] {
        let descriptor = FetchDescriptor<Streak>()
        return (try? context.fetch(descriptor)) ?? []
    }
}
