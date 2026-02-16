import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert])
        } catch {
            return false
        }
    }

    // MARK: - Categories

    func registerCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Mark Complete",
            options: [.authenticationRequired]
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 15m",
            options: []
        )
        let startFocusAction = UNNotificationAction(
            identifier: "START_FOCUS_ACTION",
            title: "Start Focus",
            options: [.foreground]
        )

        let missionCategory = UNNotificationCategory(
            identifier: "MISSION_REMINDER",
            actions: [completeAction, snoozeAction, startFocusAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let urgentCategory = UNNotificationCategory(
            identifier: "URGENT_REMINDER",
            actions: [completeAction, startFocusAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([missionCategory, urgentCategory])
    }

    // MARK: - Scheduling

    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        triggerDate: Date,
        categoryIdentifier: String = "MISSION_REMINDER",
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = userInfo

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleIntervalNotification(
        id: String,
        title: String,
        body: String,
        interval: TimeInterval,
        repeats: Bool = false,
        categoryIdentifier: String = "MISSION_REMINDER"
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 1), repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotifications(for missionId: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let idsToRemove = requests
                .filter { $0.identifier.hasPrefix(missionId) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
