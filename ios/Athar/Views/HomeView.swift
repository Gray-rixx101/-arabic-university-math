import SwiftUI

struct HomeView: View {
    @Environment(HabitStore.self) private var store
    @State private var path: [UUID] = []
    @State private var editorKind: HabitKind?
    @State private var showStats = false
    @State private var showSettings = false
    @State private var noteTarget: NoteTarget?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    if store.active.isEmpty {
                        emptyState
                    } else {
                        if store.settings.showQuote { quoteBanner }
                        switch store.settings.viewMode {
                        case .cards:
                            ForEach(store.active) { h in
                                HabitCard(habit: h).onTapGesture { path.append(h.id) }
                            }
                        case .compact:
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                ForEach(store.active) { h in
                                    HabitCard(habit: h, compact: true).onTapGesture { path.append(h.id) }
                                }
                            }
                        case .list:
                            ListModeView(habits: store.active, onOpen: { path.append($0) }, onNote: { noteTarget = $0 })
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
            .scrollIndicators(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) {
                if !store.active.isEmpty { ViewSwitcher().padding(.bottom, 8) }
            }
            .navigationDestination(for: UUID.self) { id in
                HabitDetailView(habitID: id)
            }
        }
        .overlay(alignment: .top) { ToastView() }
        .sheet(item: $editorKind) { kind in HabitEditorView(habit: nil, kind: kind) }
        .sheet(isPresented: $showStats) { StatsView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(item: $noteTarget) { NoteEditor(target: $0) }
        .onOpenURL { url in
            // athar://habit/<id> من الودجت
            if url.host == "habit", let id = UUID(uuidString: url.lastPathComponent), store.habit(id) != nil {
                path = [id]
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            CircleIconButton(systemImage: "gearshape") { showSettings = true }
            VStack(alignment: .leading, spacing: 2) {
                Text("أثر").font(.system(size: 26, weight: .black))
                Text(Day.long(Day.today)).font(.caption).foregroundStyle(Theme.muted)
            }
            Spacer()
            CircleIconButton(systemImage: "chart.bar.xaxis") { showStats = true }
            CircleIconButton(systemImage: "plus", primary: true) { editorKind = .build }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var quoteBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("⚛️").font(.title3)
            Text(Atomic.quoteOfTheDay).font(.footnote).lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                withAnimation { store.updateSettings { $0.showQuote = false } }
            } label: {
                Image(systemName: "xmark").font(.caption.bold()).foregroundStyle(Theme.muted)
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color(hex: "#1F1A3A"), Theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(hex: "#2D2650")))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("🌱").font(.system(size: 56))
            Text("ابدأ بعادة واحدة صغيرة").font(.title2.bold())
            Text("العادات الصغيرة تتراكم مثل الفائدة المركبة. أضف عادة تريد بناءها، أو عادة ضارة تريد التخلص منها.")
                .font(.subheadline).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            HStack(spacing: 10) {
                Button { editorKind = .build } label: {
                    Label("عادة أبنيها", systemImage: "plus").frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButtonStyle())
                Button { editorKind = .quit } label: {
                    Label("عادة أتركها", systemImage: "shield").frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButtonStyle(color: Theme.surface2))
            }
            .frame(maxWidth: 380)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

extension HabitKind: Identifiable {
    var id: String { rawValue }
}

struct FilledButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 18)
            .frame(minHeight: 50)
            .background(color, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(color == Theme.accent ? 0 : 0.08)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ViewSwitcher: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        HStack(spacing: 4) {
            item(.list, "list.bullet")
            item(.cards, "rectangle.grid.1x2")
            item(.compact, "square.grid.2x2")
        }
        .padding(5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.08)))
        .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
    }

    private func item(_ mode: ViewMode, _ icon: String) -> some View {
        let on = store.settings.viewMode == mode
        return Button {
            withAnimation(.snappy) { store.updateSettings { $0.viewMode = mode } }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(on ? Color.primary : Theme.muted)
                .frame(width: 54, height: 40)
                .background(on ? Color.white.opacity(0.12) : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: on)
    }
}

