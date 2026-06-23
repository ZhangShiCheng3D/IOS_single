//
//  BubbleWrapView.swift
//  CalmBox
//
//  泡泡纸：拖动或点击屏幕捏破泡泡，伴随清脆音效与细腻震动。
//

import SwiftUI

struct BubbleWrapView: View {

    @Environment(HapticManager.self) private var haptics
    @State private var viewModel = BubbleWrapViewModel(columns: 6, rows: 11)
    /// 已通过滑动经过的泡泡，避免拖动时重复触发。
    @State private var draggedThisGesture: Set<Int> = []

    var body: some View {
        VStack(spacing: 16) {
            progressBar

            GeometryReader { geo in
                let spacing: CGFloat = 8
                let totalSpacing = spacing * CGFloat(viewModel.columns - 1)
                let bubbleSize = (geo.size.width - totalSpacing) / CGFloat(viewModel.columns)

                bubbleGrid(bubbleSize: bubbleSize, spacing: spacing)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(bubbleSize: bubbleSize, spacing: spacing, width: geo.size.width))
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .navigationTitle("scene.bubble.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    haptics.playSelection()
                    withAnimation(.spring) { viewModel.reset() }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("bubble.reset")
                .disabled(viewModel.poppedCount == 0)
            }
        }
        .sceneBackground(.bubbleWrap)
    }

    // MARK: - 子视图

    private var progressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("bubble.popped \(viewModel.poppedCount)")
                    .font(.subheadline.weight(.medium))
                Spacer()
                if viewModel.allPopped {
                    Label("bubble.allDone", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
            ProgressView(value: Double(viewModel.poppedCount), total: Double(viewModel.bubbles.count))
                .tint(Theme.Scene.accent(.bubbleWrap))
        }
    }

    private func bubbleGrid(bubbleSize: CGFloat, spacing: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.fixed(bubbleSize), spacing: spacing), count: viewModel.columns)
        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(viewModel.bubbles) { bubble in
                BubbleCell(isPopped: bubble.isPopped, size: bubbleSize)
                    .onTapGesture {
                        pop(bubble.id)
                    }
            }
        }
    }

    // MARK: - 手势

    /// 拖动经过泡泡时连续捏破。
    private func dragGesture(bubbleSize: CGFloat, spacing: CGFloat, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let cell = bubbleSize + spacing
                let col = Int(value.location.x / cell)
                let row = Int(value.location.y / cell)
                guard col >= 0, col < viewModel.columns, row >= 0 else { return }
                let index = row * viewModel.columns + col
                guard index < viewModel.bubbles.count, !draggedThisGesture.contains(index) else { return }
                draggedThisGesture.insert(index)
                pop(index)
            }
            .onEnded { _ in
                draggedThisGesture.removeAll()
            }
    }

    private func pop(_ id: Int) {
        if viewModel.pop(id) {
            haptics.playBubblePop()
            SoundEffectPlayer.shared.play(.bubblePop)
            if viewModel.allPopped {
                haptics.playSuccess()
            }
        }
    }
}

// MARK: - 单个泡泡视图

private struct BubbleCell: View {
    let isPopped: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            if isPopped {
                // 破裂后的凹陷效果。
                Circle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Circle().stroke(Color(.systemGray3), lineWidth: 1)
                    )
                    .scaleEffect(0.85)
            } else {
                // 凸起的泡泡，带高光。
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.95), Color(hex: "#86A8E7")],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: size
                        )
                    )
                    .overlay(
                        Circle()
                            .fill(.white.opacity(0.5))
                            .frame(width: size * 0.25, height: size * 0.25)
                            .offset(x: -size * 0.18, y: -size * 0.18)
                    )
                    .shadow(color: Color(hex: "#7F7FD5").opacity(0.4), radius: 2, y: 2)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isPopped)
    }
}

#Preview {
    NavigationStack {
        BubbleWrapView()
            .environment(HapticManager())
    }
}
