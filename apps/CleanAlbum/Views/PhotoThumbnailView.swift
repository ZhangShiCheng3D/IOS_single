//
//  PhotoThumbnailView.swift
//  CleanAlbum
//
//  异步加载并缓存单张照片缩略图的组件。
//

import SwiftUI
import UIKit

struct PhotoThumbnailView: View {
    let item: PhotoItem
    let size: CGSize
    /// 注入的缩略图加载器（来自 ScanViewModel，MainActor 隔离）。
    let loader: @MainActor (PhotoItem, CGSize) async -> UIImage?

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.cardBackground)
                    .overlay {
                        ProgressView()
                            .controlSize(.small)
                    }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .task(id: item.id) {
            // 取 2x 像素更清晰。
            let scaled = CGSize(width: size.width * 2, height: size.height * 2)
            image = await loader(item, scaled)
        }
    }
}
