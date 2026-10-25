import SwiftUI
import Observation

struct ToastMessage: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    var undo: (() -> Void)?
}

@Observable
final class HabitStore {
    private(set) var data: AppData
    var toast: ToastMessage?

    init() {
        data = AppData.load()
    }

    var settings: AppSettings { data.settings }
    var active: [Habit] { data.habits.filter { !$0.archived } }
    var archived: [Habit] { data.habits.filter { $0.archived } }

    func habit(_ id: UUID) -> Habit? { data.habits.first { $0.id == id } }

    func reload() {
        data = AppData.load()
    }

    private func commit(reschedule: Bool = false) {
        data.save()
        if reschedule { Notifications.reschedule(data.habits) }
    }

    // MARK: - الإعدادات

    func updateSettings(_ change: (inout AppSettings) -> Void) {
        change(&data.settings)
        commit()
    }

    // MARK: - العادات

    func upsert(_ habit: Habit) {
        if let i = data.habits.firstIndex(where: { $0.id == habit.id }) {
            data.habits[i] = habit
        } else {
            data.habits.append(habit)
        }
        commit(reschedule: true)
    }

    func delete(_ id: UUID) {
        data.habits.removeAll { $0.id == id }
        commit(reschedule: true)
    }

    func setArchived(_ id: UUID, _ archived: Bool) {
        guard let i = data.habits.firstIndex(where: { $0.id == id }) else { return }
        data.habits[i].archived = archived
        commit(reschedule: true)
    }

    func moveActive(from source: IndexSet, to destination: Int) {
        var list = active
        list.move(fromOffsets: source, toOffset: destination)
        data.habits = list + archived
        commit()
    }

    func setNote(_ id: UUID, date: Date, text: String) {
        guard let i = data.habits.firstIndex(where: { $0.id == id }) else { return }
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        data.habits[i].notes[Day.key(date)] = t.isEmpty ? nil : t
        commit()
    }

    func replaceAll(with newData: AppData) {
        var d = newData
        d.settings.onboarded = true
        data = d
        commit(reschedule: true)
    }

    func deleteEverything() {
        data = AppData()
        data.settings.onboarded = true
        commit(reschedule: true)
    }

    // MARK: - التسجيل اليومي

    func tap(_ id: UUID, on date: Date) {
        guard let i = data.habits.firstIndex(where: { $0.id == id }), Day.start(date) <= Day.today else { return }
        let before = data.habits[i]
        if before.kind == .quit && Day.start(date) < Day.start(before.startDate) { return }
        let outcome = data.habits[i].tap(on: date)
        commit()
        let isToday = Day.start(date) == Day.today
        switch outcome {
        case .completed where isToday:
            celebrate(data.habits[i])
        case .slipped where isToday:
            show("🤍", "لا بأس، الزلّة لا تعني الفشل. المهم ألا تفوّت مرتين.") { [weak self] in
                guard let self, let j = self.data.habits.firstIndex(where: { $0.id == id }) else { return }
                self.data.habits[j] = before
                self.commit()
            }
        default:
            break
        }
    }

    private func celebrate(_ h: Habit) {
        let s = h.stats(firstWeekday: settings.firstWeekday)
        let yesterday = Day.add(-1, Day.today)
        let missedYesterday = yesterday >= h.effectiveStart && h.isScheduled(yesterday) && !h.isDone(yesterday)
        let text: String
        if s.periodIsWeek, let target = h.weeklyTarget, h.doneThisWeek(firstWeekday: settings.firstWeekday) == target {
            text = "أكملت هدف الأسبوع! \(target) من \(target)"
        } else if !s.periodIsWeek && missedYesterday && s.doneDays > 1 {
            text = "عدت للمسار! لا تفوّت مرتين أبدًا."
        } else if !s.periodIsWeek && [7, 21, 30, 66, 100, 365].contains(s.current) {
            text = "\(s.current) يومًا متتاليًا! أنت تبني هوية جديدة."
        } else if !h.plan.identity.isEmpty {
            text = "صوت جديد لهويتك: «\(h.plan.identity)»"
        } else {
            text = s.current > 1 ? "أحسنت! السلسلة: \(s.current)" : "أحسنت! بداية رائعة"
        }
        show(h.emoji, text)
    }

    func show(_ icon: String, _ text: String, undo: (() -> Void)? = nil) {
        toast = ToastMessage(icon: icon, text: text, undo: undo)
    }
}
