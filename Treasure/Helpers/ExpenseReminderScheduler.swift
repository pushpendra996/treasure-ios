import Foundation
import UserNotifications

/// Local daily reminders at 10:00 and 20:00 to log expenses.
enum ExpenseReminderScheduler {
    static let morningId = "treasure.expense.reminder.morning"
    static let eveningId = "treasure.expense.reminder.evening"

    static func requestAndSchedule() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            schedule(center: center)
        }
    }

    static func schedule(center: UNUserNotificationCenter = .current()) {
        center.removePendingNotificationRequests(withIdentifiers: [morningId, eveningId])
        addDailyReminder(
            id: morningId,
            hour: 10,
            minute: 0,
            title: "Log today's expenses",
            body: "Add what you spent so your month-end report is complete — and you can spot spending that isn't worth it.",
            center: center
        )
        addDailyReminder(
            id: eveningId,
            hour: 20,
            minute: 0,
            title: "Did you log today's expenses?",
            body: "A quick log tonight gives you a clear picture at month-end. Tap to add your expenses.",
            center: center
        )
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
