//
//  ScanProgressView.swift
//  CleanAlbum
//
//  扫描进行中的进度展示。
//

import SwiftUI

struct ScanProgressView: View {
    let phase: ScanPhase
    /// 用户点击"取消扫描"的回调。为 nil 时不显示取消按钮。
    var onCancel: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Layout.spacingLG + 4) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.brand.opacity(0.15), lineWidth: 10)
                    .frame(width: 140, height: 140)

                if case .analyzing(let progress) = phase {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.brand, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)
                    Text("\(Int(progress * 100))%")
                        .font(.title.bold())
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .accessibilityLabel(Text(statusKey))
                        .accessibilityValue(Text("\(Int(progress * 100))%"))
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.brand)
                }
            }

            VStack(spacing: Layout.spacingSM) {
                Text(statusKey)
                    .font(.headline)
                Text("scan.privacy.note")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let onCancel {
                Button(role: .cancel) {
                    Haptics.light()
                    onCancel()
                } label: {
                    Text("action.cancelScan")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, Layout.spacingLG)
                        .padding(.vertical, Layout.spacingMD)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .padding(.top, Layout.spacingSM)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }

    private var statusKey: LocalizedStringKey {
        switch phase {
        case .requestingPermission: return "scan.status.permission"
        case .fetching: return "scan.status.fetching"
        case .analyzing: return "scan.status.analyzing"
        case .grouping: return "scan.status.grouping"
        default: return "scan.status.analyzing"
        }
    }
}

#Preview {
    ScanProgressView(phase: .analyzing(progress: 0.62))
}
