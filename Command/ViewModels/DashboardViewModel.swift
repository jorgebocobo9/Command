import Foundation
import SwiftData
import SwiftUI

@Observable
final class DashboardViewModel {
    var todayMissions: [Mission] = []
    var allActiveMissions: [Mission] = []
    var streaks: [Streak] = []
    var currentEnergy: Double = 0.5

    func load(context: ModelContext) async {
        let calendar = Calendar.current
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!

        // All non-completed missions
        let completed = MissionStatus.completed
        let abandoned = MissionStatus.abandoned
        let allDescriptor = FetchDescriptor<Mission>(
            predicate: #Predicate { mission in
                mission.status != completed && mission.status != abandoned
            }
        )
        allActiveMissions = (try? context.fetch(allDescriptor)) ?? []

        // Today's missions: due today or overdue
        todayMissions = allActiveMissions.filter { mission in
            guard let deadline = mission.deadline else { return false }
            return deadline <= endOfDay
        }.sorted { a, b in
            let aDeadline = a.deadline ?? .distantFuture
            let bDeadline = b.deadline ?? .distantFuture
            return aDeadline < bDeadline
        }

        // Load energy level from EnergyProfile if available
        let hour = calendar.component(.hour, from: Date())
        let weekday = calendar.component(.weekday, from: Date())
        let energyDescriptor = FetchDescriptor<EnergyProfile>(
            predicate: #Predicate { $0.hourOfDay == hour && $0.dayOfWeek == weekday }
        )
        currentEnergy = (try? context.fetch(energyDescriptor).first?.averageProductivity) ?? 0.5

        // Load streaks
        let streakDescriptor = FetchDescriptor<Streak>()
        streaks = (try? context.fetch(streakDescriptor)) ?? []
    }
}
