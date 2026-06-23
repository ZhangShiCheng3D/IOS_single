//
//  MedicationViewModel.swift
//  SeniorHelper
//
//  用药提醒业务逻辑：增删改、照片存取、通知排程。
//  View 通过 SwiftData 的 @Query 读取列表，本 VM 负责写操作与副作用。
//

import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class MedicationViewModel {

    let notificationManager = NotificationManager()

    /// 新增或保存一条用药计划。
    /// - Parameters:
    ///   - context: SwiftData 上下文。
    ///   - existing: 编辑时传入既有对象；新增时为 nil。
    func save(
        in context: ModelContext,
        existing: Medication?,
        name: String,
        dosage: String,
        times: [Date],
        isEnabled: Bool,
        newImage: UIImage?,
        removePhoto: Bool
    ) {
        let medication: Medication
        if let existing {
            medication = existing
            medication.name = name
            medication.dosage = dosage
            medication.reminderTimes = times
            medication.isEnabled = isEnabled
        } else {
            medication = Medication(
                name: name,
                dosage: dosage,
                reminderTimes: times,
                isEnabled: isEnabled
            )
            context.insert(medication)
        }

        // 处理照片变更。
        if removePhoto {
            ImageStore.delete(medication.photoFileName)
            medication.photoFileName = nil
        }
        if let newImage {
            ImageStore.delete(medication.photoFileName) // 替换旧图
            medication.photoFileName = ImageStore.save(newImage)
        }

        try? context.save()

        // 重新排程通知。
        notificationManager.schedule(for: medication)
        Haptics.success()
    }

    /// 删除一条计划：撤销通知、删除照片、移除记录。
    func delete(_ medication: Medication, in context: ModelContext) {
        notificationManager.cancel(for: medication)
        ImageStore.delete(medication.photoFileName)
        context.delete(medication)
        try? context.save()
    }

    /// 切换启用状态并即时生效。
    func toggleEnabled(_ medication: Medication, in context: ModelContext) {
        medication.isEnabled.toggle()
        try? context.save()
        notificationManager.schedule(for: medication)
        Haptics.tap()
    }

    /// 确保通知权限；未授权时申请。返回是否可用。
    @discardableResult
    func ensureNotificationPermission() async -> Bool {
        await notificationManager.refreshStatus()
        switch notificationManager.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return await notificationManager.requestAuthorization()
        default:
            return false
        }
    }
}
