//
//  SudokuViewModel.swift
//  PaperGames
//
//  数独对局的视图模型（MVVM）。管理盘面状态、选择、笔记、错误、
//  计时、撤销、提示等全部交互逻辑。
//

import SwiftUI
import Observation

@Observable
@MainActor
final class SudokuViewModel {

    // MARK: - 单元格状态

    struct Cell {
        var value: Int               // 当前填入值，0 表示空
        var isGiven: Bool            // 是否为初始线索（不可修改）
        var notes: Set<Int>          // 铅笔笔记（候选数字）
        var isError: Bool            // 是否与解答冲突（错误提示）
    }

    // MARK: - 撤销记录

    private struct Move {
        let index: Int
        let previous: Cell
    }

    // MARK: - 公开状态

    private(set) var puzzle: SudokuPuzzle
    private(set) var cells: [Cell]
    var selectedIndex: Int?
    var isNotesMode = false
    private(set) var mistakeCount = 0
    private(set) var elapsedSeconds = 0
    private(set) var isComplete = false
    private(set) var isPaused = false
    private(set) var usedNotesThisGame = false
    private(set) var hintsUsed = 0

    let difficulty: Difficulty

    private var undoStack: [Move] = []
    /// 计时任务。基于结构化并发，避免 Timer 在 Swift 6 严格并发下的 Sendable 问题。
    /// 标注 nonisolated(unsafe) 以便在非隔离的 deinit 中安全取消（Task.cancel 本身线程安全）。
    private nonisolated(unsafe) var timerTask: Task<Void, Never>?

    // MARK: - 初始化

    init(puzzle: SudokuPuzzle) {
        self.puzzle = puzzle
        self.difficulty = puzzle.difficulty
        self.cells = puzzle.givens.map { value in
            Cell(value: value, isGiven: value != 0, notes: [], isError: false)
        }
    }

    /// 便捷构造：直接按难度生成新谜题。
    convenience init(difficulty: Difficulty) {
        self.init(puzzle: SudokuGenerator.generate(difficulty: difficulty))
    }

    deinit {
        // Task 是 Sendable，可在非隔离的 deinit 中安全取消。
        timerTask?.cancel()
    }

    // MARK: - 计时

