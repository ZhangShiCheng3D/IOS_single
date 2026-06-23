//
//  SudokuBoardView.swift
//  PaperGames
//
//  数独 9x9 盘面渲染。包含单元格、选中/关联高亮、错误提示、笔记显示，
//  以及加粗的 3x3 宫格分隔线。
//

import SwiftUI

struct SudokuBoardView: View {
    @Bindable var viewModel: SudokuViewModel
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 9

            ZStack {
                // 单元格层。
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { col in
                                let index = row * 9 + col
                                SudokuCellView(
                                    cell: viewModel.cells[index],
                                    isSelected: viewModel.selectedIndex == index,
                                    isPeer: peerHighlight(index),
                                    isSameNumber: sameNumberHighlight(index),
                                    size: cell
                                )
                                .onTapGesture {
                                    Haptics.tap()
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        viewModel.select(index)
                                    }
                                }
                                .accessibilityElement()
                                .accessibilityLabel(cellAccessibilityLabel(index))
                                .accessibilityAddTraits(viewModel.selectedIndex == index ? [.isSelected, .isButton] : .isButton)
                            }
                        }
                    }
                }
                // 网格线层。
                gridLines(cell: cell, side: side)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - 无障碍

    /// 单元格的 VoiceOver 描述：行列定位 + 当前值/笔记。
    private func cellAccessibilityLabel(_ index: Int) -> Text {
        let row = index / 9 + 1
        let col = index % 9 + 1
        let cell = viewModel.cells[index]
        let position = Text("a11y.cell.position.\(row).\(col)")
        if cell.value != 0 {
            let valueText = Text("a11y.cell.value.\(cell.value)")
            return cell.isGiven
                ? position + Text(", ") + Text("a11y.cell.given") + Text(" ") + valueText
                : position + Text(", ") + valueText
        }
        if !cell.notes.isEmpty {
            return position + Text(", ") + Text("a11y.cell.notes")
        }
        return position + Text(", ") + Text("a11y.cell.empty")
    }

    // MARK: - 高亮判定

    /// 同行/列/宫高亮（受设置开关控制）。
    private func peerHighlight(_ index: Int) -> Bool {
        guard settings.highlightPeers, let selected = viewModel.selectedIndex else { return false }
        return viewModel.isPeer(of: selected, index: index)
    }

    /// 与选中格相同数字高亮。
    private func sameNumberHighlight(_ index: Int) -> Bool {
        guard settings.highlightPeers,
              let selected = viewModel.selectedIndex,
              selected != index else { return false }
        let value = viewModel.cells[selected].value
        return value != 0 && viewModel.cells[index].value == value
    }

    // MARK: - 网格线

    private func gridLines(cell: CGFloat, side: CGFloat) -> some View {
        Path { path in
            for i in 0...9 {
                let position = CGFloat(i) * cell
                path.move(to: CGPoint(x: position, y: 0))
                path.addLine(to: CGPoint(x: position, y: side))
                path.move(to: CGPoint(x: 0, y: position))
                path.addLine(to: CGPoint(x: side, y: position))
            }
        }
        .stroke(Color.primary.opacity(0.25), lineWidth: 0.5)
        .overlay(
            // 加粗的 3x3 宫格线与外框。
            Path { path in
                for i in stride(from: 0, through: 9, by: 3) {
                    let position = CGFloat(i) * cell
                    path.move(to: CGPoint(x: position, y: 0))
                    path.addLine(to: CGPoint(x: position, y: side))
                    path.move(to: CGPoint(x: 0, y: position))
                    path.addLine(to: CGPoint(x: side, y: position))
                }
            }
            .stroke(Color.primary, lineWidth: 2)
        )
        .allowsHitTesting(false)
    }
}

#Preview {
    SudokuBoardView(viewModel: SudokuViewModel(difficulty: .easy))
        .environment(SettingsStore())
        .padding()
}
