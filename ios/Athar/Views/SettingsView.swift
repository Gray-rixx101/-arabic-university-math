import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct SettingsView: View {
    @Environment(HabitStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var exporting = false
    @State private var importing = false
    @State private var pendingImport: AppData?
    @State private var confirmWipe = false
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    @State private var showGuide = false

    var body: some View {
        NavigationStack {
            Form {
                Section("عام") {
                    Picker("بداية الأسبوع", selection: Binding(
                        get: { store.settings.firstWeekday },
                        set: { v in store.updateSettings { $0.firstWeekday = v } }
                    )) {
                        Text("السبت").tag(7)
                        Text("الأحد").tag(1)
                        Text("الاثنين").tag(2)
                    }
                    Picker("أيام عرض القائمة", selection: Binding(
                        get: { store.settings.listDays },
                        set: { v in store.updateSettings { $0.listDays = v } }
                    )) {
                        Text("4").tag(4)
                        Text("5").tag(5)
                        Text("7").tag(7)
                    }
                    Toggle("اقتباس يومي من العادات الذرية", isOn: Binding(
                        get: { store.settings.showQuote },
                        set: { v in store.updateSettings { $0.showQuote = v } }
                    ))
                }

                Section {
                    HStack {
                        settingsIcon("bell.fill", "#5ED0EA")
                        Text("الإشعارات")
                        Spacer()
                        Text(statusText).foregroundStyle(Theme.muted).font(.footnote)
                    }
                    if notifStatus == .notDetermined {
                        Button("السماح بالإشعارات") {
                            Task {
                                await Notifications.requestAuthorization()
                                await refreshStatus()
                                Notifications.reschedule(store.data.habits)
                            }
                        }
                    } else if notifStatus == .denied {
                        Button("افتح إعدادات iPhone لتفعيلها") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                    }
                } header: {
                    Text("التذكيرات")
                } footer: {
                    Text("أضف التذكيرات من شاشة تعديل كل عادة.")
                }

                Section("العادات") {
                    NavigationLink { ArchivedView() } label: {
                        row("archivebox.fill", "#34D399", "العادات المؤرشفة", value: store.archived.isEmpty ? "" : "\(store.archived.count)")
                    }
                    NavigationLink { ReorderView() } label: {
                        row("arrow.up.arrow.down", "#F07178", "أعد ترتيب العادات")
                    }
                }

                Section {
                    Button { exporting = true } label: { row("square.and.arrow.up", "#5AA9F5", "تصدير نسخة احتياطية") }
                    Button { importing = true } label: { row("square.and.arrow.down", "#34D399", "استعادة من ملف") }
                } header: {
                    Text("النسخ والاستعادة")
                } footer: {
                    Text("بياناتك محفوظة على جهازك فقط. احفظ نسخة في «الملفات» أو iCloud Drive بين حين وآخر.")
                }

                Section("مساعدة") {
                    Button { showGuide = true } label: { row("atom", "#A78BFA", "دليل العادات الذرية") }
                    Button {
                        dismiss()
                        store.updateSettings { $0.onboarded = false }
                    } label: { row("book.fill", "#F59E4A", "إظهار المقدمة") }
                }

                Section {
                    Button(role: .destructive) { confirmWipe = true } label: {
                        Label("حذف كل البيانات", systemImage: "trash")
                    }
                }

                Section {
                    HStack {
                        settingsIcon("info.circle.fill", "#94A3B8")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("أثر")
                            Text("بلا حساب ولا إعلانات. بياناتك تبقى على جهازك.").font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Text(verbatim: "v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                            .foregroundStyle(Theme.muted).font(.footnote)
                    }
                } header: {
                    Text("حول التطبيق")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
            .task { await refreshStatus() }
            .fileExporter(isPresented: $exporting,
                          document: BackupDocument(data: store.data.exportData()),
                          contentType: .json,
                          defaultFilename: "athar-backup-\(Day.key(Day.today))") { result in
                if case .success = result { store.show("✅", "تم حفظ النسخة الاحتياطية") }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                guard case .success(let url) = result else { return }
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                if let raw = try? Data(contentsOf: url), let decoded = try? AppData.decoder.decode(AppData.self, from: raw) {
                    pendingImport = decoded
                } else {
                    store.show("⚠️", "الملف غير صالح. اختر ملف نسخة احتياطية من «أثر».")
                }
            }
            .alert("استعادة النسخة؟", isPresented: Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } })) {
                Button("إلغاء", role: .cancel) { pendingImport = nil }
                Button("استعادة", role: .destructive) {
                    if let d = pendingImport { store.replaceAll(with: d) }
                    pendingImport = nil
                    store.show("✅", "تمت الاستعادة بنجاح")
                }
            } message: {
                Text("ستُستبدل بياناتك الحالية بـ \(pendingImport?.habits.count ?? 0) عادة من الملف.")
            }
            .confirmationDialog("حذف كل شيء؟", isPresented: $confirmWipe, titleVisibility: .visible) {
                Button("حذف الكل", role: .destructive) { store.deleteEverything() }
            } message: {
                Text("سيُحذف كل العادات والسجلات والملاحظات من هذا الجهاز.")
            }
            .sheet(isPresented: $showGuide) { GuideView() }
        }
    }

    private var statusText: String {
        switch notifStatus {
        case .authorized, .provisional, .ephemeral: return "مفعّلة"
        case .denied: return "مرفوضة"
        default: return "غير مفعّلة"
        }
    }

    private func refreshStatus() async {
        notifStatus = await Notifications.authorizationStatus()
    }

    private func settingsIcon(_ name: String, _ hex: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color(hex: hex))
            .frame(width: 32, height: 32)
            .background(Color(hex: hex).opacity(0.18), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func row(_ icon: String, _ hex: String, _ title: String, value: String = "") -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon, hex)
            Text(title).foregroundStyle(Color.primary)
            Spacer()
            if !value.isEmpty { Text(value).foregroundStyle(Theme.muted) }
        }
    }
}

