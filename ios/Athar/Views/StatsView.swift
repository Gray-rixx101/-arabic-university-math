import SwiftUI
import Charts

struct StatsView: View {
    @Environment(HabitStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selected: UUID?
    @State private var year = Day.year(Day.today)

    private var fw: Int { store.settings.firstWeekday }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if store.active.isEmpty {
                        ContentUnavailableView("لا توجد إحصاءات بعد", systemImage: "chart.bar", description: Text("أضف عادة وسجّلها لترى تقدمك هنا."))
                    } else {
                        chips
                        yearNav
                        if let id = selected, let h = store.habit(id) {
                            habitStats(h)
                        } else {
                            overallStats
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("الإحصاءات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("الكل", color: Theme.accent, on: selected == nil) { selected = nil }
                ForEach(store.active) { h in
                    chip("\(h.emoji) \(h.name)", color: h.color, on: selected == h.id) { selected = h.id }
                }
            }
        }
    }

    private func chip(_ title: String, color: Color, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.footnote.weight(.semibold))
                .padding(.horizontal, 12).frame(height: 36)
                .background(on ? color.opacity(0.2) : Theme.surface2, in: Capsule())
                .overlay(Capsule().stroke(on ? color : Theme.line))
        }
        .buttonStyle(.plain)
    }

    private var yearNav: some View {
        HStack {
            Button { year -= 1 } label: { Image(systemName: "chevron.backward").frame(width: 34, height: 34).background(Theme.surface2, in: Circle()) }
            Spacer()
            Text(verbatim: "\(year)").font(.headline.weight(.heavy))
            Spacer()
            Button { if year < Day.year(Day.today) { year += 1 } } label: {
                Image(systemName: "chevron.forward").frame(width: 34, height: 34).background(Theme.surface2, in: Circle())
            }
            .opacity(year < Day.year(Day.today) ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .padding(6)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line))
    }

    private var yearEnd: Date {
        year >= Day.year(Day.today) ? Day.today : (Day.calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? Day.today)
    }

    private var yearStart: Date {
        Day.calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Day.today
    }

    private var yearWeeks: Int {
        (Day.daysBetween(yearStart, yearEnd) + 7) / 7 + 1
    }

    private func daysOfYear() -> [Date] {
        var out: [Date] = []
        var d = yearStart
        while d <= yearEnd {
            out.append(d)
            d = Day.add(1, d)
        }
        return out
    }

    private func habitStats(_ h: Habit) -> some View {
        let st = h.stats(year: year, firstWeekday: fw)
        var months = Array(repeating: 0, count: 12)
        for d in daysOfYear() where h.isDone(d) { months[Day.month(d) - 1] += 1 }
        let usesSum = h.kind == .build && h.goal > 1
        return VStack(spacing: 10) {
            Panel {
                HStack(spacing: 12) {
                    EmojiTile(emoji: h.emoji, color: h.color, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(h.name).font(.headline)
                        Text(h.detail.isEmpty ? h.frequencyLabel : h.detail).font(.caption).foregroundStyle(Theme.muted)
                    }
                }
                HeatmapView(habit: h, firstWeekday: fw, cellSize: 5, spacing: 2, end: yearEnd, showMonths: true, fixedWeeks: yearWeeks)
            }
            HStack(spacing: 10) {
                StatTile(systemImage: "number", value: "\(usesSum ? st.sum : st.doneDays)", unit: usesSum ? (h.unit.isEmpty ? "مرة" : h.unit) : "يوم",
                         label: h.kind == .quit ? "أيام نظيفة" : "إتمامات", color: h.color)
                StatTile(systemImage: "percent", value: "\(st.rate)", unit: "%", label: st.periodIsWeek ? "أسابيع مكتملة" : "معدل الإنجاز", color: h.color)
            }
            Panel {
                PanelTitle(title: h.kind == .quit ? "أيام نظيفة / شهر" : "الإنجازات / شهر", systemImage: "chart.xyaxis.line", color: h.color)
                MonthlyChart(values: months, color: h.color, year: year)
            }
            HStack(spacing: 10) {
                StatTile(systemImage: h.kind == .quit ? "checkmark.shield" : "flame",
                         value: "\(h.kind == .quit ? h.cleanDays : st.current)", unit: st.periodIsWeek ? "أسبوع" : "يوم", label: "السلسلة الحالية", color: h.color)
                StatTile(systemImage: "star", value: "\(st.best)", unit: st.periodIsWeek ? "أسبوع" : "يوم", label: "أفضل سلسلة", color: h.color)
            }
        }
    }

    private var overallStats: some View {
        let habits = store.active
        let starts = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0.effectiveStart) })
        let fraction: (Date) -> Double = { d in
            var act = 0, done = 0
            for h in habits where d >= (starts[h.id] ?? d) && h.isScheduled(d) {
                act += 1
                if h.isDone(d) { done += 1 }
            }
            return act > 0 ? Double(done) / Double(act) : 0
        }
        var months = Array(repeating: 0, count: 12)
        var totalDone = 0, possible = 0
        for d in daysOfYear() {
            for h in habits where d >= (starts[h.id] ?? d) && h.isScheduled(d) {
                let done = h.isDone(d)
                if done {
                    totalDone += 1
                    months[Day.month(d) - 1] += 1
                }
                if done || d != Day.today { possible += 1 }
            }
        }
        let todayDone = habits.filter { $0.isDone(Day.today) }.count
        let ranked = habits.map { ($0, $0.stats(year: year, firstWeekday: fw)) }.sorted { $0.1.rate > $1.1.rate }
        let best = ranked.map { $0.1.best }.max() ?? 0

        return VStack(spacing: 10) {
            Panel {
                HeatmapView(habit: nil, firstWeekday: fw, cellSize: 5, spacing: 2, end: yearEnd, showMonths: true,
                            fixedWeeks: yearWeeks, tint: Theme.accent, aggregate: fraction)
            }
            HStack(spacing: 10) {
                StatTile(systemImage: "checkmark", value: "\(todayDone)/\(habits.count)", label: "إنجاز اليوم")
                StatTile(systemImage: "percent", value: "\(possible > 0 ? Int((Double(totalDone) / Double(possible) * 100).rounded()) : 0)", unit: "%", label: "معدل الإنجاز")
            }
            Panel {
                PanelTitle(title: "الإنجازات / شهر", systemImage: "chart.xyaxis.line")
                MonthlyChart(values: months, color: Theme.accent, year: year)
            }
            HStack(spacing: 10) {
                StatTile(systemImage: "number", value: "\(totalDone)", label: "إجمالي الإتمامات")
                StatTile(systemImage: "star", value: "\(best)", unit: "يوم", label: "أطول سلسلة")
            }
            VStack(spacing: 0) {
                ForEach(ranked.indices, id: \.self) { i in
                    let h = ranked[i].0
                    let s = ranked[i].1
                    Button { selected = h.id } label: {
                        HStack(spacing: 12) {
                            EmojiTile(emoji: h.emoji, color: h.color, size: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(h.name).font(.subheadline)
                                Text(h.kind == .quit ? "\(h.cleanDays) يوم بدون" : "السلسلة \(s.current) · الأفضل \(s.best)")
                                    .font(.caption).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Text("\(s.rate)%").font(.subheadline.bold()).foregroundStyle(h.color).monospacedDigit()
                        }
                        .padding(12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if i < ranked.count - 1 { Divider().overlay(Theme.line) }
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.line))
        }
    }
}

struct MonthlyChart: View {
    let values: [Int]
    let color: Color
    let year: Int

    private var lastMonth: Int {
        year == Day.year(Day.today) ? Day.month(Day.today) - 1 : 11
    }

    var body: some View {
        Chart {
            ForEach(0...lastMonth, id: \.self) { i in
                AreaMark(x: .value("الشهر", i), y: .value("العدد", values[i]))
                    .foregroundStyle(LinearGradient(colors: [color.opacity(0.45), color.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("الشهر", i), y: .value("العدد", values[i]))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2.2))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("الشهر", i), y: .value("العدد", values[i]))
                    .foregroundStyle(color)
                    .symbolSize(20)
            }
        }
        .chartXScale(domain: 0...11)
        .chartXAxis {
            AxisMarks(values: [0, 2, 4, 6, 8, 10]) { v in
                AxisGridLine().foregroundStyle(Theme.line)
                AxisValueLabel {
                    if let i = v.as(Int.self) { Text(Day.months[i]).font(.system(size: 9)) }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Theme.line)
                AxisValueLabel().font(.system(size: 9))
            }
        }
        .frame(height: 160)
    }
}
