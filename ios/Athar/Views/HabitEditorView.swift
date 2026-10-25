import SwiftUI

private enum FreqMode: String, CaseIterable, Identifiable {
    case daily, weekdays, weekly
    var id: String { rawValue }
    var title: String {
        switch self {
        case .daily: return "يوميًا"
        case .weekdays: return "أيام محددة"
        case .weekly: return "عدد مرات أسبوعيًا"
        }
    }
}

struct HabitEditorView: View {
    @Environment(HabitStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Habit
    @State private var freqMode: FreqMode
    @State private var weekdays: Set<Int>
    @State private var weeklyTarget: Int
    private let isNew: Bool

    init(habit: Habit?, kind: HabitKind = .build) {
        var h = habit ?? Habit(name: "", kind: kind)
        if habit == nil {
            h.colorHex = kind == .quit ? "#F07178" : Theme.palette[Int.random(in: 0..<Theme.palette.count)]
            h.emoji = kind == .quit ? "🚫" : "🎯"
        }
        _draft = State(initialValue: h)
        isNew = habit == nil
        switch h.frequency {
        case .daily:
            _freqMode = State(initialValue: .daily)
            _weekdays = State(initialValue: [1, 2, 3, 4, 5])
            _weeklyTarget = State(initialValue: 3)
        case .weekdays(let s):
            _freqMode = State(initialValue: .weekdays)
            _weekdays = State(initialValue: s)
            _weeklyTarget = State(initialValue: 3)
        case .weekly(let n):
            _freqMode = State(initialValue: .weekly)
            _weekdays = State(initialValue: [1, 2, 3, 4, 5])
            _weeklyTarget = State(initialValue: n)
        }
    }

    private var fw: Int { store.settings.firstWeekday }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("النوع", selection: $draft.kind) {
                        Text("✨ عادة أبنيها").tag(HabitKind.build)
                        Text("🚫 عادة أتركها").tag(HabitKind.quit)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text(draft.kind == .quit
                         ? "كل يوم يُحسب نظيفًا تلقائيًا، وأنت تسجّل الزلّات فقط. هدفك سلسلة أطول بدون."
                         : "سجّل إنجازك، وشاهد المربعات تمتلئ مثل GitHub.")
                }

                if isNew {
                    Section("اقتراحات سريعة") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(draft.kind == .quit ? HabitPreset.quit : HabitPreset.build) { p in
                                    Button { apply(p) } label: {
                                        Text("\(p.emoji) \(p.name)")
                                            .font(.footnote)
                                            .padding(.horizontal, 12).frame(height: 36)
                                            .background(draft.name == p.name ? Color(hex: p.color).opacity(0.2) : Theme.surface2, in: Capsule())
                                            .overlay(Capsule().stroke(draft.name == p.name ? Color(hex: p.color) : Theme.line))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                }

                Section("العادة") {
                    TextField(draft.kind == .quit ? "الاسم، مثل: ترك التدخين" : "الاسم، مثل: قراءة 20 صفحة", text: $draft.name)
                    TextField("وصف قصير (اختياري)", text: $draft.detail)
                }

                Section("الرمز") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                        ForEach(Theme.emojis, id: \.self) { e in
                            Button { draft.emoji = e } label: {
                                Text(e).font(.system(size: 22))
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(draft.emoji == e ? draft.color.opacity(0.22) : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(draft.emoji == e ? draft.color : .clear, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("اللون") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 12) {
                        ForEach(Theme.palette, id: \.self) { hex in
                            Button { draft.colorHex = hex } label: {
                                Circle().fill(Color(hex: hex))
                                    .frame(width: 34, height: 34)
                                    .overlay(Circle().stroke(.white, lineWidth: draft.colorHex == hex ? 3 : 0))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if draft.kind == .build {
                    Section {
                        Stepper(value: $draft.goal, in: 1...999) {
                            HStack {
                                Text("الهدف في اليوم")
                                Spacer()
                                Text("\(draft.goal)").font(.headline).monospacedDigit()
                            }
                        }
                        if draft.goal > 1 {
                            TextField("الوحدة: كوب، صفحة، تكرار…", text: $draft.unit)
                        }
                    } header: {
                        Text("الهدف")
                    } footer: {
                        Text("إذا كان الهدف أكثر من 1، كل ضغطة تضيف واحدًا حتى يكتمل اليوم.")
                    }

                    Section("التكرار") {
                        Picker("التكرار", selection: $freqMode) {
                            ForEach(FreqMode.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        switch freqMode {
                        case .daily:
                            EmptyView()
                        case .weekdays:
                            WeekdayPicker(selection: $weekdays, firstWeekday: fw)
                        case .weekly:
                            Stepper(value: $weeklyTarget, in: 1...7) {
                                HStack {
                                    Text("مرات في الأسبوع")
                                    Spacer()
                                    Text("\(weeklyTarget)").font(.headline).monospacedDigit()
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        DatePicker("بدأت الإقلاع منذ", selection: $draft.startDate, in: ...Day.today, displayedComponents: .date)
                    } footer: {
                        Text("تُحسب الأيام النظيفة من هذا التاريخ.")
                    }
                }

                Section {
                    planField(Atomic.identity)
                } header: {
                    Text(draft.kind == .quit ? "⚛️ القوانين المعكوسة للتخلص من العادة" : "⚛️ قوانين العادات الذرية الأربعة")
                }

                ForEach(Array(Atomic.laws(for: draft.kind).enumerated()), id: \.element.id) { item in
                    Section {
                        DisclosureGroup {
                            ForEach(item.element.fields) { planField($0) }
                        } label: {
                            HStack(spacing: 10) {
                                Text("\(item.offset + 1)")
                                    .font(.footnote.bold())
                                    .foregroundStyle(Color(hex: "#C4B5FD"))
                                    .frame(width: 26, height: 26)
                                    .background(Color(hex: "#262145"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                Text(item.element.title).font(.subheadline.bold())
                                if item.element.fields.contains(where: { !draft.plan[keyPath: $0.key].isEmpty }) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.ok).font(.footnote)
                                }
                            }
                        }
                    }
                }

                Section {
                    ForEach($draft.reminders) { $r in
                        VStack(alignment: .leading, spacing: 10) {
                            DatePicker("الوقت", selection: timeBinding($r), displayedComponents: .hourAndMinute)
                            WeekdayPicker(selection: $r.weekdays, firstWeekday: fw)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { draft.reminders.remove(atOffsets: $0) }
                    Button {
                        draft.reminders.append(Reminder())
                        Task { await Notifications.requestAuthorization() }
                    } label: {
                        Label("إضافة تذكير", systemImage: "bell.badge")
                    }
                } header: {
                    Text("⏰ التذكيرات")
                } footer: {
                    Text("تصلك إشعارات في الوقت المحدد، وفيها زر «تم ✓» لتسجيل العادة دون فتح التطبيق. اسحب لليسار لحذف تذكير.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle(isNew ? "عادة جديدة" : "تعديل العادة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "إضافة" : "حفظ") { save() }
                        .bold()
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func planField(_ f: LawField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(f.label).font(.caption).foregroundStyle(Theme.muted)
            TextField(f.placeholder, text: Binding(
                get: { draft.plan[keyPath: f.key] },
                set: { draft.plan[keyPath: f.key] = $0 }
            ), axis: .vertical)
            .lineLimit(1...4)
        }
        .padding(.vertical, 4)
    }

    private func timeBinding(_ r: Binding<Reminder>) -> Binding<Date> {
        Binding(
            get: {
                Day.calendar.date(bySettingHour: r.wrappedValue.hour, minute: r.wrappedValue.minute, second: 0, of: Day.today) ?? Day.today
            },
            set: { d in
                r.wrappedValue.hour = Day.calendar.component(.hour, from: d)
                r.wrappedValue.minute = Day.calendar.component(.minute, from: d)
            }
        )
    }

    private func apply(_ p: HabitPreset) {
        draft.name = p.name
        draft.detail = p.detail
        draft.emoji = p.emoji
        draft.colorHex = p.color
        draft.goal = p.goal
        draft.unit = p.unit
        draft.plan = p.plan
        switch p.frequency {
        case .daily: freqMode = .daily
        case .weekdays(let s):
            freqMode = .weekdays
            weekdays = s
        case .weekly(let n):
            freqMode = .weekly
            weeklyTarget = n
        }
    }

    private func save() {
        var h = draft
        h.name = h.name.trimmingCharacters(in: .whitespacesAndNewlines)
        h.detail = h.detail.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.kind == .build {
            switch freqMode {
            case .daily: h.frequency = .daily
            case .weekdays: h.frequency = weekdays.isEmpty ? .daily : .weekdays(weekdays)
            case .weekly: h.frequency = .weekly(weeklyTarget)
            }
        } else {
            h.frequency = .daily
            h.goal = 1
        }
        h.startDate = Day.start(h.startDate)
        h.reminders = h.reminders.filter { !$0.weekdays.isEmpty }
        store.upsert(h)
        if isNew {
            store.show(h.emoji, h.kind == .quit ? "بدأت رحلة الإقلاع. يومًا بيوم." : "أضيفت العادة. ابدأ صغيرًا!")
        }
        dismiss()
    }
}
