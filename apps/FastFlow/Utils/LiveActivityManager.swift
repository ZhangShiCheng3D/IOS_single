//
//  LiveActivityManager.swift
//  FastFlow
//
//  Live Activity 生命周期管理：启动、更新、结束断食实时活动。
//

import Foundation
import ActivityKit

/// 断食 Live Activity 管理器（单例）。
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    /// 当前活动引用。
    private var currentActivity: Activity<FastingActivityAttributes>?

    /// 系统是否允许 Live Activity。
    var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// 启动一个断食 Live Activity。
    func start(startTime: Date, targetEndTime: Date, planName: String) {
        guard isEnabled else { return }
        // 若已有活动先结束，避免重复。
        end()

        let attributes = FastingActivityAttributes(planName: planName)
        let state = FastingActivityAttributes.ContentState(
            startTime: startTime,
            targetEndTime: targetEndTime,
            planName: planName,
            hasReachedGoal: false
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: targetEndTime.addingTimeInterval(3600)),
                pushType: nil
            )
        } catch {
            currentActivity = nil
        }
    }

    /// 更新当前活动状态（如已达成目标）。
    func update(startTime: Date, targetEndTime: Date, planName: String, hasReachedGoal: Bool) async {
        guard let activity = currentActivity else { return }
        let state = FastingActivityAttributes.ContentState(
            startTime: startTime,
            targetEndTime: targetEndTime,
            planName: planName,
            hasReachedGoal: hasReachedGoal
        )
        await activity.update(.init(state: state, staleDate: targetEndTime.addingTimeInterval(3600)))
    }

    /// 结束并移除当前活动。
    func end() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }

    /// App 重启后尝试恢复对已有活动的引用。
    func restoreIfNeeded() {
        if currentActivity == nil {
            currentActivity = Activity<FastingActivityAttributes>.activities.first
        }
    }
}
