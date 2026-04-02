import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.06, green: 0.07, blue: 0.09)
    static let card = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let cardSecondary = Color(red: 0.16, green: 0.17, blue: 0.21)
    static let accent = Color(red: 0.47, green: 0.89, blue: 0.58)
    static let accentMuted = Color(red: 0.22, green: 0.34, blue: 0.24)
    static let textSecondary = Color.white.opacity(0.68)
    static let border = Color.white.opacity(0.08)
}

enum AppFormat {
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static func monthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    static func weight(_ value: Double) -> String {
        if value == 0 { return "Bodyweight" }
        if value.rounded(.down) == value {
            return "\(Int(value)) lb"
        }
        return String(format: "%.1f lb", value)
    }

    static func editableWeight(_ value: Double) -> String {
        if value.rounded(.down) == value {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}
