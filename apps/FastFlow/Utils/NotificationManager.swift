//
//  NotificationManager.swift
//  FastFlow
//
//  本地通知管理：断食目标达成提醒、喝水定时提醒。
//

import Foundation
import UserNotifications

/// 本地通知管理器（单例）。
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // 通知标识前缀。
    private static let fastingGoalID = "fastflow.fasting.goal"
    private static let waterReminderPrefix = "fastflow.water.reminder."
    /// 喝水提醒最多可能的时段数（覆盖 0...23 时）。
    private static let maxWaterReminderSlots = 24

    /// 请求通知权限。返回是否授权。
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// 当前授权状态。
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - 断食目标提醒

    /// 在断食达到目标时间时安排一条提醒。
    func scheduleFastingGoalNotification(at fireDate: Date, planName: String) {
        cancelFastingGoalNotification()
        guard fireDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif.fasting.title", comment: "")
        content.body = String(
            format: NSLocalizedString("notif.fasting.body", comment: ""),
            planName
        )
        content.sound = .default

        let interval = fireDate.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.fastingGoalID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// 取消断食目标提醒。
    func cancelFastingGoalNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.fastingGoalID])
    }

    // MARK: - 喝水提醒

    /// 安排每日喝水提醒。`startHour`...`endHour` 之间每隔 `intervalHours` 提醒一次。
    func scheduleWaterReminders(startHour: Int, endHour: Int, intervalHours: Int) {
        cancelWaterReminders()
        guard intervalHours > 0, endHour > startHour else { return }

        var hour = startHour
        var index = 0
        while hour <= endHour {
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notif.water.title", comment: "")
            content.body = NSLocalizedString("notif.water.body", comment: "")
            content.sound = .default

            var components = DateComponents()
            components.hour = hour
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: Self.waterReminderPrefix + "\(index)",
                content: content,
                trigger: trigger
            )
            center.add(request)

            hour += intervalHours
            index += 1
        }
    }

    /// 取消所有喝水提醒（移除全部可能的时段标识）。
    func cancelWaterReminders() {
        let ids = (0..<Self.maxWaterReminderSlots).map { Self.waterReminderPrefix + "\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
