import Foundation
import UserNotifications

final class NotificationService: @unchecked Sendable {
    
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    // UserDefaults Keys
    private let enabledKey = "laotie_reminder_enabled"
    private let hourKey = "laotie_reminder_hour"
    private let minuteKey = "laotie_reminder_minute"
    
    var isReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            if newValue {
                scheduleNotifications()
            } else {
                cancelAllNotifications()
            }
        }
    }
    
    var reminderHour: Int {
        get {
            let h = UserDefaults.standard.integer(forKey: hourKey)
            return h == 0 ? 20 : h  // 默认 20:00
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hourKey)
            if isReminderEnabled { scheduleNotifications() }
        }
    }
    
    var reminderMinute: Int {
        get { UserDefaults.standard.integer(forKey: minuteKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: minuteKey)
            if isReminderEnabled { scheduleNotifications() }
        }
    }
    
    /// 提醒时间（Date 用于 DatePicker 绑定）
    var reminderTime: Date {
        get {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour ?? 20
            reminderMinute = components.minute ?? 0
        }
    }
    
    private init() {}
    
    // MARK: - 权限请求
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("[NotificationService] 权限请求失败: \(error)")
            return false
        }
    }
    
    // MARK: - 调度通知
    
    func scheduleNotifications() {
        cancelAllNotifications()
        
        guard isReminderEnabled else { return }
        
        // 1. 每日打卡提醒（用户自定义时间）
        scheduleDailyReminder()
        
        // 2. 断档预警（22:00）
        scheduleDeadlineWarning()
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "唠嗑小馆"
        
        // 随机选择一条东北话风格提醒
        let messages = [
            "铁子，今天还没学东北话呢！赶紧整两句！",
            "咋的，今天不唠了？快来学两句东北话！",
            "别光瞅手机了，来唠嗑小馆学两句呗！",
            "南方小土豆，今天的东北话学了没？",
            "嘎哈呢？赶紧来打卡，别断档了！",
            "铁子醒醒，该学东北话了！"
        ]
        content.body = messages.randomElement() ?? messages[0]
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "laotie_daily_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("[NotificationService] 每日提醒设置失败: \(error)")
            }
        }
    }
    
    private func scheduleDeadlineWarning() {
        let content = UNMutableNotificationContent()
        content.title = "唠嗑小馆"
        content.body = "再不学就断档了！赶紧整两句，保住连续记录！"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "laotie_deadline_warning",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("[NotificationService] 断档预警设置失败: \(error)")
            }
        }
    }
    
    // MARK: - 取消通知
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    /// 清除 badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }
}