struct ArchivedView: View {
    @Environment(HabitStore.self) private var store
    @State private var toDelete: Habit?

    var body: some View {
        List {
            if store.archived.isEmpty {
                ContentUnavailableView("لا توجد عادات مؤرشفة", systemImage: "archivebox")
                    .listRowBackground(Color.clear)
            }
            ForEach(store.archived) { h in
                HStack(spacing: 12) {
                    EmojiTile(emoji: h.emoji, color: h.color, size: 34)
                    Text(h.name)
                    Spacer()
                    Button {
                        store.setArchived(h.id, false)
                        store.show(h.emoji, "استُعيدت العادة")
                    } label: { Image(systemName: "arrow.uturn.backward.circle.fill").font(.title2) }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.ok)
                    Button { toDelete = h } label: { Image(systemName: "trash.circle.fill").font(.title2) }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.danger)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("العادات المؤرشفة")
        .confirmationDialog("حذف نهائي؟", isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } }), titleVisibility: .visible) {
            Button("حذف", role: .destructive) {
                if let h = toDelete { store.delete(h.id) }
                toDelete = nil
            }
        } message: {
            Text("سيُحذف «\(toDelete?.name ?? "")» مع كل سجله.")
        }
    }
}

struct ReorderView: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        List {
            ForEach(store.active) { h in
                HStack(spacing: 12) {
                    EmojiTile(emoji: h.emoji, color: h.color, size: 34)
                    Text(h.name)
                }
            }
            .onMove { store.moveActive(from: $0, to: $1) }
        }
        .environment(\.editMode, .constant(.active))
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("ترتيب العادات")
    }
}

