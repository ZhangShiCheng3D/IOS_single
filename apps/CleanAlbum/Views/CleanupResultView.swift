//
//  CleanupResultView.swift
//  CleanAlbum
//
//  清理完成后的成果页：删除数量 + 释放空间 + 前后容量对比。
//

import SwiftUI

struct CleanupResultView: View {
    let deletedCount: Int
    let freedBytes: Int64
    let storageBefore: (total: Int64, free: Int64)

    @Environment(\.dismiss) private var dismiss

    /// 预计清理后可用空间。
    ///
    /// 说明：删除的照片会先进入系统"最近删除"相簿（30 天可恢复），
    /// 因此设备实际可用空间要等用户清空"最近删除"后才真正增加。
    /// 直接读取此刻的设备可用容量会几乎不变、与"已释放"指标矛盾，
    /// 故这里展示基于照片体积的**预计**可用空间，并以脚注说明，保证诚实不夸大。
    private var projectedFree: Int64 { storageBefore.free + freedBytes }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    successIcon
                    headline
                    metrics
                    comparison
                    doneButton
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 110, height: 110)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
        }
        .padding(.top, 20)
    }

    private var headline: some View {
        VStack(spacing: 8) {
            Text("result.title")
                .font(.title.bold())
            Text("result.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var metrics: some View {
        HStack(spacing: 16) {
            metricCard(value: "\(deletedCount)", labelKey: "result.deleted", icon: "trash.fill")
            metricCard(value: freedBytes.readableSize, labelKey: "result.freed", icon: "internaldrive.fill")
        }
    }

    private func metricCard(value: String, labelKey: LocalizedStringKey, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.brand)
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(labelKey)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var comparison: some View {
        VStack(spacing: 14) {
            Text("result.comparison")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            comparisonRow(labelKey: "result.before", value: storageBefore.free.readableSize, highlight: false)
            Image(systemName: "arrow.down")
                .foregroundStyle(.secondary)
            comparisonRow(labelKey: "result.after", value: projectedFree.readableSize, highlight: true)

            Text("result.recentlyDeleted.note")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardSurface()
    }

    private func comparisonRow(labelKey: LocalizedStringKey, value: String, highlight: Bool) -> some View {
        HStack {
            Text(labelKey)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(highlight ? Color.green : .primary)
        }
    }

    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            Text("action.done")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(Color.brand)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    CleanupResultView(
        deletedCount: 42,
        freedBytes: 1_800_000_000,
        storageBefore: (128_000_000_000, 16_000_000_000)
    )
}
