import Foundation
import SwiftData
import SwiftUI

@Observable
final class IntelViewModel {
    var energyProfiles: [EnergyProfile] = []
    var streaks: [Streak] = []
    var completedMissions: [Mission] = []
    var totalFocusMinutes: Int = 0
    var totalMissionsCompleted: Int = 0

    func load(context: ModelContext) {
        // Energy profiles
        let profileDescriptor = FetchDescriptor<EnergyProfile>()
        energyProfiles = (try? context.fetch(profileDescriptor)) ?? []

        // Streaks
        let streakDescriptor = FetchDescriptor<Streak>()
        streaks = (try? context.fetch(streakDescriptor)) ?? []

        // Completed missions
        let missionDescriptor = FetchDescriptor<Mission>(
            predicate: #Predicate { $0.status == .completed }
        )
        completedMissions = (try? context.fetch(missionDescriptor)) ?? []
        totalMissionsCompleted = completedMissions.count

        // Total focus minutes
        let sessionDescriptor = FetchDescriptor<FocusSession>()
        let sessions = (try? context.fetch(sessionDescriptor)) ?? []
        totalFocusMinutes = sessions.compactMap(\.durationMinutes).reduce(0, +)
    }
}
