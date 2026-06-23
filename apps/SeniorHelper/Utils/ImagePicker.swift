//
//  ImagePicker.swift
//  SeniorHelper
//
//  对相机/相册的 UIImagePickerController 进行 SwiftUI 封装，用于拍摄药盒照片。
//

import SwiftUI
import UIKit

/// 拍照 / 选取药盒照片。
struct ImagePicker: UIViewControllerRepresentable {
    /// 取图来源：拍照或从相册选择。
    var sourceType: UIImagePickerController.SourceType = .camera
    /// 选中后回调返回图片。
    var onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // 若设备不支持相机（如模拟器），回退到相册。
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
