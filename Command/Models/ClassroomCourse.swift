import Foundation
import SwiftData

@Model
final class ClassroomCourse {
    var courseId: String = ""
    var name: String = ""
    var section: String?
    var lastSyncedAt: Date = Date()
    var isActive: Bool = true

    init(courseId: String, name: String) {
        self.courseId = courseId
        self.name = name
    }
}
