//
//  SudokuPuzzle.swift
//  PaperGames
//
//  数独谜题的纯数据表示（不参与 SwiftData 持久化）。
//

import Foundation

/// 一道完整的数独谜题：包含初始盘面与唯一解。
struct SudokuPuzzle: Equatable {
    /// 初始盘面，81 个元素（行优先），0 表示空格。
    let givens: [Int]
    /// 完整解答，81 个元素，全部为 1...9。
    let solution: [Int]
    /// 难度。
    let difficulty: Difficulty

    /// 索引 -> 行列转换工具。
    static func row(of index: Int) -> Int { index / 9 }
    static func col(of index: Int) -> Int { index % 9 }
    static func box(of index: Int) -> Int { (row(of: index) / 3) * 3 + col(of: index) / 3 }
    static func index(row: Int, col: Int) -> Int { row * 9 + col }
}
