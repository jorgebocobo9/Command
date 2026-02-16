import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class DashboardViewModel {
    var todayMissions: [Mission] = []
    var allActiveMissions: [Mission] = []
    var streaks: [Streak] = []
    var currentEnergy: Double = 0.5

    private let energyService = EnergyService()

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
        let todayRaw = allActiveMissions.filter { mission in
            guard let deadline = mission.deadline else { return false }
            return deadline <= endOfDay
        }

        // Sort by energy-aware ordering (overdue first, then by cognitive load vs current energy)
        todayMissions = energyService.suggestMissionOrder(todayRaw, context: context)

        // Load current energy level
        currentEnergy = energyService.currentEnergyLevel(context: context)

        // Load streaks
        let streakDescriptor = FetchDescriptor<Streak>()
        streaks = (try? context.fetch(streakDescriptor)) ?? []
    }
}
