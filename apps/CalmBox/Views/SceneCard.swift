//
//  SceneCard.swift
//  CalmBox
//
//  主页场景卡片：渐变背景、图标、标题、收藏与锁定标记。
//

import SwiftUI

struct SceneCard: View {
    let scene: RelaxScene
    let isLocked: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                background

                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: scene.systemImage)
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                    Spacer()

                    Text(scene.titleKey)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(scene.subtitleKey)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)

                topMarkers
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadius))
            .cardShadow(scene.accent)
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(scene.displayTitle)
        .accessibilityHint(scene.displaySubtitle)
        .accessibilityValue(isLocked ? Text("a11y.locked") : Text(""))
        .accessibilityAddTraits(.isButton)
    }

    private var background: some View {
        LinearGradient(
            colors: scene.gradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var topMarkers: some View {
        HStack(spacing: 8) {
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(.black.opacity(0.25), in: Circle())
            }
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.caption)
                    .foregroundStyle(isFavorite ? .pink : .white)
                    .padding(7)
                    .background(.black.opacity(0.25), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(10)
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(RelaxScene.catalog) { scene in
                SceneCard(
                    scene: scene,
                    isLocked: scene.isPremium,
                    isFavorite: scene.id == "bubble",
                    onTap: {},
                    onToggleFavorite: {}
                )
            }
        }
        .padding()
    }
}
