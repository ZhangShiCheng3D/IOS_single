//
//  SudokuCellView.swift
//  PaperGames
//
//  单个数独单元格。根据状态渲染数字、笔记、背景高亮与错误颜色。
//

import SwiftUI

struct SudokuCellView: View {
    let cell: SudokuViewModel.Cell
    let isSelected: Bool
    let isPeer: Bool
    let isSameNumber: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            background
            content
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
    }

    // MARK: - 背景

    private var background: some View {
        Rectangle()
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        if isSelected { return Color.appAccent.opacity(0.35) }
        if isSameNumber { return Color.appAccent.opacity(0.18) }
        if isPeer { return Color.appAccent.opacity(0.08) }
        return Color.appSurface
    }

    // MARK: - 内容

    @ViewBuilder
    private var content: some View {
        if cell.value != 0 {
            Text("\(cell.value)")
                .font(.system(size: size * 0.5, weight: cell.isGiven ? .bold : .regular, design: .rounded))
                .foregroundStyle(numberColor)
                .minimumScaleFactor(0.5)
        } else if !cell.notes.isEmpty {
            notesGrid
        }
    }

    /// 数字颜色：初始线索深色、用户填写强调色、错误红色。
    private var numberColor: Color {
        if cell.isError { return .red }
        if cell.isGiven { return .primary }
        return .appAccent
    }

    /// 3x3 笔记网格。
    private var notesGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { col in
                        let number = row * 3 + col + 1
                        Text(cell.notes.contains(number) ? "\(number)" : "")
                            .font(.system(size: size * 0.22, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: size / 3, height: size / 3)
                    }
                }
            }
        }
    }
}

#Preview {
    HStack {
        SudokuCellView(
            cell: .init(value: 5, isGiven: true, notes: [], isError: false),
            isSelected: false, isPeer: false, isSameNumber: false, size: 48
        )
        SudokuCellView(
            cell: .init(value: 3, isGiven: false, notes: [], isError: true),
            isSelected: true, isPeer: false, isSameNumber: false, size: 48
        )
        SudokuCellView(
            cell: .init(value: 0, isGiven: false, notes: [1, 4, 7, 9], isError: false),
            isSelected: false, isPeer: true, isSameNumber: false, size: 48
        )
    }
    .padding()
}
