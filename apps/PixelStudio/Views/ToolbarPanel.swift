//
//  ToolbarPanel.swift
//  PixelStudio
//
//  工具选择条 + 笔刷大小、镜像、网格、撤销/重做等绘制选项。
//

import SwiftUI

struct ToolbarPanel: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        VStack(spacing: 12) {
            toolRow
            optionRow
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - 工具

    private var toolRow: some View {
        HStack(spacing: 8) {
            ForEach(DrawingTool.allCases) { tool in
                Button {
                    guard vm.tool != tool else { return }
                    AppHaptics.selection()
                    vm.tool = tool
                } label: {
                    Image(systemName: tool.systemImage)
                        .font(.system(size: 18, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(vm.tool == tool ? Color.accentColor : Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(vm.tool == tool ? Color.white : Color.primary)
                }
                .accessibilityLabel(tool.titleKey)
                .accessibilityAddTraits(vm.tool == tool ? [.isSelected] : [])
            }
        }
        .animation(.snappy(duration: 0.18), value: vm.tool)
    }

    // MARK: - 选项

    private var optionRow: some View {
        HStack(spacing: 10) {
            // 撤销 / 重做
            iconButton("arrow.uturn.backward", enabled: vm.canUndo) { AppHaptics.impact(.light); vm.undo() }
            iconButton("arrow.uturn.forward", enabled: vm.canRedo) { AppHaptics.impact(.light); vm.redo() }

            Divider().frame(height: 24)

            // 笔刷大小
            Menu {
                ForEach(1...4, id: \.self) { size in
                    Button {
                        vm.brushSize = size
                    } label: {
                        Label("\(size) px", systemImage: vm.brushSize == size ? "checkmark" : "")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "scribble.variable")
                    Text("\(vm.brushSize)")
                }
                .toolChipStyle()
            }
            .accessibilityLabel(Text("brush.size"))
            .accessibilityValue(Text("\(vm.brushSize)"))

            Divider().frame(height: 24)

            // 镜像
            toggleChip("arrow.left.and.right.righttriangle.left.righttriangle.right",
                       active: vm.mirror.contains(.horizontal),
                       label: "mirror.horizontal") {
                AppHaptics.impact(.light)
                vm.mirror.formSymmetricDifference(.horizontal)
                vm.regenerateDisplay()
            }
            toggleChip("arrow.up.and.down.righttriangle.up.righttriangle.down",
                       active: vm.mirror.contains(.vertical),
                       label: "mirror.vertical") {
                AppHaptics.impact(.light)
                vm.mirror.formSymmetricDifference(.vertical)
                vm.regenerateDisplay()
            }

            // 网格
            toggleChip("grid", active: vm.showGrid, label: "grid.toggle") {
                AppHaptics.impact(.light)
                vm.showGrid.toggle()
                vm.regenerateDisplay()
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - 复用控件

    private func iconButton(_ system: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system).toolChipStyle()
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }

    private func toggleChip(_ system: String, active: Bool, label: LocalizedStringKey,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .frame(width: 38, height: 34)
                .background(active ? Color.accentColor : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(active ? Color.white : Color.primary)
        }
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(active ? [.isSelected] : [])
        .animation(.snappy(duration: 0.18), value: active)
    }
}

private extension View {
    /// 统一的小工具按钮外观。
    func toolChipStyle() -> some View {
        self
            .frame(height: 34)
            .padding(.horizontal, 10)
            .background(Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(Color.primary)
    }
}

#Preview {
    let container = PreviewData.container
    let project = PreviewData.sampleProject(in: container)
    return ToolbarPanel(vm: EditorViewModel(project: project, context: container.mainContext))
}
