import SwiftUI

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct CircleIconButton: View {
    var systemImage: String
    var primary = false
    var size: CGFloat = 42
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(primary ? Color.white : Color.primary)
                .frame(width: size, height: size)
                .background(primary ? Theme.accent : Theme.surface2, in: Circle())
                .overlay(Circle().stroke(primary ? Color.clear : Theme.line))
                .shadow(color: primary ? Theme.accent.opacity(0.5) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(PressableStyle())
    }
}

struct Panel<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.line))
    }
}

struct PanelTitle: View {
    var title: String
    var systemImage: String
    var color: Color = Theme.accent

    var body: some View {
        Label {
            Text(title).font(.system(size: 15, weight: .heavy))
        } icon: {
            Image(systemName: systemImage).foregroundStyle(color)
        }
    }
}

/// زر تسجيل اليوم: علامة صح، أو حلقة تقدّم للهدف العددي، أو درع للعادات التي تتركها
struct CheckButton: View {
    let habit: Habit
    var size: CGFloat = 46
    var date: Date = Day.today
    @Environment(HabitStore.self) private var store

    var body: some View {
        let st = habit.status(on: date)
        Button {
            store.tap(habit.id, on: date)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(background(st))
                content(st)
            }
            .frame(width: size, height: size)
            .overlay(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).stroke(.white.opacity(st == .done ? 0 : 0.06)))
            .shadow(color: st == .done ? habit.color.opacity(0.45) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(PressableStyle(scale: 0.86))
        .sensoryFeedback(.impact(weight: .light), trigger: habit.count(on: date))
        .accessibilityLabel(label(st))
    }

    private func background(_ st: DayStatus) -> Color {
        switch st {
        case .done: return habit.color
        case .slip: return Theme.danger.opacity(0.16)
        default: return habit.color.opacity(0.18)
        }
    }

    @ViewBuilder
    private func content(_ st: DayStatus) -> some View {
        let icon = size * 0.44
        if habit.kind == .quit {
            switch st {
            case .slip:
                Image(systemName: "xmark.shield.fill").font(.system(size: icon)).foregroundStyle(Theme.danger)
            case .done:
                Image(systemName: "checkmark.shield.fill").font(.system(size: icon)).foregroundStyle(.black.opacity(0.8))
            default:
                Image(systemName: "shield").font(.system(size: icon)).foregroundStyle(habit.color)
            }
        } else if st == .done {
            Image(systemName: "checkmark").font(.system(size: icon, weight: .bold)).foregroundStyle(.black.opacity(0.8))
        } else if habit.goal > 1 {
            let c = habit.count(on: date)
            ZStack {
                ProgressRing(fraction: Double(c) / Double(habit.goal), color: habit.color, lineWidth: size * 0.07)
                    .padding(size * 0.12)
                if c > 0 {
                    Text("\(c)").font(.system(size: size * 0.26, weight: .heavy)).foregroundStyle(habit.color)
                } else {
                    Image(systemName: "plus").font(.system(size: size * 0.3, weight: .bold)).foregroundStyle(habit.color)
                }
            }
        } else {
            Image(systemName: "checkmark").font(.system(size: icon, weight: .bold)).foregroundStyle(habit.color)
        }
    }

    private func label(_ st: DayStatus) -> String {
        if habit.kind == .quit { return st == .slip ? "زلّة اليوم" : "صامد اليوم، اضغط لتسجيل زلّة" }
        if habit.goal > 1 { return "\(habit.count(on: date)) من \(habit.goal)" }
        return st == .done ? "تم" : "لم يتم"
    }
}

struct Pill: View {
    var systemImage: String
    var text: String
    var color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(color.opacity(0.16), in: Capsule())
    }
}

struct StatTile: View {
    var systemImage: String
    var value: String
    var unit: String = ""
    var label: String
    var color: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .padding(.bottom, 8)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(size: 26, weight: .heavy)).monospacedDigit()
                if !unit.isEmpty { Text(unit).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.muted) }
            }
            Text(label).font(.caption).foregroundStyle(Theme.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.line))
    }
}

struct ToastView: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        ZStack {
            if let t = store.toast {
                HStack(spacing: 12) {
                    Text(t.icon).font(.title3)
                    Text(t.text).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                    if let undo = t.undo {
                        Button("تراجع") {
                            undo()
                            store.toast = nil
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.accent)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.08)))
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .id(t.id)
                .task(id: t.id) {
                    try? await Task.sleep(for: .seconds(t.undo == nil ? 3 : 5))
                    if store.toast?.id == t.id {
                        withAnimation { store.toast = nil }
                    }
                }
                .onTapGesture { withAnimation { store.toast = nil } }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.toast?.id)
    }
}

struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    var firstWeekday: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Day.orderedWeekdays(first: firstWeekday), id: \.self) { wd in
                let on = selection.contains(wd)
                Button {
                    if on { selection.remove(wd) } else { selection.insert(wd) }
                } label: {
                    Text(Day.weekdaysShort[wd - 1])
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .foregroundStyle(on ? Color.white : Theme.muted)
                        .background(on ? Theme.accent : Theme.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct NoteTarget: Identifiable {
    let habitID: UUID
    let date: Date
    var id: String { habitID.uuidString + Day.key(date) }
}

struct NoteEditor: View {
    let target: NoteTarget
    @Environment(HabitStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        let habit = store.habit(target.habitID)
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                if let habit {
                    Text("\(habit.emoji) \(habit.name) · \(Day.long(target.date))")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("ما الذي سار جيدًا؟ وما الذي اعترض طريقك؟")
                                .foregroundStyle(Theme.muted.opacity(0.6))
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                    }
            }
            .padding(16)
            .background(Theme.bg)
            .navigationTitle("ملاحظة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        store.setNote(target.habitID, date: target.date, text: text)
                        dismiss()
                    }.bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { text = habit?.notes[Day.key(target.date)] ?? "" }
    }
}
