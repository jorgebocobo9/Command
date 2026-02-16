// Placeholder — Backend agent will replace
import Foundation
import SwiftData

@Model
final class MissionStep {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var orderIndex: Int = 0
    var estimatedMinutes: Int?
    @Relationship(deleteRule: .cascade) var resources: [Resource] = []
    var mission: Mission?

    init(title: String, orderIndex: Int) {
        self.title = title
        self.orderIndex = orderIndex
    }
}
