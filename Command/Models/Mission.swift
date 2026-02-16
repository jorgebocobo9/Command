// Placeholder — Backend agent will replace with full SwiftData model
import Foundation
import SwiftData

@Model
final class Mission {
    var id: UUID = UUID()
    var title: String = ""
    var missionDescription: String = ""
    var source: MissionSource = .manual
    var category: MissionCategory = .school
    var status: MissionStatus = .pending
    var priority: MissionPriority = .medium
    var aggressionLevel: AggressionLevel = .moderate
    var deadline: Date?
    var createdAt: Date = Date()
    var completedAt: Date?
    var estimatedMinutes: Int?
    var actualMinutes: Int?
    var cognitiveLoad: CognitiveLoad?
    var classroomCourseId: String?
    var classroomAssignmentId: String?

    @Relationship(deleteRule: .cascade) var steps: [MissionStep] = []
    @Relationship(deleteRule: .cascade) var resources: [Resource] = []
    @Relationship(deleteRule: .cascade) var focusSessions: [FocusSession] = []

    init(title: String, category: MissionCategory, source: MissionSource = .manual) {
        self.title = title
        self.category = category
        self.source = source
    }

    var isOverdue: Bool {
        guard let deadline else { return false }
        return deadline < Date() && status != .completed
    }

    var stepProgress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(steps.filter(\.isCompleted).count) / Double(steps.count)
    }
}
