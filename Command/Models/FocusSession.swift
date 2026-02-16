import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var endedAt: Date?
    var plannedMinutes: Int = 25
    var breaksTaken: Int = 0
    var wasCompleted: Bool = false

    var mission: Mission?

    init(mission: Mission, plannedMinutes: Int = 25) {
        self.mission = mission
        self.plannedMinutes = plannedMinutes
    }

    var durationMinutes: Int? {
        guard let ended = endedAt else { return nil }
        return Int(ended.timeIntervalSince(startedAt) / 60)
    }
}
