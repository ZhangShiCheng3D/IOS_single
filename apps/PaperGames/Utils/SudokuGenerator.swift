//
//  SudokuGenerator.swift
//  PaperGames
//
//  数独生成与求解算法。完全离线、可无限生成保证唯一解的谜题。
//
//  算法概述：
//  1. `generateSolved` 用带随机化的回溯法填出一个完整合法盘面。
//  2. `dig` 在完整盘面上按随机顺序挖空，每挖一格用 `countSolutions`
//     验证仍保持唯一解；若破坏唯一性则还原该格。
//  3. 控制保留的线索数量逼近目标难度。
//
//  正确性可验证：生成结果同时返回 givens（谜题）与 solution（解），
//  并满足「solution 是 givens 的唯一解」。
//

import Foundation

enum SudokuGenerator {

    // MARK: - 对外接口

    /// 生成一道指定难度、保证唯一解的数独谜题。
    static func generate(difficulty: Difficulty) -> SudokuPuzzle {
        let solved = generateSolved()
        let givens = dig(from: solved, targetClues: difficulty.clueCount)
        return SudokuPuzzle(givens: givens, solution: solved, difficulty: difficulty)
    }

    // MARK: - 校验

    /// 检查在 `board` 的 `index` 处放置 `value` 是否符合数独规则。
    /// 注意：调用时 `board[index]` 应为 0（空），或在判断前临时清零。
    static func isValid(_ board: [Int], index: Int, value: Int) -> Bool {
        let row = index / 9
        let col = index % 9
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3

        for i in 0..<9 {
            // 同行
            if board[row * 9 + i] == value { return false }
            // 同列
            if board[i * 9 + col] == value { return false }
            // 同宫
            let r = boxRow + i / 3
            let c = boxCol + i % 3
            if board[r * 9 + c] == value { return false }
        }
        return true
    }

    /// 验证一个完整盘面（无空格）是否为合法解。
    static func isCompleteAndValid(_ board: [Int]) -> Bool {
        guard board.count == 81 else { return false }
        for index in 0..<81 {
            let value = board[index]
            guard (1...9).contains(value) else { return false }
            var temp = board
            temp[index] = 0
            if !isValid(temp, index: index, value: value) { return false }
        }
        return true
    }

    // MARK: - 生成完整解

    /// 用随机化回溯生成一个完整、合法的数独盘面。
    static func generateSolved() -> [Int] {
        var board = [Int](repeating: 0, count: 81)
        _ = fill(&board, from: 0)
        return board
    }

    /// 递归填充：从 `position` 起找到第一个空格并尝试随机数字。
    private static func fill(_ board: inout [Int], from position: Int) -> Bool {
        guard let index = (position..<81).first(where: { board[$0] == 0 }) else {
            return true // 没有空格，完成。
        }
        for value in Array(1...9).shuffled() {
            if isValid(board, index: index, value: value) {
                board[index] = value
                if fill(&board, from: index + 1) { return true }
                board[index] = 0
            }
        }
        return false
    }

    // MARK: - 挖空

    /// 从完整解中按随机顺序挖空，保持唯一解，逼近目标线索数。
    private static func dig(from solved: [Int], targetClues: Int) -> [Int] {
        var puzzle = solved
        var clues = 81
        // 对称地降低难度波动：使用随机顺序逐格尝试移除。
        let positions = Array(0..<81).shuffled()

        for index in positions where clues > targetClues {
            let backup = puzzle[index]
            guard backup != 0 else { continue }
            puzzle[index] = 0

            // 若移除后不再唯一解，则还原。
            if countSolutions(puzzle, limit: 2) != 1 {
                puzzle[index] = backup
            } else {
                clues -= 1
            }
        }
        return puzzle
    }

    // MARK: - 解的数量统计（唯一性判定）

    /// 统计 `board` 的解数量，最多统计到 `limit` 即提前返回。
    /// 返回 1 表示唯一解。使用「最少候选优先」的回溯以提升效率。
    static func countSolutions(_ board: [Int], limit: Int = 2) -> Int {
        var working = board
        var count = 0
        solveCounting(&working, count: &count, limit: limit)
        return count
    }

    private static func solveCounting(_ board: inout [Int], count: inout Int, limit: Int) {
        if count >= limit { return }

        // 选择候选最少的空格（约束传播，剪枝更强）。
        var bestIndex = -1
        var bestCandidates: [Int] = []
        var bestCount = 10

        for index in 0..<81 where board[index] == 0 {
            var candidates: [Int] = []
            for value in 1...9 where isValid(board, index: index, value: value) {
                candidates.append(value)
            }
            if candidates.count < bestCount {
                bestCount = candidates.count
                bestIndex = index
                bestCandidates = candidates
                if bestCount == 0 { break }      // 死路，立即回溯
                if bestCount == 1 { break }      // 已是最优，无需继续找
            }
        }

        // 没有空格 -> 找到一个完整解。
        if bestIndex == -1 {
            count += 1
            return
        }
        // 有空格但无候选 -> 此分支无解。
        if bestCandidates.isEmpty { return }

        for value in bestCandidates {
            board[bestIndex] = value
            solveCounting(&board, count: &count, limit: limit)
            board[bestIndex] = 0
            if count >= limit { return }
        }
    }

    /// 求出 `board` 的一个完整解（用于「提示/自动解」功能）。无解返回 nil。
    static func solve(_ board: [Int]) -> [Int]? {
        var working = board
        return solveFirst(&working) ? working : nil
    }

    private static func solveFirst(_ board: inout [Int]) -> Bool {
        guard let index = (0..<81).first(where: { board[$0] == 0 }) else { return true }
        for value in 1...9 where isValid(board, index: index, value: value) {
            board[index] = value
            if solveFirst(&board) { return true }
            board[index] = 0
        }
        return false
    }
}
