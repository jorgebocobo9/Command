import Foundation

// MARK: - Per-Level Config

struct AggressionLevelConfig: Codable, Equatable {
    var notificationCount: Int
    var firstReminderMinutes: Int
    var overdueIntervalMinutes: Int  // nuclear only
    var overdueCount: Int            // nuclear only

    static let defaultGentle = AggressionLevelConfig(
        notificationCount: 1, firstReminderMinutes: 1440, overdueIntervalMinutes: 0, overdueCount: 0
    )
    static let defaultModerate = AggressionLevelConfig(
        notificationCount: 5, firstReminderMinutes: 2880, overdueIntervalMinutes: 0, overdueCount: 0
    )
    static let defaultAggressive = AggressionLevelConfig(
        notificationCount: 8, firstReminderMinutes: 4320, overdueIntervalMinutes: 0, overdueCount: 0
    )
    static let defaultNuclear = AggressionLevelConfig(
        notificationCount: 8, firstReminderMinutes: 4320, overdueIntervalMinutes: 15, overdueCount: 8
    )

    static func defaultConfig(for level: AggressionLevel) -> AggressionLevelConfig {
        switch level {
        case .gentle: return defaultGentle
        case .moderate: return defaultModerate
        case .aggressive: return defaultAggressive
        case .nuclear: return defaultNuclear
        }
    }
}

// MARK: - Config Storage

enum AggressionConfigStore {
    static func config(for level: AggressionLevel) -> AggressionLevelConfig {
        let key = "aggressionConfig_\(level.rawValue)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let config = try? JSONDecoder().decode(AggressionLevelConfig.self, from: data) else {
            return AggressionLevelConfig.defaultConfig(for: level)
        }
        return config
    }

    static func save(_ config: AggressionLevelConfig, for level: AggressionLevel) {
        let key = "aggressionConfig_\(level.rawValue)"
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func resetToDefaults(for level: AggressionLevel) {
        let key = "aggressionConfig_\(level.rawValue)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Scheduler

enum AggressionScheduler {
    struct ScheduledNotification {
        let id: String
        let title: String
        let body: String
        let fireDate: Date
        let isUrgent: Bool
    }

    static func scheduleNotifications(for mission: Mission) -> [ScheduledNotification] {
        guard let deadline = mission.deadline else { return [] }
        let missionId = mission.id.uuidString
        let config = AggressionConfigStore.config(for: mission.aggressionLevel)

        var notifications = buildPreDeadline(
            level: mission.aggressionLevel,
            config: config,
            missionId: missionId,
            title: mission.title,
            deadline: deadline
        )

        // Nuclear: add overdue notifications
        if mission.aggressionLevel == .nuclear && config.overdueCount > 0 && config.overdueIntervalMinutes > 0 {
            for i in 1...config.overdueCount {
                let fireDate = deadline.addingTimeInterval(Double(i) * Double(config.overdueIntervalMinutes) * 60)
                guard fireDate > Date() else { continue }
                notifications.append(ScheduledNotification(
                    id: "\(missionId)-nuclear-overdue-\(i)",
                    title: "OVERDUE: \(mission.title)",
                    body: overdueMessage(minutesOverdue: i * config.overdueIntervalMinutes, title: mission.title),
                    fireDate: fireDate,
                    isUrgent: true
                ))
            }
        }

        return notifications
    }

    // MARK: - Build Pre-Deadline Notifications

    private static func buildPreDeadline(
        level: AggressionLevel,
        config: AggressionLevelConfig,
        missionId: String,
        title: String,
        deadline: Date
    ) -> [ScheduledNotification] {
        let count = max(1, config.notificationCount)
        let totalSeconds = Double(config.firstReminderMinutes) * 60

        // Evenly space notifications from firstReminder to deadline
        var notifications: [ScheduledNotification] = []
        for i in 0..<count {
            let fraction = count == 1 ? 1.0 : Double(i) / Double(count - 1)
            let offsetFromDeadline = totalSeconds * (1.0 - fraction)
            let fireDate = deadline.addingTimeInterval(-offsetFromDeadline)
            guard fireDate > Date() else { continue }

            let minutesBefore = Int(offsetFromDeadline / 60)
            let (ntitle, body) = notificationContent(
                level: level, title: title, minutesBefore: minutesBefore,
                index: i, total: count
            )

            notifications.append(ScheduledNotification(
                id: "\(missionId)-\(level.rawValue)-\(i)",
                title: ntitle,
                body: body,
                fireDate: fireDate,
                isUrgent: fraction > 0.6
            ))
        }
        return notifications
    }

    // MARK: - Content Generation

    private static func notificationContent(
        level: AggressionLevel, title: String, minutesBefore: Int,
        index: Int, total: Int
    ) -> (String, String) {
        let timeStr = formatMinutes(minutesBefore)
        let progress = total <= 1 ? 1.0 : Double(index) / Double(total - 1)

        switch level {
        case .gentle:
            return ("Reminder: \(title)", "Due in \(timeStr). You've got this.")
        case .moderate:
            if progress < 0.5 {
                return ("Heads up: \(title)", "'\(title)' is due in \(timeStr).")
            } else if progress < 0.8 {
                return ("\(timeStr) left", "'\(title)' needs your attention now.")
            } else {
                return ("\(timeStr) left", "'\(title)' — finish it now.")
            }
        case .aggressive, .nuclear:
            if progress < 0.3 {
                return ("\(timeStr) out", "'\(title)' — start now to stay ahead.")
            } else if progress < 0.6 {
                return ("\(timeStr) left", "'\(title)' — you need to move on this.")
            } else if progress < 0.85 {
                return ("\(timeStr) left", "'\(title)' — seriously, do it now.")
            } else {
                return ("\(timeStr)", "'\(title)' — you're about to miss this.")
            }
        }
    }

    private static func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 1440 {
            let days = minutes / 1440
            return days == 1 ? "1 day" : "\(days) days"
        } else if minutes >= 60 {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        } else {
            return "\(minutes) min"
        }
    }

    private static func overdueMessage(minutesOverdue: Int, title: String) -> String {
        if minutesOverdue < 30 {
            return "'\(title)' is overdue. Submit it NOW."
        } else if minutesOverdue < 60 {
            return "'\(title)' — \(minutesOverdue)min overdue. This is unacceptable."
        } else {
            return "'\(title)' — \(minutesOverdue)min overdue. Every minute counts. DO IT."
        }
    }
}
