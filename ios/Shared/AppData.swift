import Foundation
import WidgetKit

/// كل بيانات التطبيق في ملف JSON واحد داخل حاوية App Group، يقرؤه التطبيق والودجت معًا.
struct AppData: Codable {
    var version = 1
    var settings = AppSettings()
    var habits: [Habit] = []

    static let appGroup = "group.com.athar.habits"

    static var fileURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("athar-data.json")
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func load() -> AppData {
        let url = fileURL
        guard let raw = try? Data(contentsOf: url) else { return AppData() }
        do {
            return try decoder.decode(AppData.self, from: raw)
        } catch {
            // احتفظ بنسخة من الملف التالف بدل الكتابة فوقه
            let backup = url.deletingLastPathComponent().appendingPathComponent("athar-data-\(Int(Date().timeIntervalSince1970)).bak.json")
            try? FileManager.default.copyItem(at: url, to: backup)
            return AppData()
        }
    }

    func save() {
        if let raw = try? Self.encoder.encode(self) {
            try? raw.write(to: Self.fileURL, options: .atomic)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func exportData() -> Data {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? e.encode(self)) ?? Data()
    }
}

extension AppData {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = c.value(.version, 1)
        settings = c.value(.settings, AppSettings())
        habits = try c.decodeIfPresent([Habit].self, forKey: .habits) ?? []
    }
}

extension Notification.Name {
    static let atharDataChanged = Notification.Name("atharDataChanged")
}
