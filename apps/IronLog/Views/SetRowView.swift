//
//  SetRowView.swift
//  IronLog
//
//  单组录入行。为极速录入优化：直接键入数字 + 点按步进，
//  勾选完成时启动休息计时并触发 PR 评估（行内绿色高亮一次）。
//

import SwiftUI

struct SetRowView: View {
    @Bindable var set: SetEntry
    let displayIndex: Int

    @EnvironmentObject private var activeWorkout: ActiveWorkoutViewModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var restTimer: RestTimerViewModel

    @FocusState private var focusedField: Field?
    @State private var prFlash = false

    private enum Field { case weight, reps }

    var body: some View {
        HStack(spacing: 8) {
            // 组号 / 热身标记（点按切换热身）
            Button {
                set.isWarmup.toggle()
            } label: {
                if set.isWarmup {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 36)
                } else {
                    Text("\(displayIndex)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 36)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(set.isWarmup ? "set.warmup" : "set.working"))

            // 重量输入 + 步进
            HStack(spacing: 4) {
                TextField("0", value: weightBinding, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 44)
                    .focused($focusedField, equals: .weight)
                    .font(.body.weight(.semibold).monospacedDigit())
                    .accessibilityLabel(Text("set.col.weight"))
                Text(settings.weightUnit.symbol)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Stepper("", value: weightBinding, step: settings.weightUnit.increment)
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
            .frame(maxWidth: .infinity)

            // 次数输入
            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 64)
                .focused($focusedField, equals: .reps)
                .font(.body.weight(.semibold).monospacedDigit())
                .accessibilityLabel(Text("set.col.reps"))

            // RPE 菜单
            Menu {
                Button("set.rpe.none") { set.rpe = 0 }
                ForEach(Array(stride(from: 6.0, through: 10.0, by: 0.5)), id: \.self) { value in
                    Button(Fmt.weight(value)) { set.rpe = value }
                }
            } label: {
                Text(set.rpe > 0 ? Fmt.weight(set.rpe) : "–")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(set.rpe > 0 ? Color.ironAccent : .secondary)
                    .frame(width: 52)
            }
            .accessibilityLabel(Text("set.col.rpe"))
            .accessibilityValue(Text(set.rpe > 0 ? Fmt.weight(set.rpe) : String(localized: "set.rpe.none")))

            // 完成勾选
            Button {
                complete()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 28)
            .accessibilityLabel(Text("set.complete"))
            .accessibilityValue(Text(set.isCompleted ? "set.completed" : "set.incomplete"))
        }
        .listRowBackground(rowBackground)
        .animation(.easeOut(duration: 0.3), value: set.isCompleted)
    }

    /// 重量绑定：内部公斤 <-> 显示单位换算。
    private var weightBinding: Binding<Double> {
        Binding(
            get: { settings.weightUnit.display(fromKg: set.weight) },
            set: { set.weight = settings.weightUnit.toKg($0) }
        )
    }

    /// 完成时的行背景（PR 闪一下金色，否则完成态淡绿）。
    private var rowBackground: some View {
        Group {
            if prFlash {
                Color.yellow.opacity(0.25)
            } else if set.isCompleted {
                Color.green.opacity(0.08)
            } else {
                Color(.secondarySystemGroupedBackground)
            }
        }
    }

    private func complete() {
        focusedField = nil
        let wasCompleted = set.isCompleted
        activeWorkout.toggleComplete(set)

        guard set.isCompleted, !wasCompleted else { return }

        // 触觉反馈
        Haptics.impact()

        // 自动启动休息计时（非热身组）
        if settings.autoStartRestTimer, !set.isWarmup {
            restTimer.start(seconds: settings.defaultRestSeconds)
        }

        // PR 高亮
        if activeWorkout.lastPRSetID == set.id {
            withAnimation(.easeIn(duration: 0.2)) { prFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.6)) { prFlash = false }
            }
        }
    }
}

#Preview {
    let set = SetEntry(order: 0, weight: 100, reps: 5, rpe: 8, exercise: PreviewData.sampleExercise)
    return List {
        SetRowView(set: set, displayIndex: 1)
    }
    .environmentObject(AppSettings())
    .environmentObject(ActiveWorkoutViewModel())
    .environmentObject(RestTimerViewModel())
    .modelContainer(PreviewData.container)
}
