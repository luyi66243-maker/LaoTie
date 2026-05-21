import SwiftUI

@main
struct LaoTieApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // 清除 badge
                    NotificationService.shared.clearBadge()
                    // 重新调度通知
                    if NotificationService.shared.isReminderEnabled {
                        NotificationService.shared.scheduleNotifications()
                    }
                }
        }
    }
}
