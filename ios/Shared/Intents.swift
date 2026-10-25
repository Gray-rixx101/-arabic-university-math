import AppIntents
import WidgetKit

struct HabitEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "عادة"
    static var defaultQuery = HabitQuery()

    var id: String
    var name: String
    var emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }
}

extension HabitEntity {
    init(habit: Habit) {
        id = habit.id.uuidString
        name = habit.name
        emoji = habit.emoji
    }
}

struct HabitQuery: EntityQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        AppData.load().habits
            .filter { identifiers.contains($0.id.uuidString) }
            .map { HabitEntity(habit: $0) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        AppData.load().habits
            .filter { !$0.archived }
            .map { HabitEntity(habit: $0) }
    }

    func defaultResult() async -> HabitEntity? {
        AppData.load().habits.first { !$0.archived }.map { HabitEntity(habit: $0) }
    }
}

struct SelectHabitIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "اختر العادة"
    static var description = IntentDescription("اعرض خريطة عادة واحدة على الشاشة الرئيسية.")

    @Parameter(title: "العادة")
    var habit: HabitEntity?

    init() {}
}

/// يسجّل العادة لليوم من الودجت مباشرة دون فتح التطبيق
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "سجّل العادة اليوم"
    static var isDiscoverable = false

    @Parameter(title: "العادة")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        var data = AppData.load()
        if let i = data.habits.firstIndex(where: { $0.id.uuidString == habitID }) {
            _ = data.habits[i].tap(on: Day.today)
            data.save()
        }
        return .result()
    }
}
