import WidgetKit
import SwiftUI
import AppIntents

@main
struct AtharWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitWidget()
        OverviewWidget()
        TodayWidget()
    }
}

// MARK: - ودجت عادة واحدة (خريطة + زر تسجيل)

struct HabitEntry: TimelineEntry {
    let date: Date
    let habit: Habit?
    let firstWeekday: Int
}

struct HabitProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habit: Habit.sample(), firstWeekday: 1)
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> HabitEntry {
        entry(for: configuration, preview: context.isPreview)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<HabitEntry> {
        Timeline(entries: [entry(for: configuration, preview: false)], policy: .after(Day.nextMidnight))
    }

    private func entry(for configuration: SelectHabitIntent, preview: Bool) -> HabitEntry {
        let data = AppData.load()
        let chosen = data.habits.first { $0.id.uuidString == configuration.habit?.id && !$0.archived }
        let habit = chosen ?? data.habits.first { !$0.archived } ?? (preview ? Habit.sample() : nil)
        return HabitEntry(date: Date(), habit: habit, firstWeekday: data.settings.firstWeekday)
    }
}

struct HabitWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "AtharHabit", intent: SelectHabitIntent.self, provider: HabitProvider()) { entry in
            HabitWidgetView(entry: entry)
                .environment(\.layoutDirection, .rightToLeft)
                .containerBackground(Theme.surface, for: .widget)
        }
        .configurationDisplayName("عادة")
        .description("خريطة عادتك مع زر تسجيل سريع.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WidgetCheck: View {
    let habit: Habit
    var size: CGFloat = 34

    var body: some View {
        let st = habit.status(on: Day.today)
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(st == .done ? habit.color : (st == .slip ? Theme.danger.opacity(0.18) : habit.color.opacity(0.18)))
            if habit.kind == .quit {
                Image(systemName: st == .slip ? "xmark.shield.fill" : (st == .done ? "checkmark.shield.fill" : "shield"))
                    .font(.system(size: size * 0.46))
                    .foregroundStyle(st == .done ? Color.black.opacity(0.8) : (st == .slip ? Theme.danger : habit.color))
            } else if st == .done {
                Image(systemName: "checkmark").font(.system(size: size * 0.44, weight: .bold)).foregroundStyle(.black.opacity(0.8))
            } else if habit.goal > 1 {
                ProgressRing(fraction: Double(habit.count(on: Day.today)) / Double(habit.goal), color: habit.color, lineWidth: 2.5)
                    .padding(size * 0.14)
                Text("\(habit.count(on: Day.today))").font(.system(size: size * 0.28, weight: .heavy)).foregroundStyle(habit.color)
            } else {
                Image(systemName: "checkmark").font(.system(size: size * 0.44, weight: .bold)).foregroundStyle(habit.color)
            }
        }
        .frame(width: size, height: size)
    }
}

struct HabitWidgetView: View {
    let entry: HabitEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let h = entry.habit {
            let st = h.stats(firstWeekday: entry.firstWeekday)
            VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 10) {
                HStack(spacing: 8) {
                    EmojiTile(emoji: h.emoji, color: h.color, size: family == .systemSmall ? 30 : 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(h.name).font(.system(size: family == .systemSmall ? 12 : 14, weight: .bold)).lineLimit(1)
                        if family != .systemSmall {
                            Text(h.subtitle(firstWeekday: entry.firstWeekday)).font(.system(size: 11)).foregroundStyle(Theme.muted).lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                    Button(intent: ToggleHabitIntent(habitID: h.id.uuidString)) {
                        WidgetCheck(habit: h, size: family == .systemSmall ? 30 : 36)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
                HeatmapView(
                    habit: h,
                    firstWeekday: entry.firstWeekday,
                    cellSize: family == .systemLarge ? 15 : (family == .systemSmall ? 9 : 9.5),
                    spacing: family == .systemSmall ? 2 : 2.5,
                    showMonths: family == .systemLarge
                )
                if family == .systemLarge {
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        miniStat(h.kind == .quit ? "\(h.cleanDays)" : "\(st.current)", h.kind == .quit ? "يوم بدون" : "السلسلة", h.color)
                        miniStat("\(st.best)", "الأفضل", h.color)
                        miniStat("\(st.rate)%", "الالتزام", h.color)
                    }
                }
            }
            .widgetURL(URL(string: "athar://habit/\(h.id.uuidString)"))
        } else {
            VStack(spacing: 6) {
                Text("🌱").font(.title)
                Text("افتح «أثر» وأضف عادتك الأولى").font(.caption).multilineTextAlignment(.center).foregroundStyle(Theme.muted)
            }
        }
    }

    private func miniStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .heavy)).foregroundStyle(color)
            Text(label).font(.system(size: 10)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - ودجت كل العادات (آخر أيام + أزرار)

struct OverviewEntry: TimelineEntry {
    let date: Date
    let habits: [Habit]
    let firstWeekday: Int
}

struct OverviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> OverviewEntry {
        OverviewEntry(date: Date(), habits: [Habit.sample(), Habit.sample(color: "#5ED0EA", density: 0.9), Habit.sample(color: "#A3E635", density: 0.6)], firstWeekday: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (OverviewEntry) -> Void) {
        let e = current()
        completion(e.habits.isEmpty && context.isPreview ? placeholder(in: context) : e)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OverviewEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .after(Day.nextMidnight)))
    }

    private func current() -> OverviewEntry {
        let data = AppData.load()
        return OverviewEntry(date: Date(), habits: data.habits.filter { !$0.archived }, firstWeekday: data.settings.firstWeekday)
    }
}

