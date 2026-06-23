//
//  FrameTimelinePanel.swift
//  PixelStudio
//
//  动画时间轴：帧缩略图条、添加/复制/删除帧、洋葱皮开关、播放预览、
//  每帧时长调整。免费档不开放多帧。
//

import SwiftUI

struct FrameTimelinePanel: View {
    @ObservedObject var vm: EditorViewModel
    @State private var showingPreview = false

    var body: some View {
        VStack(spacing: 8) {
            header
            framesStrip
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
        .sheet(isPresented: $showingPreview) {
            AnimationPreviewView(vm: vm)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Label("\(vm.frameCount)", systemImage: "film")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                AppHaptics.impact(.light)
                vm.showOnionSkin.toggle()
                vm.regenerateDisplay()
            } label: {
                Image(systemName: vm.showOnionSkin ? "square.stack.3d.down.right.fill" : "square.stack.3d.down.right")
                    .foregroundStyle(vm.showOnionSkin ? Color.accentColor : Color.secondary)
            }
            .accessibilityLabel(Text("timeline.onion"))

            Button {
                showingPreview = true
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
            }
            .disabled(vm.frameCount < 2)
            .accessibilityLabel(Text("timeline.play"))
        }
    }

    private var framesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(0..<vm.frameCount), id: \.self) { index in
                    frameCell(index)
                }
                addFrameButton
            }
            .padding(.vertical, 4)
        }
    }

    private func frameCell(_ index: Int) -> some View {
        let isActive = index == vm.currentFrameIndex
        return VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                CheckerboardBackground(cell: 5)
                if let cg = vm.image(forFrame: index) {
                    Image(decorative: cg, scale: 1, orientation: .up)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                }
                Text("\(index + 1)")
                    .font(.caption2.bold())
                    .padding(2)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .padding(2)
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isActive ? Color.accentColor : Color(.separator),
                                  lineWidth: isActive ? 3 : 1)
            )
            .animation(.snappy(duration: 0.18), value: isActive)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("timeline.frame.label \(index + 1)"))
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
        .onTapGesture {
            guard index != vm.currentFrameIndex else { return }
            AppHaptics.selection()
            vm.selectFrame(index)
        }
        .contextMenu {
            Button { vm.setFrameDuration(0.06, at: index) } label: { Label("timeline.fast", systemImage: "hare") }
            Button { vm.setFrameDuration(0.12, at: index) } label: { Label("timeline.normal", systemImage: "tortoise") }
            Button { vm.setFrameDuration(0.25, at: index) } label: { Label("timeline.slow", systemImage: "tortoise.fill") }
            if vm.frameCount > 1 {
                Button(role: .destructive) {
                    vm.deleteFrame(at: index)
                } label: {
                    Label("common.delete", systemImage: "trash")
                }
            }
        }
    }

    private var addFrameButton: some View {
        Menu {
            Button {
                AppHaptics.impact(.light)
                vm.addFrame(duplicate: false)
            } label: {
                Label("timeline.addBlank", systemImage: "plus.square")
            }
            Button {
                AppHaptics.impact(.light)
                vm.addFrame(duplicate: true)
            } label: {
                Label("timeline.duplicate", systemImage: "plus.square.on.square")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 52, height: 52)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(Text("timeline.addFrame"))
    }
}

/// 全屏循环播放预览。
struct AnimationPreviewView: View {
    @ObservedObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayIndex = 0
    @State private var playTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ZStack {
                    CheckerboardBackground(cell: 16)
                    if let cg = vm.image(forFrame: displayIndex) {
                        Image(decorative: cg, scale: 1, orientation: .up)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(24)
            }
            .navigationTitle("timeline.preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                }
            }
            .onAppear { startPlayback() }
            .onDisappear { playTask?.cancel() }
        }
    }

    private func startPlayback() {
        playTask?.cancel()
        playTask = Task {
            while !Task.isCancelled {
                let frame = vm.frames.indices.contains(displayIndex) ? vm.frames[displayIndex] : nil
                let delay = frame?.duration ?? 0.12
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                if Task.isCancelled { break }
                await MainActor.run {
                    displayIndex = (displayIndex + 1) % max(1, vm.frameCount)
                }
            }
        }
    }
}

#Preview {
    let container = PreviewData.container
    let project = PreviewData.sampleProject(in: container)
    return FrameTimelinePanel(vm: EditorViewModel(project: project, context: container.mainContext))
}
