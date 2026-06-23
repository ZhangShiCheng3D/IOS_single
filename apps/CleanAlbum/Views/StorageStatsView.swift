//
//  StorageStatsView.swift
//  CleanAlbum
//
//  设备存储概览卡片：环形进度 + 可释放空间。
//

import SwiftUI

struct StorageStatsView: View {
    let total: Int64
    let free: Int64
    /// 本次扫描可释放的空间。
    let reclaimable: Int64

    private var used: Int64 { max(0, total - free) }
    private var usedFraction: Double {
        total > 0 ? Double(used) / Double(total) : 0
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                ring
                stats
            }
            if reclaimable > 0 {
                reclaimableBanner
            }
        }
        .cardSurface()
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.brand.opacity(0.15), lineWidth: 12)
            Circle()
                .trim(from: 0, to: usedFraction)
                .stroke(
                    LinearGradient(colors: [.brand, .brand.opacity(0.6)],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int(usedFraction * 100))%")
                    .font(.title2.bold())
                    .monospacedDigit()
                Text("storage.used")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 100, height: 100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("storage.used"))
        .accessibilityValue(Text("\(Int(usedFraction * 100))%"))
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 12) {
            statRow(labelKey: "storage.total", value: total.readableSize, color: .secondary)
            statRow(labelKey: "storage.free", value: free.readableSize, color: .green)
            statRow(labelKey: "storage.usedLabel", value: used.readableSize, color: .brand)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statRow(labelKey: LocalizedStringKey, value: String, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(labelKey)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }

    private var reclaimableBanner: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.brand)
            Text("storage.reclaimable")
                .font(.subheadline)
            Spacer()
            Text(reclaimable.readableSize)
                .font(.subheadline.bold())
                .foregroundStyle(Color.brand)
                .monospacedDigit()
        }
        .padding(12)
        .background(Color.brand.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StorageStatsView(
        total: 128_000_000_000,
        free: 18_000_000_000,
        reclaimable: 2_400_000_000
    )
    .padding()
}