struct OverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AtharOverview", provider: OverviewProvider()) { entry in
            OverviewWidgetView(entry: entry)
                .environment(\.layoutDirection, .rightToLeft)
                .containerBackground(Theme.surface, for: .widget)
        }
        .configurationDisplayName("كل العادات")
        .description("آخر أيامك لكل العادات، وسجّل اليوم بلمسة.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct OverviewWidgetView: View {
    let entry: OverviewEntry
    @Environment(\.widgetFamily) private var family

    private var maxRows: Int { family == .systemLarge ? 7 : 3 }
    private var dayCount: Int { family == .systemLarge ? 7 : 8 }

    var body: some View {
        if entry.habits.isEmpty {
            Text("افتح «أثر» وأضف عادتك الأولى").font(.caption).foregroundStyle(Theme.muted)
        } else {
            let days: [Date] = (0..<dayCount).map { Day.add(-$0, Day.today) }.reversed()
            VStack(spacing: family == .systemLarge ? 9 : 7) {
                HStack(spacing: 4) {
                    Spacer().frame(width: 28)
                    ForEach(days, id: \.self) { d in
                        Text(Day.weekdaysLetter[Day.weekday(d) - 1])
                            .font(.system(size: 9, weight: d == Day.today ? .bold : .regular))
                            .foregroundStyle(d == Day.today ? Color.primary : Theme.muted)
                            .frame(maxWidth: .infinity)
                    }
                    Spacer().frame(width: 30)
                }
                ForEach(entry.habits.prefix(maxRows)) { h in
                    HStack(spacing: 4) {
                        Text(h.emoji).font(.system(size: 14))
                            .frame(width: 28, height: 24)
                            .background(h.color.opacity(0.18), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                        ForEach(days, id: \.self) { d in
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(cellColor(h, d))
                                .overlay {
                                    if d == Day.today {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(.white.opacity(0.7), lineWidth: 1.2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 24)
                        }
                        Button(intent: ToggleHabitIntent(habitID: h.id.uuidString)) {
                            WidgetCheck(habit: h, size: 26)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 30)
                    }
                    
                }
                if family == .systemLarge { Spacer(minLength: 0) }
            }
        }
    }

    private func cellColor(_ h: Habit, _ d: Date) -> Color {
        switch h.status(on: d) {
        case .done: return h.color
        case .partial(let f): return h.color.opacity(0.3 + 0.5 * f)
        case .slip: return Theme.danger.opacity(0.4)
        case .off: return h.color.opacity(0.06)
        case .beforeStart, .future: return Color.white.opacity(0.03)
        case .empty: return h.color.opacity(0.15)
        }
    }
}

// MARK: - ودجت شاشة القفل: تقدّم اليوم

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AtharToday", provider: OverviewProvider()) { entry in
            TodayWidgetView(entry: entry)
                .environment(\.layoutDirection, .rightToLeft)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("تقدّم اليوم")
        .description("كم عادة أنجزت اليوم.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct TodayWidgetView: View {
    let entry: OverviewEntry
    @Environment(\.widgetFamily) private var family

    private var due: [Habit] { entry.habits.filter { $0.kind == .quit || $0.isScheduled(Day.today) } }
    private var done: Int { due.filter { $0.isDone(Day.today) }.count }
    private var fraction: Double { due.isEmpty ? 0 : Double(done) / Double(due.count) }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: fraction) {
                Image(systemName: "checkmark")
            } currentValueLabel: {
                Text("\(done)/\(due.count)").font(.system(size: 12, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryInline:
            Text("أثر: \(done) من \(due.count) اليوم")
        default:
            VStack(alignment: .leading, spacing: 3) {
                Text("أثر · اليوم").font(.headline)
                Text("أنجزت \(done) من \(due.count)").font(.subheadline)
                Gauge(value: fraction) { EmptyView() }
                    .gaugeStyle(.accessoryLinearCapacity)
            }
        }
    }
}
