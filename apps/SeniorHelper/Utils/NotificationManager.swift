//
//  NotificationManager.swift
//  SeniorHelper
//
//  本地通知管理器：申请权限、为用药计划排程每日重复提醒。
//

import Foundation
import UserNotifications
import Observation

/// 封装 UNUserNotificationCenter 的用药提醒排程逻辑。
@Observable
final class NotificationManager {

    /// 当前授权状态，供设置页展示。
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    init() {
        Task { await refreshStatus() }
    }

    /// 刷新当前授权状态。
    @MainActor
    func refreshStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// 申请通知权限。返回是否被授予。
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            return granted
        } catch {
            print("申请通知权限失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 为一条用药计划重新排程所有提醒。
    ///
    /// 会先撤销该计划旧的通知，再根据当前状态重新创建；
    /// 计划被禁用或无时间点时仅做撤销。
    func schedule(for medication: Medication) {
        cancel(for: medication)

        guard medication.isEnabled, !medication.reminderTimes.isEmpty else { return }

        let calendar = Calendar.current
        for (index, time) in medication.reminderTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "用药提醒")
            content.body = medication.dosage.isEmpty
                ? String(format: String(localized: "该服用「%@」了"), medication.name)
                : String(format: String(localized: "该服用「%@」了：%@"), medication.name, medication.dosage)
            content.sound = .default
            content.interruptionLevel = .timeSensitive

            var components = calendar.dateComponents([.hour, .minute], from: time)
            components.second = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let identifier = Self.identifier(for: medication, index: index)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error {
                    print("排程通知失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 撤销一条用药计划的全部通知。
    func cancel(for medication: Medication) {
        // 单条计划上限给足，覆盖历史排程。
        let identifiers = (0..<20).map { Self.identifier(for: medication, index: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// 撤销所有待发通知。
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// 依据多条计划批量重排（如权限刚被授予时）。
    func rescheduleAll(_ medications: [Medication]) {
        for med in medications { schedule(for: med) }
    }

    private static func identifier(for medication: Medication, index: Int) -> String {
        "med-\(medication.id.uuidString)-\(index)"
    }
}
