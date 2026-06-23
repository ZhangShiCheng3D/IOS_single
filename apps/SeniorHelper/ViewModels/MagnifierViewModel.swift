//
//  MagnifierViewModel.swift
//  SeniorHelper
//
//  放大镜页面 ViewModel：协调摄像头会话、缩放、手电筒与画面冻结。
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class MagnifierViewModel {

    let camera = CameraManager()

    /// 是否需要展示权限引导。
    var showPermissionAlert = false

    /// 画面是否已冻结（定格便于阅读）。
    var isFrozen = false

    /// 缩放区间，绑定到 Slider。
    var zoom: CGFloat {
        get { camera.zoomFactor }
        set { camera.zoomFactor = newValue }
    }

    var maxZoom: CGFloat { camera.maxZoom }
    var isTorchOn: Bool { camera.isTorchOn }
    var isAuthorized: Bool { camera.authorizationStatus == .authorized }

    /// 页面出现时启动。
    func onAppear() async {
        switch camera.authorizationStatus {
        case .authorized:
            camera.start()
        case .notDetermined:
            let granted = await camera.requestAuthorization()
            if granted {
                camera.start()
            } else {
                showPermissionAlert = true
            }
        default:
            showPermissionAlert = true
        }
    }

    /// 页面消失时停止，释放摄像头与电量。
    func onDisappear() {
        camera.stop()
        isFrozen = false
    }

    func toggleTorch() {
        Haptics.tap()
        camera.toggleTorch()
    }

    /// 定格 / 解除定格画面。
    func toggleFreeze() {
        Haptics.tap()
        isFrozen.toggle()
        // 冻结时不停止会话，仅由预览层暂停渲染，解除后立刻恢复。
    }

    /// 快捷缩放按钮（-/+）。
    func adjustZoom(by delta: CGFloat) {
        let next = (zoom + delta).clamped(to: 1.0...maxZoom)
        zoom = next
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
