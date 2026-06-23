//
//  GroupDetailView.swift
//  CleanAlbum
//
//  单组照片详情：网格预览 + 逐张选择 + 全屏滑动浏览。
//

import SwiftUI

struct GroupDetailView: View {
    @Bindable var group: PhotoGroup
    let viewModel: ScanViewModel

    @State private var fullscreenItem: PhotoItem?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 4)]

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.spacing) {
                hint
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(group.items) { item in
                        cell(for: item)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.vertical)
        }
        .background(Color.appBackground)
        .navigationTitle(LocalizedStringKey(group.kind.titleKey))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("group.keepBest") {
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        group.applyDefaultSelection()
                    }
                }
                .font(.subheadline)
            }
        }
        .fullScreenCover(item: $fullscreenItem) { item in
            PhotoPreviewView(
                group: group,
                initialItem: item,
                viewModel: viewModel
            )
        }
    }

    private var hint: some View {
        Label(
            group.kind == .blurry ? "group.hint.blurry" : "group.hint.similar",
            systemImage: "hand.tap.fill"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private func cell(for item: PhotoItem) -> some View {
        let isKeeper = group.suggestedKeeper?.id == item.id

        return ZStack(alignment: .topTrailing) {
            PhotoThumbnailView(item: item, size: CGSize(width: 120, height: 120), loader: viewModel.thumbnail)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadiusSM))
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.cornerRadiusSM)
                        .stroke(item.isSelected ? Color.destructive : Color.clear, lineWidth: 3)
                }
                .overlay(alignment: .bottomLeading) {
                    if isKeeper {
                        Label("group.keeper", systemImage: "star.fill")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial)
                            .foregroundStyle(Color.brand)
                            .clipShape(Capsule())
                            .padding(4)
                    }
                }
                .onTapGesture { toggle(item) }
                .onLongPressGesture {
                    Haptics.light()
                    fullscreenItem = item
                }

            // 选择标记
            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(item.isSelected ? Color.destructive : .white)
                .background(Circle().fill(.black.opacity(0.25)).blur(radius: 2))
                .padding(6)
                .onTapGesture { toggle(item) }
        }
        // 把整个单元格合并为一个无障碍元素，VoiceOver 朗读"照片，建议保留/待删除"，双击切换。
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(isKeeper ? "group.keeper" : "a11y.photo"))
        .accessibilityValue(Text(item.isSelected ? "preview.markedDelete" : "a11y.kept"))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text("a11y.toggleHint"))
        .accessibilityAction { toggle(item) }
    }

    /// 切换选中并给出触觉反馈，带动画刷新边框与勾选标记。
    private func toggle(_ item: PhotoItem) {
        Haptics.selection()
        withAnimation(.easeInOut(duration: 0.15)) {
            item.isSelected.toggle()
        }
    }
}
