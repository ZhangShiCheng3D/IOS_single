//
//  TicTacToeViewModel.swift
//  PaperGames
//
//  井字棋视图模型。玩家执 X，AI 执 O，使用 Minimax 实现不败 AI。
//

import SwiftUI
import Observation

@Observable
@MainActor
final class TicTacToeViewModel {

    enum Mark: String {
        case x = "✕"
        case o = "○"
    }

    enum Outcome: Equatable {
        case ongoing
        case win(Mark)
        case draw
    }

    /// 棋盘，9 格，nil 表示空。
    private(set) var board: [Mark?] = Array(repeating: nil, count: 9)
    private(set) var outcome: Outcome = .ongoing
    private(set) var isThinking = false
    var playerWins = 0
    var aiWins = 0
    var draws = 0

    /// 玩家落子。
    func playerMove(at index: Int) {
        guard outcome == .ongoing, board[index] == nil, !isThinking else { return }
        board[index] = .x
        Haptics.place()
        if updateOutcome() { return }

        // 轮到 AI。
        isThinking = true
        Task {
            // 轻微延迟，模拟思考，提升体验。
            try? await Task.sleep(for: .milliseconds(350))
            self.aiMove()
            self.isThinking = false
        }
    }

    /// 开始新一局。
    func reset() {
        board = Array(repeating: nil, count: 9)
        outcome = .ongoing
        isThinking = false
    }

    // MARK: - AI

    private func aiMove() {
        guard outcome == .ongoing else { return }
        let best = bestMove(for: .o)
        if let move = best { board[move] = .o }
        Haptics.tap()
        _ = updateOutcome()
    }

    /// Minimax 求最优落子。
    private func bestMove(for mark: Mark) -> Int? {
        var bestScore = Int.min
        var move: Int?
        for index in 0..<9 where board[index] == nil {
            board[index] = mark
            let score = minimax(depth: 0, isMaximizing: false)
            board[index] = nil
            if score > bestScore {
                bestScore = score
                move = index
            }
        }
        return move
    }

    /// Minimax 评分。AI(O) 为最大化方。
    private func minimax(depth: Int, isMaximizing: Bool) -> Int {
        if let winner = winner() {
            // 越早获胜分越高，促使 AI 尽快取胜 / 拖延失败。
            return winner == .o ? (10 - depth) : (depth - 10)
        }
        if board.allSatisfy({ $0 != nil }) { return 0 } // 平局

        if isMaximizing {
            var best = Int.min
            for index in 0..<9 where board[index] == nil {
                board[index] = .o
                best = max(best, minimax(depth: depth + 1, isMaximizing: false))
                board[index] = nil
            }
            return best
        } else {
            var best = Int.max
            for index in 0..<9 where board[index] == nil {
                board[index] = .x
                best = min(best, minimax(depth: depth + 1, isMaximizing: true))
                board[index] = nil
            }
            return best
        }
    }

    // MARK: - 胜负判定

    static let lines: [[Int]] = [
        [0,1,2],[3,4,5],[6,7,8], // 行
        [0,3,6],[1,4,7],[2,5,8], // 列
        [0,4,8],[2,4,6]          // 对角线
    ]

    /// 当前赢家（若有）。
    func winner() -> Mark? {
        for line in Self.lines {
            if let m = board[line[0]], board[line[1]] == m, board[line[2]] == m {
                return m
            }
        }
        return nil
    }

    /// 获取构成胜利的连线（用于高亮）。
    var winningLine: [Int]? {
        for line in Self.lines {
            if let m = board[line[0]], board[line[1]] == m, board[line[2]] == m {
                return line
            }
        }
        return nil
    }

    /// 更新对局结果，返回是否已结束。
    @discardableResult
    private func updateOutcome() -> Bool {
        if let w = winner() {
            outcome = .win(w)
            switch w {
            case .x: playerWins += 1; Haptics.success()
            case .o: aiWins += 1; Haptics.error()
            }
            return true
        }
        if board.allSatisfy({ $0 != nil }) {
            outcome = .draw
            draws += 1
            return true
        }
        return false
    }
}
