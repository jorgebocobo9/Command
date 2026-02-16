// Placeholder — Backend agent will replace
import Foundation
import SwiftData

@Model
final class EnergyProfile {
    var hourOfDay: Int = 0
    var dayOfWeek: Int = 1
    var averageProductivity: Double = 0.5
    var sampleCount: Int = 0

    init(hourOfDay: Int, dayOfWeek: Int) {
        self.hourOfDay = hourOfDay
        self.dayOfWeek = dayOfWeek
    }
}
