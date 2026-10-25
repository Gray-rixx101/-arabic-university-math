import UserNotifications

/// تذكيرات محلية حقيقية مع زر «تم ✓» داخل الإشعار
enum Notifications {
    static let category = "HABIT_REMINDER"
    static let doneAction = "DONE"

    static func registerCategories() {
        let done = UNNotificationAction(identifier: doneAction, title: "تم ✓", options: [])
        let cat = UNNotificationCategory(identifier: category, actions: [done], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([cat])
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func reschedule(_ habits: [Habit]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        var count = 0
        for h in habits where !h.archived {
            for r in h.reminders {
                for wd in r.weekdays.sorted() {
                    // iOS يسمح بـ 64 إشعارًا مجدولًا كحد أقصى
                    guard count < 64 else { return }
                    let content = UNMutableNotificationContent()
                    content.title = "\(h.emoji) \(h.name)"
                    content.body = h.reminderBody
                    content.sound = .default
                    content.userInfo = ["habitID": h.id.uuidString]
                    if h.kind == .build { content.categoryIdentifier = category }
                    var dc = DateComponents()
                    dc.weekday = wd
                    dc.hour = r.hour
                    dc.minute = r.minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                    let req = UNNotificationRequest(identifier: "\(h.id.uuidString)-\(r.id.uuidString)-\(wd)", content: content, trigger: trigger)
                    center.add(req)
                    count += 1
                }
            }
        }
    }
}
