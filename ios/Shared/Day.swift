import Foundation

/// أدوات التاريخ. نستخدم التقويم الميلادي دائمًا حتى لو كان الجهاز على التقويم الهجري،
/// لأن مفاتيح السجل بصيغة yyyy-MM-dd.
enum Day {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        return c
    }()

    static let months = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"]
    /// مفهرسة بـ weekday - 1 (الأحد = 1)
    static let weekdays = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
    static let weekdaysShort = ["أحد", "اثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت"]
    static let weekdaysLetter = ["ح", "ن", "ث", "ر", "خ", "ج", "س"]

    static var today: Date { calendar.startOfDay(for: Date()) }

    static func start(_ d: Date) -> Date { calendar.startOfDay(for: d) }

    static func key(_ d: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(fromKey k: String) -> Date? {
        let p = k.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))
    }

    static func add(_ n: Int, _ d: Date) -> Date {
        calendar.date(byAdding: .day, value: n, to: d) ?? d
    }

    static func weekday(_ d: Date) -> Int { calendar.component(.weekday, from: d) }
    static func year(_ d: Date) -> Int { calendar.component(.year, from: d) }
    static func month(_ d: Date) -> Int { calendar.component(.month, from: d) }
    static func dayOfMonth(_ d: Date) -> Int { calendar.component(.day, from: d) }

    static func startOfWeek(_ d: Date, first: Int) -> Date {
        let diff = (weekday(d) - first + 7) % 7
        return add(-diff, start(d))
    }

    static func startOfMonth(_ d: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: d)) ?? start(d)
    }

    static func addMonths(_ n: Int, _ d: Date) -> Date {
        calendar.date(byAdding: .month, value: n, to: d) ?? d
    }

    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        calendar.dateComponents([.day], from: start(a), to: start(b)).day ?? 0
    }

    /// أيام الأسبوع مرتبة ابتداءً من أول يوم يختاره المستخدم
    static func orderedWeekdays(first: Int) -> [Int] {
        (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    static func long(_ d: Date) -> String {
        "\(weekdays[weekday(d) - 1])، \(dayOfMonth(d)) \(months[month(d) - 1]) \(year(d))"
    }

    static func monthYear(_ d: Date) -> String {
        "\(months[month(d) - 1]) \(year(d))"
    }

    static func time(hour: Int, minute: Int) -> String {
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d", h12, minute) + (hour < 12 ? " ص" : " م")
    }

    static var nextMidnight: Date { add(1, today) }
}
