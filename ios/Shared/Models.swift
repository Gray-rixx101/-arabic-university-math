import Foundation
import SwiftUI

enum HabitKind: String, Codable, CaseIterable, Hashable {
    case build
    case quit
}

/// كم مرة يجب أداء العادة. الأيام بترقيم Calendar: الأحد = 1 ... السبت = 7
enum Frequency: Codable, Hashable {
    case daily
    case weekdays(Set<Int>)
    case weekly(Int)
}

struct Reminder: Codable, Hashable, Identifiable {
    var id = UUID()
    var hour = 8
    var minute = 0
    var weekdays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
}

/// خطة «العادات الذرية»: القوانين الأربعة للبناء، والمعكوسة للإقلاع.
struct AtomicPlan: Codable, Hashable {
    var identity = ""
    // بناء
    var cue = ""
    var stack = ""
    var bundle = ""
    var twoMinute = ""
    var reward = ""
    // إقلاع
    var trigger = ""
    var why = ""
    var friction = ""
    var accountability = ""
    var replacement = ""
}

struct Habit: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var detail = ""
    var emoji = "🎯"
    var colorHex = "#A78BFA"
    var kind: HabitKind = .build
    var goal = 1
    var unit = ""
    var frequency: Frequency = .daily
    var startDate = Day.today
    var archived = false
    var plan = AtomicPlan()
    /// "yyyy-MM-dd" → عدد مرات الإنجاز (بناء) أو عدد الزلّات (إقلاع)
    var log: [String: Int] = [:]
    var notes: [String: String] = [:]
    var reminders: [Reminder] = []
    var createdAt = Date()

    var color: Color { Color(hex: colorHex) }
}

enum ViewMode: String, Codable, CaseIterable {
    case list
    case cards
    case compact
}

struct AppSettings: Codable, Hashable {
    var firstWeekday = 1
    var viewMode: ViewMode = .cards
    var listDays = 5
    var showQuote = true
    var onboarded = false
}

// MARK: - فك ترميز متسامح حتى لا تضيع البيانات عند إضافة حقول جديدة

extension KeyedDecodingContainer {
    func value<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? fallback
    }
}

extension AtomicPlan {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        identity = c.value(.identity, "")
        cue = c.value(.cue, "")
        stack = c.value(.stack, "")
        bundle = c.value(.bundle, "")
        twoMinute = c.value(.twoMinute, "")
        reward = c.value(.reward, "")
        trigger = c.value(.trigger, "")
        why = c.value(.why, "")
        friction = c.value(.friction, "")
        accountability = c.value(.accountability, "")
        replacement = c.value(.replacement, "")
    }
}

extension Habit {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(.id, UUID())
        name = c.value(.name, "عادة")
        detail = c.value(.detail, "")
        emoji = c.value(.emoji, "🎯")
        colorHex = c.value(.colorHex, "#A78BFA")
        kind = c.value(.kind, HabitKind.build)
        goal = max(1, c.value(.goal, 1))
        unit = c.value(.unit, "")
        frequency = c.value(.frequency, Frequency.daily)
        startDate = c.value(.startDate, Day.today)
        archived = c.value(.archived, false)
        plan = c.value(.plan, AtomicPlan())
        log = c.value(.log, [String: Int]())
        notes = c.value(.notes, [String: String]())
        reminders = c.value(.reminders, [Reminder]())
        createdAt = c.value(.createdAt, Date())
    }
}

extension AppSettings {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        firstWeekday = c.value(.firstWeekday, 1)
        viewMode = c.value(.viewMode, ViewMode.cards)
        listDays = c.value(.listDays, 5)
        showQuote = c.value(.showQuote, true)
        onboarded = c.value(.onboarded, false)
    }
}

// MARK: - القوانين والاقتراحات

struct LawField: Identifiable {
    let id: String
    let key: WritableKeyPath<AtomicPlan, String>
    let label: String
    let placeholder: String
}

struct Law: Identifiable {
    let id: String
    let title: String
    let fields: [LawField]
}

enum Atomic {
    static let identity = LawField(id: "identity", key: \.identity, label: "الهوية: من الشخص الذي تريد أن تصبحه؟", placeholder: "مثال: أنا شخص يهتم بصحته")

