import SwiftUI
import UserNotifications

@main
struct AtharApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = HabitStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Notifications.registerCategories()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == Notifications.doneAction,
              let id = response.notification.request.content.userInfo["habitID"] as? String else { return }
        var data = AppData.load()
        if let i = data.habits.firstIndex(where: { $0.id.uuidString == id }) {
            let h = data.habits[i]
            if h.kind == .build && !h.isDone(Day.today) {
                data.habits[i].log[Day.key(Day.today)] = h.goal
                data.save()
            }
        }
        await MainActor.run {
            NotificationCenter.default.post(name: .atharDataChanged, object: nil)
        }
    }
}

struct RootView: View {
    @Environment(HabitStore.self) private var store
    @Environment(\.scenePhase) private var phase

    var body: some View {
        HomeView()
            .fullScreenCover(isPresented: Binding(
                get: { !store.settings.onboarded },
                set: { shown in if !shown { store.updateSettings { $0.onboarded = true } } }
            )) {
                OnboardingView()
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .onChange(of: phase) { _, p in
                if p == .active { store.reload() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .atharDataChanged)) { _ in
                store.reload()
            }
            .task {
                Notifications.reschedule(store.data.habits)
            }
    }
}
