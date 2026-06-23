//
//  FastingLiveActivity.swift
//  FastFlowWidget
//
//  断食 Live Activity：锁屏卡片 + 灵动岛（紧凑/最小/展开）。
//  使用 Text(timerInterval:) 与 ProgressView(timerInterval:) 实现自动走时，无需推送更新。
//

import SwiftUI
import WidgetKit
import ActivityKit

struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activitySystemActionForegroundColor(.accentColor)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开态。
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.planName, systemImage: "timer")
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    statusBadge(reached: context.state.hasReachedGoal)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(timerRange(context))
                        .font(.system(.title2, design: .rounded).bold())
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(timerInterval: context.state.timerRange, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .tint(context.state.hasReachedGoal ? .green : .accentColor)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(Color.accentColor)
            } compactTrailing: {
                Text(timerInterval: context.state.timerRange, countsDown: false)
                    .monospacedDigit()
                    .frame(maxWidth: 56)
                    .multilineTextAlignment(.trailing)
            } minimal: {
                Image(systemName: context.state.hasReachedGoal ? "checkmark.circle.fill" : "timer")
                    .foregroundStyle(context.state.hasReachedGoal ? .green : .accentColor)
            }
            .keylineTint(.accentColor)
        }
    }

    // MARK: - 锁屏卡片

    private func lockScreenView(context: ActivityViewContext<FastingActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label(context.state.planName, systemImage: "timer")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
                Text(timerRange(context))
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .monospacedDigit()
                ProgressView(timerInterval: context.state.timerRange, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(context.state.hasReachedGoal ? .green : .accentColor)
            }
            Spacer()
            statusBadge(reached: context.state.hasReachedGoal)
        }
        .padding()
    }

    private func statusBadge(reached: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: reached ? "checkmark.seal.fill" : "hourglass")
                .font(.title2)
                .foregroundStyle(reached ? Color.green : Color.accentColor)
            Text(reached ? "live.reached" : "live.fasting")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// 计时显示文本（系统自动走时，从开始计起向上累加）。
    private func timerRange(_ context: ActivityViewContext<FastingActivityAttributes>) -> Text {
        Text(timerInterval: context.state.timerRange, countsDown: false)
    }
}
