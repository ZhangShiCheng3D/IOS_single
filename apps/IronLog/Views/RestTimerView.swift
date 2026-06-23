//
//  RestTimerView.swift
//  IronLog
//
//  休息计时器：底部悬浮条（RestTimerBar）+ 全屏环形大计时（RestTimerSheet）。
//

import SwiftUI

/// 悬浮于标签栏上方的精简休息条。
struct RestTimerBar: View {
    @EnvironmentObject private var restTimer: RestTimerViewModel
    @State private var showFullScreen = false

    var body: some View {
        HStack(spacing: 14) {
            // 进度环 + 剩余时间
            ZStack {
                Circle()
                    .stroke(Color.ironAccent.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: restTimer.progress)
                    .stroke(Color.ironAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(Color.ironAccent)
            }
            .frame(width: 34, height: 34)
            .animation(.linear(duration: 0.2), value: restTimer.progress)

            VStack(alignment: .leading, spacing: 1) {
                Text("rest.title")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(Fmt.timer(restTimer.remaining))
                    .font(.title3.monospacedDigit().weight(.bold))
                    .contentTransition(.numericText())
            }

            Spacer()

            Button("-15") { restTimer.adjust(by: -15) }
                .buttonStyle(.bordered)
                .controlSize(.small)
            Button("+15") { restTimer.adjust(by: 15) }
                .buttonStyle(.bordered)
                .controlSize(.small)
            Button {
                restTimer.stop()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(Text("rest.skip"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .floatingShadow()
        .contentShape(Rectangle())
        .onTapGesture { showFullScreen = true }
        .sheet(isPresented: $showFullScreen) {
            RestTimerSheet()
        }
    }
}

/// 全屏休息计时（点击悬浮条展开）。
struct RestTimerSheet: View {
    @EnvironmentObject private var restTimer: RestTimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 40) {
            Text("rest.title")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, 40)

            ZStack {
                Circle()
                    .stroke(Color.ironAccent.opacity(0.15), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: restTimer.progress)
                    .stroke(Color.ironAccent, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: restTimer.progress)
                Text(Fmt.timer(restTimer.remaining))
                    .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())
            }
            .frame(width: 260, height: 260)

            HStack(spacing: 20) {
                Button {
                    restTimer.adjust(by: -15)
                } label: {
                    Label("-15", systemImage: "minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    restTimer.adjust(by: 15)
                } label: {
                    Label("+15", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 40)

            Button {
                restTimer.stop()
                dismiss()
            } label: {
                Text("rest.skip")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)

            Spacer()
        }
        .tint(.ironAccent)
        .presentationDetents([.medium, .large])
        .onChange(of: restTimer.isRunning) { _, running in
            if !running { dismiss() }
        }
    }
}

#Preview {
    let vm = RestTimerViewModel()
    vm.start(seconds: 90)
    return VStack {
        Spacer()
        RestTimerBar()
            .environmentObject(vm)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
