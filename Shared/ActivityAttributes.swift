import ActivityKit

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var missionTitle: String
        var categoryHex: String
        var isPaused: Bool
    }

    var totalMinutes: Int
    var stepTitle: String?
}

struct DeadlineActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var isOverdue: Bool
    }

    var missionTitle: String
    var categoryHex: String
    var aggressionLevel: String
}
