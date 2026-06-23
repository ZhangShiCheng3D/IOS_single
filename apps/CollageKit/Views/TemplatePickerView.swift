//
//  TemplatePickerView.swift
//  CollageKit
//
//  模板选择器：按分类浏览全部模板，付费模板带锁标记。
//  既用于新建工程，也用于编辑中切换模板。
//

import SwiftUI

struct TemplatePickerView: View {
    let isPro: Bool
    /// 选中可用模板回调。
    var onSelect: (CollageTemplate) -> Void
    /// 选中付费模板但未解锁时回调。
    var onNeedPro: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var category: TemplateCategory = .grid

    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPicker
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(TemplateLibrary.templates(in: category)) { tpl in
                            cell(tpl)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("templates_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel") { dismiss() }
                }
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TemplateCategory.allCases) { cat in
                    let selected = cat == category
                    Label(cat.displayName, systemImage: cat.systemImage)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selected ? Color.accentColor : Color(.secondarySystemBackground))
                        .foregroundStyle(selected ? .white : .primary)
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) { category = cat }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func cell(_ tpl: CollageTemplate) -> some View {
        let locked = tpl.isPremium && !isPro
        return Button {
            if locked { onNeedPro() } else { onSelect(tpl); dismiss() }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    TemplateThumbnailView(template: tpl)
                        .padding(14)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.caption.weight(.bold))
                            .padding(7)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(8)
                    }
                }
                HStack(spacing: 4) {
                    Text(tpl.name).font(.caption.weight(.medium))
                    Text("·").foregroundStyle(.secondary)
                    Text("\(tpl.slotCount)").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TemplatePickerView(isPro: false, onSelect: { _ in }, onNeedPro: {})
}