    func startTimer() {
        guard timerTask == nil, !isComplete else { return }
        isPaused = false
        // Task 在 @MainActor 上下文创建，继承主actor隔离，访问状态安全。
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                if !self.isPaused && !self.isComplete {
                    self.elapsedSeconds += 1
                }
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    func togglePause() {
        isPaused.toggle()
    }

    // MARK: - 交互

    /// 选中某个单元格。
    func select(_ index: Int) {
        guard (0..<81).contains(index) else { return }
        selectedIndex = (selectedIndex == index) ? nil : index
    }

    /// 在当前选中格输入数字（或切换笔记）。
    /// - Parameters:
    ///   - number: 1...9
    ///   - settings: 全局设置（错误提示、自动清笔记等）
    func input(_ number: Int, settings: SettingsStore) {
        guard let index = selectedIndex, (1...9).contains(number) else { return }
        guard !cells[index].isGiven, !isComplete else { return }

        recordUndo(at: index)

        if isNotesMode {
            // 笔记模式：切换候选数字。
            usedNotesThisGame = true
            if cells[index].notes.contains(number) {
                cells[index].notes.remove(number)
            } else {
                cells[index].notes.insert(number)
            }
            cells[index].value = 0
            cells[index].isError = false
        } else {
            // 正常填入。
            if cells[index].value == number {
                // 再次点击相同数字 -> 擦除。
                cells[index].value = 0
                cells[index].isError = false
            } else {
                cells[index].value = number
                cells[index].notes.removeAll()
                evaluateError(at: index, settings: settings)
                if settings.autoNotesRemoval { removeNotesForPeers(of: index, number: number) }

                if cells[index].isError {
                    mistakeCount += 1
                    Haptics.error()
                } else {
                    Haptics.place()
                }
                checkCompletion()
            }
        }
    }

    /// 擦除当前选中格。
    func erase() {
        guard let index = selectedIndex else { return }
        guard !cells[index].isGiven, !isComplete else { return }
        recordUndo(at: index)
        cells[index].value = 0
        cells[index].notes.removeAll()
        cells[index].isError = false
    }

    /// 撤销上一步。
    func undo() {
        guard let move = undoStack.popLast() else { return }
        cells[move.index] = move.previous
        selectedIndex = move.index
        checkCompletion()
    }

    var canUndo: Bool { !undoStack.isEmpty }

    /// 提示：在当前选中的空格填入正确答案。无选中则自动选一个空格。
    func hint(settings: SettingsStore) {
        let target: Int? = {
            if let index = selectedIndex, cells[index].value == 0, !cells[index].isGiven {
                return index
            }
            return cells.indices.first { cells[$0].value == 0 && !cells[$0].isGiven }
        }()
        guard let index = target else { return }

        recordUndo(at: index)
        selectedIndex = index
        cells[index].value = puzzle.solution[index]
        cells[index].notes.removeAll()
        cells[index].isError = false
        hintsUsed += 1
        Haptics.success()
        if settings.autoNotesRemoval {
            removeNotesForPeers(of: index, number: puzzle.solution[index])
        }
        checkCompletion()
    }

    // MARK: - 错误评估

    private func evaluateError(at index: Int, settings: SettingsStore) {
        guard settings.mistakeHighlight else {
            cells[index].isError = false
            return
        }
        cells[index].isError = cells[index].value != 0
            && cells[index].value != puzzle.solution[index]
    }

    /// 当用户改变错误提示设置时，重新评估全盘。
    func reevaluateErrors(settings: SettingsStore) {
        for index in cells.indices where !cells[index].isGiven {
            if settings.mistakeHighlight {
                cells[index].isError = cells[index].value != 0
                    && cells[index].value != puzzle.solution[index]
            } else {
                cells[index].isError = false
            }
        }
    }

    // MARK: - 完成判定

    private func checkCompletion() {
        let filled = cells.allSatisfy { $0.value != 0 }
        guard filled else { isComplete = false; return }
        let correct = cells.indices.allSatisfy { cells[$0].value == puzzle.solution[$0] }
        if correct {
            isComplete = true
            stopTimer()
            Haptics.success()
        }
    }

    // MARK: - 辅助

    /// 记录某格当前状态以便撤销。
    private func recordUndo(at index: Int) {
        undoStack.append(Move(index: index, previous: cells[index]))
        // 限制撤销栈长度，避免无限增长。
        if undoStack.count > 200 { undoStack.removeFirst(undoStack.count - 200) }
    }

    /// 在同行/列/宫的笔记中移除已确定的数字。
    private func removeNotesForPeers(of index: Int, number: Int) {
        for peer in peers(of: index) {
            cells[peer].notes.remove(number)
        }
    }

    /// 返回与某格同行、同列、同宫的所有单元格索引。
    func peers(of index: Int) -> [Int] {
        let row = index / 9
        let col = index % 9
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        var result = Set<Int>()
        for i in 0..<9 {
            result.insert(row * 9 + i)
            result.insert(i * 9 + col)
            result.insert((boxRow + i / 3) * 9 + (boxCol + i % 3))
        }
        result.remove(index)
        return Array(result)
    }

    /// 某个数字在盘面上已正确填入的个数（用于数字键盘显示剩余数量）。
    func remainingCount(for number: Int) -> Int {
        let placed = cells.filter { $0.value == number }.count
        return max(0, 9 - placed)
    }

    /// 是否为同行/列/宫的关联格（用于高亮）。
    func isPeer(of base: Int, index: Int) -> Bool {
        guard base != index else { return false }
        return SudokuPuzzle.row(of: base) == SudokuPuzzle.row(of: index)
            || SudokuPuzzle.col(of: base) == SudokuPuzzle.col(of: index)
            || SudokuPuzzle.box(of: base) == SudokuPuzzle.box(of: index)
    }

    /// 进度（0...1）。
    var progress: Double {
        let editable = cells.filter { !$0.isGiven }
        guard !editable.isEmpty else { return 1 }
        let done = editable.filter { $0.value != 0 }.count
        return Double(done) / Double(editable.count)
    }

    var formattedTime: String { GameRecord.format(seconds: elapsedSeconds) }
}
