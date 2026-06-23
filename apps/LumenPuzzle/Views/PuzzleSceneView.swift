//
//  PuzzleSceneView.swift
//  LumenPuzzle
//
//  将 PuzzleSceneController 的 SCNScene 桥接进 SwiftUI 的 UIViewRepresentable。
//  负责手势：
//   · 单指拖动 → 移动光源（把屏幕坐标反投影到光源所在水平面）。
//   · 双指拖动 → 环绕旋转视角。
//

import SwiftUI
import SceneKit

struct PuzzleSceneView: UIViewRepresentable {

    /// 关联的游戏视图模型。手势事件回调到它。
    @ObservedObject var viewModel: GameViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = viewModel.scene.scene
        view.pointOfView = viewModel.scene.cameraNode
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.isJitteringEnabled = true
        view.preferredFramesPerSecond = 60
        // 关闭内建相机控制，改用自定义手势，避免与移动光源冲突。
        view.allowsCameraControl = false

        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // 状态由控制器内部驱动，无需在此同步。
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject {
        private let viewModel: GameViewModel
        private weak var scnView: SCNView?

        init(viewModel: GameViewModel) {
            self.viewModel = viewModel
        }

        func attach(to view: SCNView) {
            scnView = view

            let movePan = UIPanGestureRecognizer(target: self, action: #selector(handleMovePan(_:)))
            movePan.maximumNumberOfTouches = 1
            view.addGestureRecognizer(movePan)

            let orbitPan = UIPanGestureRecognizer(target: self, action: #selector(handleOrbitPan(_:)))
            orbitPan.minimumNumberOfTouches = 2
            orbitPan.maximumNumberOfTouches = 2
            view.addGestureRecognizer(orbitPan)
        }

        // MARK: 移动光源

        @objc private func handleMovePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = scnView else { return }
            let location = gesture.location(in: view)

            switch gesture.state {
            case .began:
                viewModel.beginDrag()
                if let point = planePoint(for: location, in: view) {
                    viewModel.dragLight(toPlanePoint: point)
                }
            case .changed:
                if let point = planePoint(for: location, in: view) {
                    viewModel.dragLight(toPlanePoint: point)
                }
            case .ended, .cancelled, .failed:
                viewModel.endDrag()
            default:
                break
            }
        }

        /// 把屏幕点反投影到光源所在的水平面（y = lightBounds.height）。
        private func planePoint(for location: CGPoint, in view: SCNView) -> SCNVector3? {
            let near = view.unprojectPoint(SCNVector3(Float(location.x), Float(location.y), 0))
            let far = view.unprojectPoint(SCNVector3(Float(location.x), Float(location.y), 1))
            let direction = far - near
            guard abs(direction.y) > 1e-5 else { return nil }

            let planeHeight = viewModel.level.lightBounds.height
            let t = (planeHeight - near.y) / direction.y
            guard t.isFinite else { return nil }
            return near + direction * t
        }

        // MARK: 环绕视角

        @objc private func handleOrbitPan(_ gesture: UIPanGestureRecognizer) {
            guard let view = scnView else { return }
            switch gesture.state {
            case .changed:
                let translation = gesture.translation(in: view)
                let yaw = Float(-translation.x) * 0.006
                let pitch = Float(-translation.y) * 0.006
                viewModel.orbitCamera(deltaYaw: yaw, deltaPitch: pitch)
                gesture.setTranslation(.zero, in: view)
            default:
                break
            }
        }
    }
}
