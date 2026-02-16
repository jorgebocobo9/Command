import Foundation

enum MissionSource: String, Codable {
    case manual
    case googleClassroom
}

enum MissionCategory: String, Codable, CaseIterable {
    case school
    case work
    case personal
}

enum MissionStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case abandoned
}

enum MissionPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case critical
}

enum AggressionLevel: String, Codable, CaseIterable {
    case gentle
    case moderate
    case aggressive
    case nuclear
}

enum CognitiveLoad: String, Codable, CaseIterable {
    case light
    case moderate
    case heavy
    case extreme
}

enum ResourceType: String, Codable {
    case video
    case article
    case documentation
    case tool
}

enum StreakCategory: String, Codable, CaseIterable {
    case school
    case work
    case personal
    case overall
}
