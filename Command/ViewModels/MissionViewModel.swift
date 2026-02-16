import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class MissionViewModel {
    var isDecomposing = false
    var decompositionError: String?

    func createMission(
        title: String,
        description: String,
        category: MissionCategory,
        priority: MissionPriority,
        aggressionLevel: AggressionLevel,
        deadline: Date?,
        context: ModelContext
    ) -> Mission {
        let mission = Mission(title: title, category: category)
        mission.missionDescription = description
        mission.priority = priority
        mission.aggressionLevel = aggressionLevel
        mission.deadline = deadline
        context.insert(mission)
        try? context.save()
        return mission
    }

    func completeMission(_ mission: Mission, context: ModelContext) {
        mission.status = .completed
        mission.completedAt = Date()
        try? context.save()
    }

    func abandonMission(_ mission: Mission, context: ModelContext) {
        mission.status = .abandoned
        try? context.save()
    }

    func deleteMission(_ mission: Mission, context: ModelContext) {
        context.delete(mission)
        try? context.save()
    }

    func toggleStep(_ step: MissionStep, context: ModelContext) {
        step.isCompleted.toggle()

        // Update mission status based on step completion
        if let mission = step.mission {
            let allCompleted = mission.steps.allSatisfy(\.isCompleted)
            if allCompleted && !mission.steps.isEmpty {
                mission.status = .completed
                mission.completedAt = Date()
            } else if mission.status == .completed {
                mission.status = .inProgress
                mission.completedAt = nil
            }
        }

        try? context.save()
    }

    func addStep(to mission: Mission, title: String, context: ModelContext) {
        let step = MissionStep(title: title, orderIndex: mission.steps.count)
        step.mission = mission
        mission.steps.append(step)
        try? context.save()
    }

    func removeStep(_ step: MissionStep, from mission: Mission, context: ModelContext) {
        mission.steps.removeAll { $0.id == step.id }
        context.delete(step)
        // Reindex remaining steps
        for (index, s) in mission.steps.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            s.orderIndex = index
        }
        try? context.save()
    }
}
