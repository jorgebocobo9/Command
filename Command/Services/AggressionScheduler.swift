import Foundation

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

        switch mission.aggressionLevel {
        case .gentle:
            return gentleSchedule(missionId: missionId, title: mission.title, deadline: deadline)
        case .moderate:
            return moderateSchedule(missionId: missionId, title: mission.title, deadline: deadline)
        case .aggressive:
            return aggressiveSchedule(missionId: missionId, title: mission.title, deadline: deadline)
        case .nuclear:
            return nuclearSchedule(missionId: missionId, title: mission.title, deadline: deadline)
        }
    }

    // MARK: - Gentle: 1 notification, 24h before

    private static func gentleSchedule(missionId: String, title: String, deadline: Date) -> [ScheduledNotification] {
        let fireDate = deadline.addingTimeInterval(-24 * 3600)
        guard fireDate > Date() else { return [] }
        return [
            ScheduledNotification(
                id: "\(missionId)-gentle-1",
                title: "Reminder: \(title)",
                body: "Due tomorrow. You've got this.",
                fireDate: fireDate,
                isUrgent: false
            )
        ]
    }

    // MARK: - Moderate: 3 notifications + 2 re-notifies

    private static func moderateSchedule(missionId: String, title: String, deadline: Date) -> [ScheduledNotification] {
        var notifications: [ScheduledNotification] = []
        let intervals: [(TimeInterval, String, String)] = [
            (-48 * 3600, "Heads up", "'\(title)' is due in 2 days."),
            (-24 * 3600, "Due tomorrow", "'\(title)' — time to lock in."),
            (-6 * 3600, "6 hours left", "'\(title)' needs your attention now."),
            (-2 * 3600, "2 hours left", "'\(title)' is almost due. Focus up."),
            (-30 * 60, "30 minutes", "'\(title)' — this is it. Finish now.")
        ]

        for (i, entry) in intervals.enumerated() {
            let fireDate = deadline.addingTimeInterval(entry.0)
            guard fireDate > Date() else { continue }
            notifications.append(ScheduledNotification(
                id: "\(missionId)-moderate-\(i)",
                title: entry.1,
                body: entry.2,
                fireDate: fireDate,
                isUrgent: i >= 3
            ))
        }
        return notifications
    }

    // MARK: - Aggressive: 8 notifications with escalating tone

    private static func aggressiveSchedule(missionId: String, title: String, deadline: Date) -> [ScheduledNotification] {
        var notifications: [ScheduledNotification] = []
        let intervals: [(TimeInterval, String, String)] = [
            (-72 * 3600, "3 days out", "'\(title)' — start now to stay ahead."),
            (-48 * 3600, "2 days left", "'\(title)' — you need to move on this."),
            (-24 * 3600, "Tomorrow", "'\(title)' is due TOMORROW. No more delays."),
            (-12 * 3600, "12 hours", "'\(title)' — halfway to deadline. Are you working?"),
            (-6 * 3600, "6 hours", "'\(title)' — this is getting tight."),
            (-3 * 3600, "3 hours", "'\(title)' — seriously, do it now."),
            (-1 * 3600, "1 hour", "'\(title)' — final hour. Lock in or fail."),
            (-15 * 60, "15 minutes", "'\(title)' — you're about to miss this.")
        ]

        for (i, entry) in intervals.enumerated() {
            let fireDate = deadline.addingTimeInterval(entry.0)
            guard fireDate > Date() else { continue }
            notifications.append(ScheduledNotification(
                id: "\(missionId)-aggressive-\(i)",
                title: entry.1,
                body: entry.2,
                fireDate: fireDate,
                isUrgent: i >= 5
            ))
        }
        return notifications
    }

    // MARK: - Nuclear: 8 pre-deadline + every 15min when overdue

    private static func nuclearSchedule(missionId: String, title: String, deadline: Date) -> [ScheduledNotification] {
        var notifications = aggressiveSchedule(missionId: missionId, title: title, deadline: deadline)

        // Post-deadline: every 15 minutes for 2 hours
        for i in 1...8 {
            let fireDate = deadline.addingTimeInterval(Double(i) * 15 * 60)
            guard fireDate > Date() else { continue }
            notifications.append(ScheduledNotification(
                id: "\(missionId)-nuclear-overdue-\(i)",
                title: "OVERDUE: \(title)",
                body: overduMessage(minutesOverdue: i * 15, title: title),
                fireDate: fireDate,
                isUrgent: true
            ))
        }
        return notifications
    }

    private static func overduMessage(minutesOverdue: Int, title: String) -> String {
        switch minutesOverdue {
        case 0..<30:
            return "'\(title)' is overdue. Submit it NOW."
        case 30..<60:
            return "'\(title)' — \(minutesOverdue)min overdue. This is unacceptable."
        default:
            return "'\(title)' — \(minutesOverdue)min overdue. Every minute counts. DO IT."
        }
    }
}
