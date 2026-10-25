import SwiftUI

struct HabitDetailView: View {
    let habitID: UUID
    @Environment(HabitStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var month = Day.startOfMonth(Day.today)
    @State private var editing = false
    @State private var noteTarget: NoteTarget?
    @State private var confirmDelete = false
    @State private var confirmArchive = false

    var body: some View {
        Group {
            if let h = store.habit(habitID) {
                content(h)
            } else {
                ContentUnavailableView("العادة غير موجودة", systemImage: "questionmark.circle")
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = true } label: { Image(systemName: "pencil") }
            }
        }
        .sheet(isPresented: $editing) {
            if let h = store.habit(habitID) { HabitEditorView(habit: h) }
        }
        .sheet(item: $noteTarget) { NoteEditor(target: $0) }
    }

    private func content(_ h: Habit) -> some View {
        let fw = store.settings.firstWeekday
        let st = h.stats(firstWeekday: fw)
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    EmojiTile(emoji: h.emoji, color: h.color, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(h.name).font(.system(size: 22, weight: .heavy))
                        Text(h.detail.isEmpty ? h.frequencyLabel : h.detail)
                            .font(.footnote).foregroundStyle(Theme.muted)
                    }
                    Spacer(minLength: 0)
                    CheckButton(habit: h)
                }
                .padding(.top, 4)

