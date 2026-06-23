//
//  PhotoPreviewView.swift
//  CleanAlbum
//
//  全屏照片浏览：左右滑动切换，底部可勾选删除。
//

import SwiftUI
import UIKit

struct PhotoPreviewView: View {
    let group: PhotoGroup
    let initialItem: PhotoItem
    let viewModel: ScanViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selection: String

    init(group: PhotoGroup, initialItem: PhotoItem, viewModel: ScanViewModel) {
        self.group = group
        self.initialItem = initialItem
        self.viewModel = viewModel
        // 初始即定位到被点开的那张，避免先闪现第一张再跳转。
        _selection = State(initialValue: initialItem.id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $selection) {
                    ForEach(group.items) { item in
                        FullImage(item: item, loader: viewModel.thumbnail)
                            .tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            .overlay(alignment: .bottom) { selectionBar }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("action.close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var currentItem: PhotoItem? {
        group.items.first { $0.id == selection }
    }

    private var selectionBar: some View {
        Group {
            if let item = currentItem {
                Button {
                    Haptics.selection()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        item.isSelected.toggle()
                    }
                } label: {
                    Label(
                        item.isSelected ? "preview.markedDelete" : "preview.markDelete",
                        systemImage: item.isSelected ? "checkmark.circle.fill" : "trash"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(item.isSelected ? Color.destructive : Color.white.opacity(0.15))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding()
            }
        }
    }
}

/// 全屏单图，支持双击/捏合缩放。
private struct FullImage: View {
    let item: PhotoItem
    let loader: @MainActor (PhotoItem, CGSize) async -> UIImage?
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { scale = max(1, $0) }
                                .onEnded { _ in withAnimation { scale = 1 } }
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    ProgressView().tint(.white)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .task(id: item.id) {
            image = await loader(item, CGSize(width: 1024, height: 1024))
        }
    }
}
