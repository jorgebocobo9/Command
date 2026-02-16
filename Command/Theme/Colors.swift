import SwiftUI

enum CommandColors {
    // Backgrounds
    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "12121A")
    static let surfaceElevated = Color(hex: "1A1A25")
    static let surfaceBorder = Color(hex: "2A2A35")

    // Category accents
    static let school = Color(hex: "00D4FF")       // Cyan
    static let work = Color(hex: "FF2D78")          // Magenta
    static let personal = Color(hex: "00FF88")      // Green

    // Status
    static let urgent = Color(hex: "FF3B30")
    static let warning = Color(hex: "FF9500")
    static let success = Color(hex: "34C759")

    // Text
    static let textPrimary = Color(hex: "F5F5F7")
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary = Color(hex: "48484A")

    static func categoryColor(_ category: MissionCategory) -> Color {
        switch category {
        case .school: return school
        case .work: return work
        case .personal: return personal
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.init(
            red: Double((rgbValue >> 16) & 0xFF) / 255.0,
            green: Double((rgbValue >> 8) & 0xFF) / 255.0,
            blue: Double(rgbValue & 0xFF) / 255.0
        )
    }
}
