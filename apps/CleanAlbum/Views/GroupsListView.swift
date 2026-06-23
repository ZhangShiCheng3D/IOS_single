//
//  GroupsListView.swift
//  CleanAlbum
//
//  某一类别（重复/相似/模糊）下的全部分组列表。
//

import SwiftUI

struct GroupsListView: View {
    let kind: PhotoGroupKind
    let viewModel: ScanViewModel

    private var groups: [PhotoGroup] { viewModel.groups(of: kind) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Layout.spacing) {
                ForEach(groups) { group in
                    NavigationLink {
                        GroupDetailView(group: group, viewModel: viewModel)
                    } label: {
                        GroupCard(group: group, viewModel: viewModel)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle(LocalizedStringKey(kind.titleKey))
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if groups.isEmpty {
                ContentUnavailableView(
                    "groups.empty",
                    systemImage: "checkmark.seal",
                    description: Text("groups.empty.desc")
                )
            }
        }
    }
}

/// 分组卡片：横向缩略图条 + 统计。
private struct GroupCard: View {
    @Bindable var group: PhotoGroup
    let viewModel: ScanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(group.items.count)", systemImage: group.kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(group.reclaimableBytes.readableSize)
                    .font(.caption)
                    .foregroundStyle(Color.brand)
                    .monospacedDigit()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(group.items.prefix(8)) { item in
                        PhotoThumbnailView(item: item, size: CGSize(width: 72, height: 72), loader: viewModel.thumbnail)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                if item.isSelected {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red, lineWidth: 2)
                                }
                            }
                    }
                    if group.items.count > 8 {
                        Text("+\(group.items.count - 8)")
                            .font(.caption.bold())
                            .frame(width: 72, height: 72)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .cardSurface()
    }
}
