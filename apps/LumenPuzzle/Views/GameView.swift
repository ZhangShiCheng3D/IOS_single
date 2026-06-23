//
//  GameView.swift
//  LumenPuzzle
//
//  单关游玩界面：全屏 3D 解谜场景 + 极简 HUD + 通关结算。
//

import SwiftUI
import SwiftData

/// 关卡游玩入口。通过 sessionID 强制重建内部会话以实现"重玩"。
struct GameView: View {
    let level: Level
    @State private var sessionID = UUID()

    var body: some View {
        PuzzleSessionView(level: level, onRestart: { sessionID = UUID() })
            .id(sessionID)
            .navigationBarBackButtonHidden(true)
    }
}

/// 真正持有 GameViewModel 的会话视图。
private struct PuzzleSessionView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: GameViewModel
    let onRestart: () -> Void

    init(level: Level, onRestart: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: GameViewModel(level: level))
        self.onRestart = onRestart
    }

    var body: some View {
        ZStack {
            // 3D 场景。
            PuzzleSceneView(viewModel: viewModel)
                .ignoresSafeArea()

            // HUD。
            VStack {
                topBar
                Spacer()
                if viewModel.showHint {
                    hintCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                bottomBar
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // 通关结算层。
            if viewModel.showCompletion {
                CompletionView(
                    level: viewModel.level,
                    timeText: viewModel.formattedTime,
                    moves: viewModel.moveCount,
                    newAchievements: viewModel.newlyUnlockedAchievements,
                    onReplay: onRestart,
                    onExit: { dismiss() }
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .background(LinearGradient.lumenBackground.ignoresSafeArea())
        .animation(Motion.state, value: viewModel.showCompletion)
        .animation(Motion.soft, value: viewModel.showHint)
        .task {
            viewModel.configure(context: modelContext)
            viewModel.start()
        }
    }

    // MARK: - HUD 组件

    private var topBar: some View {
        HStack {
            Button {
                Haptics.selection()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Color.lumenText)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.lumenSurface.opacity(0.5)))
            }
            .accessibilityLabel(Text("a11y.back"))

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.level.nameKey.asLocalizedKey)
                    .font(.headline)
                    .foregroundStyle(Color.lumenText)
                Text(viewModel.formattedTime)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.lumenTextSecondary)
            }

            Spacer()

            Button {
                Haptics.selection()
                viewModel.showHint.toggle()
            } label: {
                Image(systemName: "lightbulb")
                    .font(.headline)
                    .foregroundStyle(viewModel.showHint ? Color.lumenAccent : Color.lumenText)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.lumenSurface.opacity(0.5)))
            }
            .accessibilityLabel(Text("a11y.hint"))
        }
        .padding(.top, 8)
    }

    private var hintCard: some View {
        Text(viewModel.level.hintKey.asLocalizedKey)
            .font(.callout)
            .foregroundStyle(Color.lumenText)
            .multilineTextAlignment(.center)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.bottom, 12)
    }

    private var bottomBar: some View {
        HStack(spacing: 14) {
            // 点亮进度。
            Label {
                Text("\(viewModel.litCount)/\(viewModel.totalCount)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            } icon: {
                Image(systemName: "sun.max.fill")
            }
            .foregroundStyle(Color.lumenAccent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.lumenSurface.opacity(0.5)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("a11y.progress \(viewModel.litCount) \(viewModel.totalCount)"))

            // 步数。
            Label {
                Text("\(viewModel.moveCount)")
                    .font(.subheadline.monospacedDigit())
            } icon: {
                Image(systemName: "hand.draw")
            }
            .foregroundStyle(Color.lumenTextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.lumenSurface.opacity(0.4)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("a11y.moves \(viewModel.moveCount)"))

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        GameView(level: LevelCatalog.level1)
            .environmentObject(PurchaseManager())
            .modelContainer(for: [LevelProgress.self, AchievementRecord.self], inMemory: true)
    }
}
