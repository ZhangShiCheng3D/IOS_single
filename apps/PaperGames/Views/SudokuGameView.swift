//
//  SudokuGameView.swift
//  PaperGames
//
//  数独对局主界面。整合盘面、控制条、数字键盘、计时、暂停、
//  完成结算，并将成绩写入 SwiftData。
//

import SwiftUI
import SwiftData

struct SudokuGameView: View {
    let difficulty: Difficulty

    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    /// 异步生成谜题；生成完成前为 nil。
    @State private var viewModel: SudokuViewModel?
    @State private var showCompletion = false
    @State private var bestSeconds: Int?

    /// 查询该难度的历史记录用于显示最佳成绩。
    @Query private var records: [GameRecord]

    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        let raw = difficulty.rawValue
        // 仅查询数独 + 当前难度的记录。
        _records = Query(
            filter: #Predicate<GameRecord> { record in
                record.gameTypeRaw == "sudoku" && record.difficultyRaw == raw
            },
            sort: \.durationSeconds
        )
    }

    var body: some View {
        Group {
            if let viewModel {
                gameContent(viewModel)
            } else {
                loadingView
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(difficulty.titleKey)
        .navigationBarTitleDisplayMode(.inline)
        .task { await generateIfNeeded() }
        .onDisappear { viewModel?.stopTimer() }
        .onChange(of: scenePhase) { _, phase in
            // 进入后台自动暂停计时。
            if phase != .active { viewModel?.togglePauseIfRunning(pause: true) }
        }
    }

    // MARK: - 加载

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("sudoku.generating")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func generateIfNeeded() async {
        guard viewModel == nil else {
            viewModel?.startTimer()
            return
        }
        // 在后台线程生成，避免阻塞主线程（地狱难度挖空较耗时）。
        let puzzle = await Task.detached(priority: .userInitiated) {
            SudokuGenerator.generate(difficulty: difficulty)
        }.value
        let vm = SudokuViewModel(puzzle: puzzle)
        vm.reevaluateErrors(settings: settings)
        viewModel = vm
        vm.startTimer()
    }

    // MARK: - 游戏主体

    private func gameContent(_ vm: SudokuViewModel) -> some View {
        VStack(spacing: 16) {
            statusBar(vm)

            SudokuBoardView(viewModel: vm)
                .padding(.horizontal)
                .overlay { if vm.isPaused { pauseOverlay(vm) } }

            controlBar(vm)
                .padding(.horizontal)

            NumberPadView(viewModel: vm)
                .padding(.horizontal)
                .disabled(vm.isPaused || vm.isComplete)

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.togglePause()
                } label: {
                    Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
                }
                .accessibilityLabel(Text(vm.isPaused ? "sudoku.resume" : "sudoku.pause"))
            }
        }
        .onChange(of: vm.isComplete) { _, complete in
            if complete {
                saveRecord(vm)
                showCompletion = true
            }
        }
        .sheet(isPresented: $showCompletion) {
            SudokuCompletionView(
                difficulty: difficulty,
                seconds: vm.elapsedSeconds,
                mistakes: vm.mistakeCount,
                isNewBest: isNewBest(vm.elapsedSeconds),
                onNewGame: { startNewGame() },
                onHome: { dismiss() }
            )
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
    }

    // MARK: - 状态栏

    private func statusBar(_ vm: SudokuViewModel) -> some View {
        HStack {
            statusItem(symbol: "clock", text: vm.formattedTime)
            Spacer()
            statusItem(
                symbol: "xmark.circle",
                text: settings.mistakeHighlight ? "\(vm.mistakeCount)" : "—",
                tint: vm.mistakeCount > 0 ? .red : .secondary
            )
            Spacer()
            if let best = bestSeconds {
                statusItem(symbol: "trophy", text: GameRecord.format(seconds: best), tint: .yellow)
            } else {
                statusItem(symbol: "trophy", text: "—")
            }
        }
        .padding(.horizontal)
        .onAppear { bestSeconds = records.first?.durationSeconds }
    }

    private func statusItem(symbol: String, text: String, tint: Color = .secondary) -> some View {
        Label(text, systemImage: symbol)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(tint)
    }

    // MARK: - 控制条

    private func controlBar(_ vm: SudokuViewModel) -> some View {
        HStack(spacing: 12) {
            controlButton(symbol: "arrow.uturn.backward", titleKey: "sudoku.undo", enabled: vm.canUndo) {
                vm.undo()
            }
            controlButton(symbol: "eraser", titleKey: "sudoku.erase") {
                vm.erase()
            }
            controlButton(
                symbol: vm.isNotesMode ? "pencil.circle.fill" : "pencil.circle",
                titleKey: "sudoku.notes",
                highlighted: vm.isNotesMode
            ) {
                vm.isNotesMode.toggle()
                Haptics.tap()
            }
            controlButton(symbol: "lightbulb", titleKey: "sudoku.hint") {
                vm.hint(settings: settings)
            }
        }
    }

    private func controlButton(
        symbol: String,
        titleKey: LocalizedStringKey,
        enabled: Bool = true,
        highlighted: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.title3)
                Text(titleKey)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(highlighted ? Color.white : Color.appAccent)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(highlighted ? Color.appAccent : Color.appSurface)
            )
        }
        .buttonStyle(.pressable)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    // MARK: - 暂停遮罩

    private func pauseOverlay(_ vm: SudokuViewModel) -> some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            VStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.appAccent)
                Text("sudoku.paused")
                    .font(.headline)
                Button("sudoku.resume") { vm.togglePause() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - 数据

    private func isNewBest(_ seconds: Int) -> Bool {
        guard let best = bestSeconds else { return true }
        return seconds < best
    }

    private func saveRecord(_ vm: SudokuViewModel) {
        let record = GameRecord(
            gameType: .sudoku,
            difficulty: difficulty,
            durationSeconds: vm.elapsedSeconds,
            mistakes: vm.mistakeCount,
            usedNotes: vm.usedNotesThisGame
        )
        modelContext.insert(record)
        try? modelContext.save()
        if isNewBest(vm.elapsedSeconds) { bestSeconds = vm.elapsedSeconds }
    }

    private func startNewGame() {
        showCompletion = false
        viewModel = nil
        bestSeconds = records.first?.durationSeconds
        Task { await generateIfNeeded() }
    }
}

// MARK: - 暂停辅助

private extension SudokuViewModel {
    /// 仅在计时进行中按需暂停（避免覆盖已暂停状态）。
    func togglePauseIfRunning(pause: Bool) {
        if pause, !isPaused, !isComplete { togglePause() }
    }
}

#Preview {
    NavigationStack {
        SudokuGameView(difficulty: .easy)
            .environment(SettingsStore())
            .environment(PurchaseManager())
            .modelContainer(for: GameRecord.self, inMemory: true)
    }
}