struct HabitCard: View {
    let habit: Habit
    var compact = false
    @Environment(HabitStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 12) {
            HStack(spacing: compact ? 8 : 12) {
                EmojiTile(emoji: habit.emoji, color: habit.color, size: compact ? 32 : 42)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .font(.system(size: compact ? 14 : 16, weight: .bold))
                            .lineLimit(1)
                        if habit.kind == .quit && !compact {
                            Text("إقلاع")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: "#FCA5A5"))
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Theme.danger.opacity(0.14), in: Capsule())
                        }
                    }
                    if !compact {
                        Text(habit.subtitle(firstWeekday: store.settings.firstWeekday))
                            .font(.caption).foregroundStyle(Theme.muted).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                CheckButton(habit: habit, size: compact ? 36 : 46)
            }
            HeatmapView(
                habit: habit,
                firstWeekday: store.settings.firstWeekday,
                cellSize: compact ? 7.5 : 10.5,
                spacing: compact ? 2 : 3
            )
        }
        .padding(compact ? 12 : 14)
        .background {
            ZStack {
                Theme.surface
                LinearGradient(colors: [habit.color.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.line))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// عرض آخر عدة أيام لكل العادات في جدول واحد
struct ListModeView: View {
    let habits: [Habit]
    var onOpen: (UUID) -> Void
    var onNote: (NoteTarget) -> Void
    @Environment(HabitStore.self) private var store

    private var days: [Date] {
        (0..<store.settings.listDays).map { Day.add(-$0, Day.today) }.reversed()
    }

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text("\(habits.count) عادة").font(.caption).foregroundStyle(Theme.muted)
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(days, id: \.self) { d in
                            VStack(spacing: 1) {
                                Text(Day.weekdaysLetter[Day.weekday(d) - 1]).font(.system(size: 11))
                                Text("\(Day.dayOfMonth(d))").font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(d == Day.today ? Color.primary : Theme.muted)
                            .frame(width: 36)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)

                ForEach(habits) { h in
                    Divider().overlay(Theme.line)
                    HStack(spacing: 10) {
                        Button { onOpen(h.id) } label: {
                            HStack(spacing: 10) {
                                EmojiTile(emoji: h.emoji, color: h.color, size: 32)
                                Text(h.name).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer(minLength: 0)
                        HStack(spacing: 6) {
                            ForEach(days, id: \.self) { d in
                                DayCell(habit: h, date: d)
                                    .contextMenu {
                                        Button { onNote(NoteTarget(habitID: h.id, date: d)) } label: {
                                            Label("ملاحظة", systemImage: "note.text")
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.line))

            Text("اضغط مطولًا على أي يوم لإضافة ملاحظة")
                .font(.caption2).foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
        }
    }
}

struct DayCell: View {
    let habit: Habit
    let date: Date
    var size: CGFloat = 36
    @Environment(HabitStore.self) private var store

    var body: some View {
        let st = habit.status(on: date)
        Button {
            store.tap(habit.id, on: date)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous).fill(fill(st))
                switch st {
                case .partial(let f):
                    ProgressRing(fraction: f, color: habit.color, lineWidth: 3).padding(6)
                case .slip:
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.danger)
                default:
                    EmptyView()
                }
                if date == Day.today {
                    RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(.white.opacity(0.75), lineWidth: 1.5)
                }
            }
            .frame(width: size, height: size)
            .opacity(st == .beforeStart || st == .future ? 0.25 : 1)
        }
        .buttonStyle(PressableStyle(scale: 0.86))
        .disabled(st == .beforeStart || st == .future)
        .sensoryFeedback(.impact(weight: .light), trigger: habit.count(on: date))
    }

    private func fill(_ st: DayStatus) -> Color {
        switch st {
        case .done: return habit.color
        case .slip: return Theme.danger.opacity(0.2)
        case .off: return habit.color.opacity(0.07)
        default: return habit.color.opacity(0.18)
        }
    }
}
