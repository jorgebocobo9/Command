// Placeholder — Backend agent will replace
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

    init(plannedMinutes: Int = 25) {
        self.plannedMinutes = plannedMinutes
    }
}
