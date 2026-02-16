// Placeholder — Backend agent will replace
import Foundation
import SwiftData

@Model
final class Resource {
    var id: UUID = UUID()
    var title: String = ""
    var urlString: String = ""
    var type: ResourceType = .article
    var mission: Mission?
    var step: MissionStep?

    init(title: String, urlString: String, type: ResourceType) {
        self.title = title
        self.urlString = urlString
        self.type = type
    }
}
