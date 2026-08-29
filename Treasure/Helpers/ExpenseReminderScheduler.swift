import Foundation
import UserNotifications

/// Local daily reminders at 10:00 and 20:00 to log expenses.
enum ExpenseReminderScheduler {
    static let morningId = "treasure.expense.reminder.morning"
    static let eveningId = "treasure.expense.reminder.evening"
    static let enabledKey = "reminders_enabled"

    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: enabledKey) == nil { return true }
        return UserDefaults.standard.bool(forKey: enabledKey)
    }

    static func requestAndSchedule() {
        UserDefaults.standard.set(true, forKey: enabledKey)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            schedule(center: center)
        }
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        if enabled {
            requestAndSchedule()
        } else {
            cancel()
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [morningId, eveningId])
    }

    static func rescheduleIfEnabled() {
        guard isEnabled else { return }
        schedule()
    }

    static func schedule(center: UNUserNotificationCenter = .current()) {
        center.removePendingNotificationRequests(withIdentifiers: [morningId, eveningId])
        addDailyReminder(
            id: morningId,
            hour: 10,
            minute: 0,
            title: L10n.string("expense_reminder_morning_title"),
            body: L10n.string("expense_reminder_morning_body"),
            center: center
        )
        addDailyReminder(
            id: eveningId,
            hour: 20,
            minute: 0,
            title: L10n.string("expense_reminder_evening_title"),
            body: L10n.string("expense_reminder_evening_body"),
            center: center
        )
    }

    static func notificationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private static func addDailyReminder(
        id: String,
        hour: Int,
        minute: Int,
        title: String,
        body: String,
        center: UNUserNotificationCenter
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "EXPENSE_REMINDER"

        var date = DateComponents()
        date.calendar = Calendar.current
        date.hour = hour
        date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