struct GuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("من كتاب «العادات الذرية» لجيمس كلير: التغييرات الصغيرة جدًا، عندما تتكرر يوميًا، تصنع نتائج مذهلة. السر ليس في الأهداف بل في الأنظمة.")
                        .foregroundStyle(Color.primary.opacity(0.85))
                    guidePanel("✨ لبناء عادة جيدة", [
                        ("اجعلها واضحة", "حدّد متى وأين: «سأقرأ 10 صفحات الساعة 9 مساءً في غرفتي». واستخدم تكديس العادات: «بعد أن أصلي العشاء، سأقرأ»."),
                        ("اجعلها جذابة", "اربطها بشيء تحبه، وانضم لأناس يرونها أمرًا طبيعيًا."),
                        ("اجعلها سهلة", "قاعدة الدقيقتين: ابدأ بنسخة لا تتجاوز دقيقتين. أتقن الحضور قبل أن تحسّن الأداء."),
                        ("اجعلها مُرضية", "كافئ نفسك فورًا، وتتبّع عادتك. رؤية المربعات تمتلئ مكافأة بحد ذاتها."),
                    ])
                    guidePanel("🚫 للتخلص من عادة سيئة", [
                        ("اجعلها غير مرئية", "أزل المحفزات من بيئتك."),
                        ("اجعلها غير جذابة", "ذكّر نفسك بفوائد تركها وأضرار الاستمرار فيها."),
                        ("اجعلها صعبة", "زِد الخطوات بينك وبينها."),
                        ("اجعلها غير مُرضية", "شريك محاسبة أو عقد مع نفسك يجعل لها ثمنًا فوريًا."),
                        ("ضع بديلًا", "لا تكتفِ بالترك: ضع عادة بديلة تلبي الحاجة نفسها."),
                    ])
                    guidePanel("🪪 العادات المبنية على الهوية", [
                        ("", "بدل «أريد أن أترك التدخين» قل «أنا لست مدخّنًا». كل مرة تنجز عادتك هي صوت للشخص الذي تريد أن تصبحه. اكتب هويتك في كل عادة وسيذكّرك «أثر» بها."),
                    ])
                    guidePanel("🔁 لا تفوّت مرتين", [
                        ("", "الكمال ليس شرطًا. إذا فوّتّ يومًا، عد في اليوم التالي مباشرة. المرة الواحدة حادث، والمرتان بداية نمط جديد."),
                    ])
                }
                .font(.subheadline)
                .lineSpacing(4)
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("العادات الذرية")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }

    private func guidePanel(_ title: String, _ items: [(String, String)]) -> some View {
        Panel {
            Text(title).font(.headline)
            ForEach(items.indices, id: \.self) { i in
                if items[i].0.isEmpty {
                    Text(items[i].1).foregroundStyle(Color.primary.opacity(0.85))
                } else {
                    (Text(items[i].0 + ": ").bold().foregroundColor(Color(hex: "#C4B5FD")) + Text(items[i].1))
                }
            }
        }
    }
}

struct OnboardingView: View {
    @Environment(HabitStore.self) private var store
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if page < 3 {
                    Button("تخطّي") { finish() }.foregroundStyle(Theme.muted)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 24)

            TabView(selection: $page) {
                slide(tag: 0,
                      art: AnyView(Panel { HeatmapView(habit: Habit.sample(), cellSize: 11) }),
                      title: "شاهد عاداتك", accent: "تؤتي ثمارها.",
                      body: "كل مربع يوم. كل يوم تنجز فيه عادتك يمتلئ مربعه، تمامًا مثل لوحة المساهمات في GitHub.")
                slide(tag: 1,
                      art: AnyView(Text("⚛️").font(.system(size: 64))),
                      title: "العادات", accent: "الذرية",
                      body: "تحسّن 1% كل يوم = 37 ضعفًا في سنة. لكل عادة تضيفها، يساعدك «أثر» على تطبيق القوانين الأربعة: اجعلها واضحة، جذابة، سهلة، ومُرضية.")
                slide(tag: 2,
                      art: AnyView(Panel { HeatmapView(habit: Habit.sample(color: "#F07178", density: 0.97, kind: .quit), cellSize: 11) }),
                      title: "عادات نافعة", accent: "بدلًا من الضارة.",
                      body: "للعادات التي تريد تركها: كل يوم يُحسب نظيفًا تلقائيًا، وأنت تسجّل الزلّات فقط. حدّد محفزاتها، اجعلها صعبة، وضع عادة بديلة.")
                slide(tag: 3,
                      art: AnyView(Text("📲").font(.system(size: 64))),
                      title: "عاداتك", accent: "على شاشتك.",
                      body: "أضف ودجت «أثر» للشاشة الرئيسية وسجّل عاداتك بلمسة دون فتح التطبيق. وفعّل التذكيرات من كل عادة.")
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule().fill(i == page ? Theme.accent : Color(hex: "#3A3A40"))
                        .frame(width: i == page ? 22 : 7, height: 7)
                }
            }
            .animation(.snappy, value: page)
            .padding(.vertical, 18)

            Button {
                if page < 3 { withAnimation { page += 1 } } else { finish() }
            } label: {
                Text(page < 3 ? "التالي" : "ابدأ الآن").frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(
            RadialGradient(colors: [Color(hex: "#1E1940"), Theme.bg], center: .top, startRadius: 0, endRadius: 520)
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    private func slide(tag: Int, art: AnyView, title: String, accent: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            art
            (Text(title + "\n").foregroundColor(.white) + Text(accent).foregroundColor(Theme.accent))
                .font(.system(size: 34, weight: .black))
            Text(body).font(.body).foregroundStyle(Color(hex: "#B9B9C2")).lineSpacing(5)
            Spacer()
        }
        .padding(.horizontal, 24)
        .tag(tag)
    }

    private func finish() {
        store.updateSettings { $0.onboarded = true }
    }
}
