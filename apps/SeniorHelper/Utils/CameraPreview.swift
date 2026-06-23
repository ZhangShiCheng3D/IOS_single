//
//  CameraPreview.swift
//  SeniorHelper
//
//  将 AVCaptureSession 桥接为 SwiftUI 可用的实时预览视图。
//

import SwiftUI
import AVFoundation

/// 摄像头实时预览层。支持「冻结」时暂停渲染。
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var isFrozen: Bool

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 冻结时暂停图层动画/渲染，呈现定格画面。
        uiView.videoPreviewLayer.connection?.isEnabled = !isFrozen
    }

    /// 以 AVCaptureVideoPreviewLayer 作为 layerClass 的容器视图。
    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