    static let buildLaws: [Law] = [
        Law(id: "b1", title: "اجعلها واضحة", fields: [
            LawField(id: "cue", key: \.cue, label: "النية التنفيذية (متى وأين؟)", placeholder: "سأقوم بـ ... في الساعة ... في ..."),
            LawField(id: "stack", key: \.stack, label: "تكديس العادات", placeholder: "بعد أن [عادة حالية]، سأقوم بـ [العادة الجديدة]"),
        ]),
        Law(id: "b2", title: "اجعلها جذابة", fields: [
            LawField(id: "bundle", key: \.bundle, label: "ربط الإغراء", placeholder: "بعد أن أنجزها، سأفعل شيئًا أحبه: ..."),
        ]),
        Law(id: "b3", title: "اجعلها سهلة", fields: [
            LawField(id: "twoMinute", key: \.twoMinute, label: "قاعدة الدقيقتين", placeholder: "أسهل نسخة منها تأخذ أقل من دقيقتين: ..."),
        ]),
        Law(id: "b4", title: "اجعلها مُرضية", fields: [
            LawField(id: "reward", key: \.reward, label: "المكافأة الفورية", placeholder: "عندما أنجزها سأكافئ نفسي بـ ..."),
        ]),
    ]

    static let quitLaws: [Law] = [
        Law(id: "q1", title: "اجعلها غير مرئية", fields: [
            LawField(id: "trigger", key: \.trigger, label: "ما الذي يحفّزها؟ وكيف تبتعد عنه؟", placeholder: "مثال: أترك الجوال خارج غرفة النوم"),
        ]),
        Law(id: "q2", title: "اجعلها غير جذابة", fields: [
            LawField(id: "why", key: \.why, label: "لماذا تريد تركها؟", placeholder: "ما الضرر الذي تسببه، وما الذي ستكسبه بتركها؟"),
        ]),
        Law(id: "q3", title: "اجعلها صعبة", fields: [
            LawField(id: "friction", key: \.friction, label: "أضف عوائق", placeholder: "مثال: لا أحتفظ بها في البيت"),
        ]),
        Law(id: "q4", title: "اجعلها غير مُرضية", fields: [
            LawField(id: "accountability", key: \.accountability, label: "شريك المحاسبة", placeholder: "سأخبر ... وإذا زللت سأقوم بـ ..."),
        ]),
        Law(id: "q5", title: "العادة البديلة", fields: [
            LawField(id: "replacement", key: \.replacement, label: "ماذا ستفعل بدلًا منها؟", placeholder: "عندما أشعر بالرغبة سأقوم بـ ..."),
        ]),
    ]

    static func laws(for kind: HabitKind) -> [Law] { kind == .quit ? quitLaws : buildLaws }

    static let quotes = [
        "تحسّن 1% كل يوم يعني أن تصبح أفضل بـ 37 ضعفًا خلال سنة.",
        "كل مرة تنجز فيها عادتك، تمنح صوتًا للشخص الذي تريد أن تصبحه.",
        "لا ترتفع إلى مستوى أهدافك، بل تهبط إلى مستوى أنظمتك.",
        "لا تفوّت مرتين أبدًا. المرة الواحدة خطأ، والمرتان بداية عادة جديدة.",
        "اجعلها سهلة لدرجة أنك لا تستطيع الرفض.",
        "البيئة أقوى من الإرادة. صمّم محيطك لينجح.",
        "العادة التي لا تُقاس لا تتحسن.",
        "أهم شيء أن تحضر. ابدأ صغيرًا، ثم كبّر.",
    ]

    static var quoteOfTheDay: String {
        quotes[abs(Day.daysBetween(Date(timeIntervalSince1970: 0), Day.today)) % quotes.count]
    }
}

struct HabitPreset: Identifiable {
    var id: String { name }
    let name: String
    let detail: String
    let emoji: String
    let color: String
    var goal = 1
    var unit = ""
    var frequency: Frequency = .daily
    var plan = AtomicPlan()

