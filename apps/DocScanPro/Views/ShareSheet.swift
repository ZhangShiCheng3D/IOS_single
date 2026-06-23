//
//  ShareSheet.swift
//  DocScanPro
//
//  UIActivityViewController 的 SwiftUI 封装，用于分享 PDF / 文本。
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
