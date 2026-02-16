import SwiftUI

enum CommandColors {
    // Backgrounds — stepped for clear layer separation
    static let background = Color(hex: "08080D")
    static let surface = Color(hex: "141420")
    static let surfaceElevated = Color(hex: "1C1C2E")
    static let surfaceBorder = Color(hex: "2C2C40")

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

// Color(hex:) extension is in Shared/ColorHex.swift
