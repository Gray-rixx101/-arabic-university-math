import Foundation

enum DayStatus: Equatable {
    case future
    case beforeStart
    case off
    case empty
    case partial(Double)
    case done
    case slip
}

enum TapOutcome {
    case progressed, completed, reset, slipped, cleared
}

struct HabitStats {
    var current = 0
    var best = 0
    var rate = 0
    var doneDays = 0
    var sum = 0
    var periodIsWeek = false
}

extension Habit {
    func count(on d: Date) -> Int { log[Day.key(d)] ?? 0 }

    func isScheduled(_ d: Date) -> Bool {
        if case .weekdays(let set) = frequency { return set.contains(Day.weekday(d)) }
        return true
    }

    /// للعادات النافعة: أقدم يوم مسجَّل أو تاريخ البدء، أيهما أسبق
    var effectiveStart: Date {
        var s = Day.start(startDate)
        if kind == .build {
            for k in log.keys {
                if let d = Day.date(fromKey: k), d < s { s = d }
            }
        }
        return s
    }

    func status(on date: Date, today: Date = Day.today) -> DayStatus {
        let d = Day.start(date)
        if d > today { return .future }
        let c = log[Day.key(d)] ?? 0
        if kind == .quit {
            if d < Day.start(startDate) { return .beforeStart }
            return c > 0 ? .slip : .done
        }
        if c >= goal { return .done }
        if c > 0 { return .partial(Double(c) / Double(goal)) }
        if !isScheduled(d) { return .off }
        return .empty
    }

    func isDone(_ d: Date, today: Date = Day.today) -> Bool { status(on: d, today: today) == .done }

    /// يُرجع ما حدث بعد الضغط على يوم معيّن
    mutating func tap(on date: Date) -> TapOutcome {
        let k = Day.key(date)
        if kind == .quit {
            if (log[k] ?? 0) > 0 {
                log[k] = nil
                return .cleared
            }
            log[k] = 1
            return .slipped
        }
        let c = log[k] ?? 0
        let n = c >= goal ? 0 : c + 1
        log[k] = n == 0 ? nil : n
        if n == 0 { return .reset }
        return n >= goal ? .completed : .progressed
    }

    /// عدد الأيام منذ آخر زلّة
    var cleanDays: Int {
        guard kind == .quit else { return 0 }
        var n = 0
        var d = Day.today
        let s = Day.start(startDate)
        while d >= s && (log[Day.key(d)] ?? 0) == 0 {
            n += 1
            d = Day.add(-1, d)
        }
        return n
    }

    func doneThisWeek(firstWeekday: Int) -> Int {
        let ws = Day.startOfWeek(Day.today, first: firstWeekday)
        return (0..<7).filter { i in
            let d = Day.add(i, ws)
            return d <= Day.today && isDone(d)
        }.count
    }

    var weeklyTarget: Int? {
        if case .weekly(let n) = frequency { return n }
        return nil
    }

    var frequencyLabel: String {
        if kind == .quit { return "إقلاع" }
        let per = goal > 1 ? "\(goal) \(unit.isEmpty ? "مرات" : unit)" : ""
        switch frequency {
        case .daily:
            return per.isEmpty ? "يوميًا" : "\(per) يوميًا"
        case .weekdays(let set):
            let names = Day.orderedWeekdays(first: 7).filter { set.contains($0) }.map { Day.weekdaysShort[$0 - 1] }
            return (per.isEmpty ? "" : "\(per) · ") + names.joined(separator: "، ")
        case .weekly(let n):
            return (per.isEmpty ? "" : "\(per) · ") + "\(n) مرات أسبوعيًا"
        }
    }

    func subtitle(firstWeekday: Int) -> String {
        if kind == .quit {
            let n = cleanDays
            return "\(n) \(n == 1 ? "يوم" : "يومًا") بدون" + (detail.isEmpty ? "" : " · \(detail)")
        }
        if let target = weeklyTarget {
            return "\(doneThisWeek(firstWeekday: firstWeekday))/\(target) هذا الأسبوع" + (detail.isEmpty ? "" : " · \(detail)")
        }
        return detail.isEmpty ? frequencyLabel : detail
    }

    var reminderBody: String {
        for s in [plan.cue, plan.stack, plan.twoMinute, plan.replacement, detail] where !s.isEmpty { return s }
        return "حان وقت عادتك. ابدأ صغيرًا."
    }

    // MARK: - الإحصاءات

    func stats(year: Int? = nil, firstWeekday: Int) -> HabitStats {
        let today = Day.today
        let start = effectiveStart
        var s = HabitStats()
        guard start <= today else { return s }
        func inYear(_ d: Date) -> Bool { year == nil || Day.year(d) == year }

        // عادة أسبوعية: السلسلة بالأسابيع
        if kind == .build, let target = weeklyTarget {
            s.periodIsWeek = true
            var ws = Day.startOfWeek(start, first: firstWeekday)
            let current = Day.startOfWeek(today, first: firstWeekday)
            var run = 0, met = 0, weeks = 0
            while ws <= current {
                var n = 0
                for i in 0..<7 {
                    let d = Day.add(i, ws)
                    if d > today { break }
                    if isDone(d, today: today) {
                        n += 1
                        if inYear(d) {
                            s.doneDays += 1
                            s.sum += count(on: d)
                        }
                    }
                }
                let ok = n >= target
                let isCurrent = ws == current
                if ok { run += 1 } else if !isCurrent { run = 0 }
                if inYear(ws) {
                    if ok {
                        met += 1
                        weeks += 1
                    } else if !isCurrent {
                        weeks += 1
                    }
                    s.best = max(s.best, run)
                }
                ws = Day.add(7, ws)
            }
            s.current = run
            s.rate = weeks > 0 ? Int((Double(met) / Double(weeks) * 100).rounded()) : 0
            return s
        }

        var run = 0, total = 0
        var d = start
        while d <= today {
            let isToday = d == today
            let st = status(on: d, today: today)
            if st == .off {
                d = Day.add(1, d)
                continue
            }
            let done = st == .done
            // لا نكسر السلسلة بسبب اليوم الحالي قبل أن ينتهي
            if done { run += 1 } else if !(isToday && kind == .build) { run = 0 }
            if inYear(d) {
                if done {
                    s.doneDays += 1
                    total += 1
                } else if !isToday || kind == .quit {
                    total += 1
                }
                if kind == .build { s.sum += count(on: d) }
                s.best = max(s.best, run)
            }
            d = Day.add(1, d)
        }
        s.current = run
        s.rate = total > 0 ? Int((Double(s.doneDays) / Double(total) * 100).rounded()) : 0
        return s
    }

    /// عادة تجريبية للعرض في المقدمة والودجت
    static func sample(color: String = "#A78BFA", density: Double = 0.78, kind: HabitKind = .build) -> Habit {
        var h = Habit(name: kind == .quit ? "ترك التدخين" : "قراءة 20 صفحة", emoji: kind == .quit ? "🚭" : "📖", colorHex: color, kind: kind)
        h.startDate = Day.add(-200, Day.today)
        var seed: UInt64 = 7
        for i in 1..<200 {
            seed = (seed &* 9301 &+ 49297) % 233280
            let r = Double(seed) / 233280
            let key = Day.key(Day.add(-i, Day.today))
            if kind == .quit {
                if r > density { h.log[key] = 1 }
            } else if r < density {
                h.log[key] = 1
            }
        }
        return h
    }
}
