//
//  NotificationManager.swift
//  IronLog
//
//  本地通知：休息计时结束提醒 + PR 达成祝贺。
//  纯本地，无远程推送。
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private var isAuthorized = false

    /// 请求通知权限（首次使用计时器或达成 PR 时调用）。
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            isAuthorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            isAuthorized = false
        }
    }

    /// 安排组间休息结束提醒。
    func scheduleRestFinished(after seconds: TimeInterval) {
        guard seconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif.rest.title")
        content.body = String(localized: "notif.rest.body")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "rest.timer",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// 取消已安排的休息提醒（提前结束计时时）。
    func cancelRest() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["rest.timer"])
    }

    /// 立即推送 PR 达成祝贺。
    func notifyPR(exerciseName: String, detail: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif.pr.title")
        content.body = String(format: String(localized: "notif.pr.body"), exerciseName, detail)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "pr.\(UUID().uuidString)",
            content: content,
            trigger: nil // 立即触发
        )
        UNUserNotificationCenter.current().add(request)
    }
}
