//
//  DocumentScannerView.swift
//  DocScanPro
//
//  VisionKit 文档扫描相机封装。VNDocumentCameraViewController 提供
//  自动边缘检测、透视校正、多页连拍能力，全部在系统层本地完成。
//

import SwiftUI
import VisionKit
import UIKit

/// 将 VisionKit 文档相机桥接到 SwiftUI。
struct DocumentScannerView: UIViewControllerRepresentable {

    /// 扫描完成回调，返回校正后的页面图像数组。
    var onComplete: ([UIImage]) -> Void
    /// 取消回调。
    var onCancel: () -> Void
    /// 出错回调。
    var onError: (Error) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // 无需动态更新。
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            for index in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: index))
            }
            parent.onComplete(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.onError(error)
        }
    }
}