    static let build: [HabitPreset] = [
        HabitPreset(name: "شرب الماء", detail: "اشرب ما يكفي طوال اليوم", emoji: "💧", color: "#5ED0EA", goal: 8, unit: "كوب",
                    plan: AtomicPlan(cue: "زجاجة ماء دائمًا على مكتبي", stack: "بعد أن أصلي، سأشرب كوب ماء", twoMinute: "رشفة واحدة فقط")),
        HabitPreset(name: "قراءة 20 صفحة", detail: "خصص وقتًا لكتاب جيد", emoji: "📖", color: "#A78BFA", goal: 20, unit: "صفحة",
                    plan: AtomicPlan(identity: "أنا قارئ", stack: "بعد العشاء، سأقرأ وأنا أشرب الشاي", twoMinute: "اقرأ صفحة واحدة")),
        HabitPreset(name: "الجري صباحًا", detail: "ابدأ يومك بالجري", emoji: "🏃", color: "#A3E635",
                    plan: AtomicPlan(identity: "أنا رياضي", cue: "أضع ملابس الجري بجانب السرير", twoMinute: "البس حذاء الجري واخرج من الباب")),
        HabitPreset(name: "النادي", detail: "تمرين قوة", emoji: "🏋️", color: "#F5C142", frequency: .weekly(3),
                    plan: AtomicPlan(twoMinute: "جهّز حقيبة النادي")),
        HabitPreset(name: "التأمل", detail: "لحظة هدوء لنفسك", emoji: "🧘", color: "#5FD39A", plan: AtomicPlan(twoMinute: "تنفّس بعمق 3 مرات")),
        HabitPreset(name: "ورد القرآن", detail: "ولو صفحة كل يوم", emoji: "📗", color: "#5ED6C0",
                    plan: AtomicPlan(stack: "بعد صلاة الفجر، سأقرأ وردي", twoMinute: "آية واحدة")),
        HabitPreset(name: "أذكار الصباح والمساء", detail: "حصّن يومك", emoji: "📿", color: "#818CF8", goal: 2, unit: "مرة"),
        HabitPreset(name: "صيام الاثنين والخميس", detail: "سنة نبوية", emoji: "🌙", color: "#FACC15", frequency: .weekdays([2, 5])),
        HabitPreset(name: "النوم 8 ساعات", detail: "نم مبكرًا", emoji: "😴", color: "#818CF8"),
        HabitPreset(name: "اليوميات", detail: "اكتب ما في بالك", emoji: "✍️", color: "#F472B6", plan: AtomicPlan(twoMinute: "اكتب سطرًا واحدًا")),
        HabitPreset(name: "خيط الأسنان", detail: "ابتسامة أصح", emoji: "🦷", color: "#5AA9F5", plan: AtomicPlan(stack: "بعد أن أفرّش أسناني، سأستخدم الخيط")),
    ]

    static let quit: [HabitPreset] = [
        HabitPreset(name: "ترك التدخين", detail: "أنفاس أنقى كل يوم", emoji: "🚭", color: "#F07178",
                    plan: AtomicPlan(identity: "أنا شخص لا يدخّن", why: "صحتي، مالي، وعائلتي", replacement: "أمضغ علكة أو أمشي 5 دقائق")),
        HabitPreset(name: "بلا سكر", detail: "اختر حياة بسكر أقل", emoji: "🍬", color: "#F472B6",
                    plan: AtomicPlan(friction: "لا أشتري الحلويات ولا أحتفظ بها في البيت", replacement: "فاكهة أو تمر")),
        HabitPreset(name: "تقليل الجوال", detail: "لا تصفّح قبل النوم", emoji: "📵", color: "#5AA9F5",
                    plan: AtomicPlan(trigger: "أترك الجوال خارج غرفة النوم", friction: "أحذف التطبيقات المشتتة من الشاشة الرئيسية")),
        HabitPreset(name: "بلا وجبات سريعة", detail: "طعام بيتي أصح", emoji: "🍔", color: "#F59E4A"),
        HabitPreset(name: "بلا مشروبات غازية", detail: "الماء أفضل", emoji: "🥤", color: "#E879F9", plan: AtomicPlan(replacement: "ماء فوار بالليمون")),
        HabitPreset(name: "تقليل الألعاب", detail: "وقت أكثر لما يهم", emoji: "🎮", color: "#818CF8"),
        HabitPreset(name: "بلا شراء عشوائي", detail: "وفّر مالك", emoji: "💸", color: "#FACC15", plan: AtomicPlan(friction: "أنتظر 48 ساعة قبل أي شراء غير ضروري")),
    ]
}