                if !h.plan.identity.isEmpty {
                    Text("🪪 \(h.plan.identity)")
                        .font(.footnote.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(h.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Panel {
                    HeatmapView(habit: h, firstWeekday: fw, cellSize: 11, spacing: 3, showMonths: true)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if h.kind == .quit {
                            Pill(systemImage: "checkmark.shield", text: "\(h.cleanDays) يوم بدون", color: h.color)
                        } else if let target = h.weeklyTarget {
                            Pill(systemImage: "flame", text: "\(st.current) أسبوع", color: h.color)
                            Pill(systemImage: "calendar", text: "\(h.doneThisWeek(firstWeekday: fw))/\(target) هذا الأسبوع", color: h.color)
                        } else {
                            Pill(systemImage: "flame", text: "\(st.current)", color: h.color)
                            Pill(systemImage: "target", text: h.frequencyLabel, color: h.color)
                        }
                        Pill(systemImage: "star", text: "أفضل: \(st.best)", color: h.color)
                        Pill(systemImage: "percent", text: "\(st.rate)%", color: h.color)
                    }
                }

                MonthCalendarView(habit: h, month: $month) { d in
                    noteTarget = NoteTarget(habitID: h.id, date: d)
                }

                notesPanel(h)
                planPanel(h)

                HStack(spacing: 10) {
                    Button { confirmArchive = true } label: {
                        Label("أرشفة", systemImage: "archivebox").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButtonStyle(color: Theme.surface2))
                    Button { confirmDelete = true } label: {
                        Label("حذف", systemImage: "trash").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButtonStyle(color: Theme.danger.opacity(0.14), foreground: Theme.danger))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .confirmationDialog("أرشفة العادة؟", isPresented: $confirmArchive, titleVisibility: .visible) {
            Button("أرشفة") {
                dismiss()
                store.setArchived(h.id, true)
                store.show("🗂️", "تمت الأرشفة. يمكنك استعادتها من الإعدادات.")
            }
        } message: {
            Text("ستختفي من الشاشة الرئيسية مع الاحتفاظ بكل سجلها.")
        }
        .confirmationDialog("حذف العادة نهائيًا؟", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("حذف", role: .destructive) {
                dismiss()
                store.delete(h.id)
            }
        } message: {
            Text("سيُحذف كل سجلها وملاحظاتها ولا يمكن التراجع.")
        }
    }

    private func notesPanel(_ h: Habit) -> some View {
        let notes = h.notes.sorted { $0.key > $1.key }
        let todayKey = Day.key(Day.today)
        return Panel {
            HStack {
                PanelTitle(title: "ملاحظات", systemImage: "note.text", color: h.color)
                Spacer()
                Button { noteTarget = NoteTarget(habitID: h.id, date: Day.today) } label: {
                    Image(systemName: "plus").font(.footnote.bold())
                        .frame(width: 32, height: 32)
                        .background(Theme.surface2, in: Circle())
                }
                .buttonStyle(.plain)
            }
            if notes.isEmpty {
                Text("لا توجد ملاحظات بعد. ما الذي سار جيدًا؟ وما الذي اعترض طريقك؟")
                    .font(.footnote).foregroundStyle(Theme.muted)
            } else {
                ForEach(notes, id: \.key) { item in
                    let k = item.key
                    let v = item.value
                    Button {
                        if let d = Day.date(fromKey: k) { noteTarget = NoteTarget(habitID: h.id, date: d) }
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                Circle().fill(h.color).frame(width: 6, height: 6)
                                Text(k == todayKey ? "اليوم" : (Day.date(fromKey: k).map(Day.long) ?? k))
                                    .font(.caption2).foregroundStyle(Theme.muted)
                            }
                            Text(v).font(.subheadline).multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(k == todayKey ? h.color : .clear))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func planPanel(_ h: Habit) -> some View {
        let items: [(String, String)] = Atomic.laws(for: h.kind).flatMap { law in
            law.fields.compactMap { f in
                let v = h.plan[keyPath: f.key]
                return v.isEmpty ? nil : ("\(law.title) · \(f.label)", v)
            }
        }
        return Panel {
            PanelTitle(title: h.kind == .quit ? "خطة الإقلاع" : "خطة العادة الذرية", systemImage: "atom", color: h.color)
            if items.isEmpty {
                Text("لم تكتب خطتك بعد. العادات التي لها «متى وأين» واضحان تنجح أكثر بكثير.")
                    .font(.footnote).foregroundStyle(Theme.muted)
            } else {
                ForEach(items.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(items[i].0).font(.caption).foregroundStyle(Theme.muted)
                        Text(items[i].1).font(.subheadline)
                    }
                    if i < items.count - 1 { Divider().overlay(Theme.line) }
                }
            }
            Button { editing = true } label: {
                Label(items.isEmpty ? "اكتب خطتك" : "تعديل الخطة", systemImage: "pencil")
                    .font(.footnote.bold())
                    .padding(.horizontal, 14).frame(height: 36)
                    .background(Theme.surface2, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

struct MonthCalendarView: View {
    let habit: Habit
    @Binding var month: Date
    var onNote: (Date) -> Void
    @Environment(HabitStore.self) private var store

    var body: some View {
        let fw = store.settings.firstWeekday
        let first = Day.startOfMonth(month)
        let offset = (Day.weekday(first) - fw + 7) % 7
        let gridStart = Day.add(-offset, first)
        let daysInMonth = Day.calendar.range(of: .day, in: .month, for: first)?.count ?? 30
        let count = Int((Double(offset + daysInMonth) / 7).rounded(.up)) * 7
        let thisMonth = Day.month(first)
        let canGoNext = Day.addMonths(1, first) <= Day.today

        Panel {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Day.orderedWeekdays(first: fw), id: \.self) { wd in
                    Text(Day.weekdaysShort[wd - 1]).font(.caption2).foregroundStyle(Theme.muted)
                }
                ForEach(0..<count, id: \.self) { i in
                    let d = Day.add(i, gridStart)
                    CalendarDayCell(habit: habit, date: d, inMonth: Day.month(d) == thisMonth)
                        .contextMenu {
                            if d <= Day.today {
                                Button { onNote(d) } label: { Label("ملاحظة", systemImage: "note.text") }
                            }
                        }
                }
            }
            HStack(spacing: 8) {
                Label(Day.monthYear(first), systemImage: "calendar")
                    .font(.subheadline.bold())
                Spacer()
                Button { month = Day.addMonths(-1, first) } label: {
                    Image(systemName: "chevron.backward").frame(width: 34, height: 34).background(Theme.surface2, in: Circle())
                }
                Button { if canGoNext { month = Day.addMonths(1, first) } } label: {
                    Image(systemName: "chevron.forward").frame(width: 34, height: 34).background(Theme.surface2, in: Circle())
                }
                .opacity(canGoNext ? 1 : 0.35)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Text(habit.kind == .quit ? "اضغط على يوم لتسجيل زلّة أو إلغائها · اضغط مطولًا لملاحظة" : "اضغط على يوم لتسجيله · اضغط مطولًا لإضافة ملاحظة")
                .font(.caption2).foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
        }
    }
}

struct CalendarDayCell: View {
    let habit: Habit
    let date: Date
    let inMonth: Bool
    @Environment(HabitStore.self) private var store

    var body: some View {
        let st = habit.status(on: date)
        let hasNote = habit.notes[Day.key(date)] != nil
        Button {
            store.tap(habit.id, on: date)
        } label: {
            VStack(spacing: 3) {
                Text("\(Day.dayOfMonth(date))")
                    .font(.system(size: 14, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(st == .slip ? Color(hex: "#FCA5A5") : (inMonth ? Color.primary : Theme.muted))
                Circle()
                    .fill(st == .slip ? Theme.danger : habit.color)
                    .frame(width: 4, height: 4)
                    .opacity(dotVisible(st) ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(background(st), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if date == Day.today {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.7), lineWidth: 1.5)
                }
            }
            .overlay(alignment: .topLeading) {
                if hasNote {
                    Circle().fill(.white.opacity(0.7)).frame(width: 5, height: 5).padding(6)
                }
            }
            .opacity(st == .future ? 0.3 : (inMonth ? 1 : 0.4))
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .disabled(st == .future || st == .beforeStart)
        .sensoryFeedback(.impact(weight: .light), trigger: habit.count(on: date))
    }

    private func dotVisible(_ st: DayStatus) -> Bool {
        switch st {
        case .done, .slip, .partial: return true
        default: return false
        }
    }

    private func background(_ st: DayStatus) -> Color {
        switch st {
        case .done: return habit.color.opacity(0.26)
        case .partial: return habit.color.opacity(0.12)
        case .slip: return Theme.danger.opacity(0.16)
        default: return .clear
        }
    }
}
