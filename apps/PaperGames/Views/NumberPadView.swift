//
//  NumberPadView.swift
//  PaperGames
//
//  数独数字输入键盘（1-9）。每个数字下方显示剩余可填数量；
//  填满的数字置灰。
//

import SwiftUI

struct NumberPadView: View {
    @Bindable var viewModel: SudokuViewModel
    @Environment(SettingsStore.self) private var settings

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 9)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...9, id: \.self) { number in
                numberButton(number)
            }
        }
    }

    private func numberButton(_ number: Int) -> some View {
        let remaining = viewModel.remainingCount(for: number)
        let exhausted = remaining == 0
        return Button {
            viewModel.input(number, settings: settings)
        } label: {
            VStack(spacing: 2) {
                Text("\(number)")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(exhausted ? Color.secondary : Color.appAccent)
                Text("\(remaining)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .opacity(exhausted ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.appSurface)
            )
        }
        .buttonStyle(.pressable)
        .disabled(exhausted)
        .accessibilityLabel(Text("\(number)"))
        .accessibilityValue(Text("a11y.numberpad.remaining.\(remaining)"))
    }
}

#Preview {
    NumberPadView(viewModel: SudokuViewModel(difficulty: .easy))
        .environment(SettingsStore())
        .padding()
}
