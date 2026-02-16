import AppIntents
import SwiftData

struct AddMissionIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Mission"
    static let description: IntentDescription = "Quickly add a new mission to Nag"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Title")
    var missionTitle: String

    @Parameter(title: "Category", default: .school)
    var category: MissionCategoryEntity

    @Parameter(title: "Priority", default: .medium)
    var priority: MissionPriorityEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$missionTitle) mission") {
            \.$category
            \.$priority
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([
            Mission.self,
            MissionStep.self,
            Resource.self,
            FocusSession.self,
            EnergyProfile.self,
            Streak.self,
            ClassroomCourse.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let mission = Mission(title: missionTitle, category: category.toMissionCategory)
        mission.priority = priority.toMissionPriority
        context.insert(mission)
        try context.save()

        return .result(dialog: "Added \"\(missionTitle)\" to your missions.")
    }
}

// MARK: - Entity wrappers for App Intents

enum MissionCategoryEntity: String, AppEnum {
    case school
    case work
    case personal

    nonisolated static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    nonisolated static let caseDisplayRepresentations: [MissionCategoryEntity: DisplayRepresentation] = [
        .school: "School",
        .work: "Work",
        .personal: "Personal",
    ]

    var toMissionCategory: MissionCategory {
        switch self {
        case .school: return .school
        case .work: return .work
        case .personal: return .personal
        }
    }
}

enum MissionPriorityEntity: String, AppEnum {
    case low
    case medium
    case high
    case critical

    nonisolated static let typeDisplayRepresentation: TypeDisplayRepresentation = "Priority"
    nonisolated static let caseDisplayRepresentations: [MissionPriorityEntity: DisplayRepresentation] = [
        .low: "Low",
        .medium: "Medium",
        .high: "High",
        .critical: "Critical",
    ]

    var toMissionPriority: MissionPriority {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .critical: return .critical
        }
    }
}
