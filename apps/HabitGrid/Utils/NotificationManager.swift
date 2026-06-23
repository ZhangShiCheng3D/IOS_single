//
//  NotificationManager.swift
//  HabitGrid
//
//  本地通知：每日习惯提醒的授权、调度与取消。
//

import Foundation
import Observation
import UserNotifications

/// 封装 UNUserNotificationCenter，提供习惯提醒的增删与权限请求。
/// MainActor 隔离，使全局单例在 Swift 6 严格并发下安全。
@Observable
@MainActor
final class NotificationManager {

    static let shared = NotificationManager()

    /// 最近一次已知的授权状态。
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// 请求通知授权。返回是否已授权。
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            return granted
        } catch {
            await refreshStatus()
            return false
        }
    }

    /// 刷新当前授权状态。
    func refreshStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
        }
    }

    /// 为某个习惯调度每日提醒。会先取消旧的同 id 通知，避免重复。
    /// - Parameters:
    ///   - habitID: 习惯唯一标识，用作通知请求 id。
    ///   - title: 习惯名称。
    ///   - time: 提醒时间（仅取时分）。
    func scheduleReminder(habitID: UUID, title: String, time: Date) async {
        cancelReminder(habitID: habitID)

        // 确保已授权；未授权则尝试请求。
        if authorizationStatus != .authorized {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = String(localized: "notification.body")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: requestID(for: habitID),
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // 调度失败不致命，仅记录。
            print("通知调度失败: \(error.localizedDescription)")
        }
    }

    /// 取消某个习惯的提醒。
    func cancelReminder(habitID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [requestID(for: habitID)])
    }

    /// 清除应用角标。
    func clearBadge() {
        center.setBadgeCount(0)
    }

    private func requestID(for habitID: UUID) -> String {
        "habit-reminder-\(habitID.uuidString)"
    }
}
