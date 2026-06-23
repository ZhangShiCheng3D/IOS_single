//
//  MagnifierView.swift
//  SeniorHelper
//
//  放大镜模式：实时摄像头放大 + 手电筒 + 画面定格。
//  本功能永久免费，作为获客入口。
//

import SwiftUI
import UIKit

struct MagnifierView: View {
    @State private var viewModel = MagnifierViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.isAuthorized {
                    cameraContent
                } else {
                    permissionPlaceholder
                }
            }
            .navigationTitle(Text("放大镜"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: scenePhase) { _, phase in
            // 退到后台时停止会话；回前台重新开启。
            if phase == .active, viewModel.isAuthorized {
                Task { await viewModel.onAppear() }
            } else if phase == .background {
                viewModel.onDisappear()
            }
        }
    }

    // MARK: - 摄像头主内容

    private var cameraContent: some View {
        VStack(spacing: 0) {
            // 实时预览，点击可定格。
            CameraPreview(session: viewModel.camera.session, isFrozen: viewModel.isFrozen)
                .overlay(alignment: .top) {
                    if viewModel.isFrozen {
                        frozenBadge
                    }
                }
                .overlay(alignment: .center) {
                    // 双指捏合缩放。
                    Color.clear.contentShape(Rectangle())
                        .gesture(magnification)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .padding(.horizontal, Theme.smallPadding)
                .padding(.top, Theme.smallPadding)

            controlPanel
        }
    }

    private var frozenBadge: some View {
        Text("已定格 · 再次点击解除")
            .font(.headline)
            .padding(.horizontal, Theme.padding)
            .padding(.vertical, Theme.smallPadding)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, Theme.padding)
    }

    /// 底部大按钮控制面板。
    private var controlPanel: some View {
        VStack(spacing: Theme.padding) {
            // 缩放控制：- 滑块 +
            HStack(spacing: Theme.padding) {
                zoomButton(symbol: "minus.magnifyingglass", delta: -1) {
                    viewModel.adjustZoom(by: -1)
                }

                VStack(spacing: 4) {
                    Slider(value: $viewModel.zoom, in: 1...max(1.01, viewModel.maxZoom))
                        .tint(Theme.accent)
                    Text(verbatim: String(format: "%.1f×", viewModel.zoom))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                }

                zoomButton(symbol: "plus.magnifyingglass", delta: 1) {
                    viewModel.adjustZoom(by: 1)
                }
            }

            // 手电筒 + 定格
            HStack(spacing: Theme.padding) {
                Button {
                    viewModel.toggleTorch()
                } label: {
                    Label(
                        viewModel.isTorchOn ? "关灯" : "照明",
                        systemImage: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill"
                    )
                }
                .buttonStyle(.seniorPrimary(background: viewModel.isTorchOn ? Theme.callAction : Theme.accent))
                .accessibilityHint(Text("打开或关闭手电筒补光"))

                Button {
                    viewModel.toggleFreeze()
                } label: {
                    Label(
                        viewModel.isFrozen ? "继续" : "定格",
                        systemImage: viewModel.isFrozen ? "play.fill" : "camera.metering.center.weighted"
                    )
                }
                .buttonStyle(.seniorPrimary(background: viewModel.isFrozen ? Theme.danger : Theme.accent))
                .accessibilityHint(Text("定格当前画面，方便看清"))
            }
        }
        .padding(Theme.padding)
        .background(.black)
    }

    private func zoomButton(symbol: String, delta: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title)
                .frame(width: Theme.minTapHeight, height: Theme.minTapHeight)
                .background(Color.white.opacity(0.15), in: Circle())
                .foregroundStyle(.white)
        }
        .accessibilityLabel(Text(delta > 0 ? "放大" : "缩小"))
    }

    private var magnification: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newZoom = viewModel.zoom * value.magnification
                viewModel.zoom = min(max(newZoom, 1.0), max(1.01, viewModel.maxZoom))
            }
    }

    // MARK: - 权限占位

    private var permissionPlaceholder: some View {
        VStack(spacing: Theme.padding) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.8))

            Text("需要使用相机")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            Text("放大镜需要打开相机才能放大文字。请在「设置」中允许使用相机。")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.largePadding)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("前往设置")
            }
            .buttonStyle(.seniorPrimary)
            .padding(.horizontal, Theme.largePadding)
        }
    }
}

#Preview {
    MagnifierView()
        .environment(SpeechManager())
}
