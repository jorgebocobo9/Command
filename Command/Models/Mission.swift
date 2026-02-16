import Foundation
import SwiftData

@Model
final class Mission {
    var id: UUID = UUID()
    var title: String = ""
    var missionDescription: String = ""
    var source: MissionSource = MissionSource.manual
    var category: MissionCategory = MissionCategory.school
    var status: MissionStatus = MissionStatus.pending
    var priority: MissionPriority = MissionPriority.medium
    var aggressionLevel: AggressionLevel = AggressionLevel.moderate
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

    var totalActualMinutes: Int {
        focusSessions.reduce(0) { total, session in
            guard let ended = session.endedAt else { return total }
            return total + Int(ended.timeIntervalSince(session.startedAt) / 60)
        }
    }

    /// Auto-prioritization score (0-100). Higher = more urgent.
    var urgencyScore: Double {
        var score: Double = 0

        // Deadline proximity (0-50)
        if let deadline {
            let hoursUntil = deadline.timeIntervalSinceNow / 3600
            if hoursUntil < 0 {
                // Overdue — max urgency, increases the longer it's overdue
                score += min(50, 50 + hoursUntil / 24 * 2) // still 50 base
                score = max(score, 45) // floor at 45 for any overdue
            } else if hoursUntil < 6 {
                score += 42
            } else if hoursUntil < 24 {
                score += 35
            } else if hoursUntil < 48 {
                score += 28
            } else if hoursUntil < 168 { // 7 days
                score += 18
            } else {
                score += 8
            }
        } else {
            score += 5 // no deadline = low urgency
        }

        // Priority (0-20)
        switch priority {
        case .critical: score += 20
        case .high: score += 14
        case .medium: score += 8
        case .low: score += 3
        }

        // Aggression (0-15)
        switch aggressionLevel {
        case .nuclear: score += 15
        case .aggressive: score += 10
        case .moderate: score += 5
        case .gentle: score += 0
        }

        // Near-completion bonus (0-10) — nudge tasks that are almost done
        if !steps.isEmpty {
            let progress = stepProgress
            if progress > 0.7 { score += 10 }
            else if progress > 0.4 { score += 5 }
            else if progress > 0 { score += 2 }
        }

        return min(score, 100)
    }
}
