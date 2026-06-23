//
//  BubbleWrapViewModel.swift
//  CalmBox
//
//  泡泡纸状态管理：维护泡泡网格、记录已破裂泡泡、统计与重置。
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class BubbleWrapViewModel {

    /// 单个泡泡。
    struct Bubble: Identifiable {
        let id: Int
        var isPopped: Bool = false
    }

    /// 网格列数。
    let columns: Int
    /// 网格行数。
    let rows: Int

    private(set) var bubbles: [Bubble]
    private(set) var poppedCount = 0

    /// 是否全部破裂。
    var allPopped: Bool { poppedCount == bubbles.count }

    init(columns: Int = 6, rows: Int = 10) {
        self.columns = columns
        self.rows = rows
        self.bubbles = (0..<(columns * rows)).map { Bubble(id: $0) }
    }

    /// 捏破一个泡泡。返回 true 表示这是首次破裂（应触发反馈）。
    @discardableResult
    func pop(_ id: Int) -> Bool {
        guard id >= 0, id < bubbles.count, !bubbles[id].isPopped else { return false }
        bubbles[id].isPopped = true
        poppedCount += 1
        return true
    }

    /// 重置全部泡泡。
    func reset() {
        for index in bubbles.indices {
            bubbles[index].isPopped = false
        }
        poppedCount = 0
    }
}
