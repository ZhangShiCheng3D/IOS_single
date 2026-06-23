//
//  DesignSystem.swift
//  CollageKit
//
//  集中管理的设计令牌：圆角、触觉反馈、主按钮样式。
//  统一全局视觉语言，避免在各视图重复硬编码相同的外观参数。
//

import SwiftUI
import UIKit

enum DesignSystem {

    /// 统一圆角半径（点）。
    enum Radius {
        static let card: CGFloat = 14
        static let button: CGFloat = 16
    }

    /// 触觉反馈封装。仅在主线程的用户操作中调用。
    @MainActor
    enum Haptics {
        /// 成功（购买完成、保存到相册）。
        static func success() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        /// 轻量选择变化（切换模板、选色）。
        static func selection() {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        /// 触感冲击（删除等较重操作）。
        static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
}

// MARK: - 按钮样式

/// 主操作按钮：填充强调色、白字、统一圆角，带按压与禁用反馈。
struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, height: height)
    }

    private struct StyledBody: View {
        let configuration: ButtonStyleConfiguration
        let height: CGFloat
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Color.accentColor,
                            in: RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))
                .shadow(color: Color.accentColor.opacity(isEnabled ? 0.28 : 0), radius: 10, y: 4)
                .opacity(isEnabled ? (configuration.isPressed ? 0.88 : 1) : 0.5)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

/// 次要操作按钮：浅色表面、主色文字，带按压与禁用反馈。
struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, height: height)
    }

    private struct StyledBody: View {
        let configuration: ButtonStyleConfiguration
        let height: CGFloat
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))
                .opacity(isEnabled ? (configuration.isPressed ? 0.88 : 1) : 0.5)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}
