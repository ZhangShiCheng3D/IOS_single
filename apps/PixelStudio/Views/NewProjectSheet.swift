//
//  NewProjectSheet.swift
//  PixelStudio
//
//  新建作品：命名 + 选择画布尺寸。大于 32 的尺寸需要 Pro。
//

import SwiftUI

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    /// 回调：作品名称、画布边长。
    var onCreate: (String, Int) -> Void

    @State private var name: String = ""
    @State private var selectedSize: CanvasSize = .s16
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("newProject.name.section") {
                    TextField("newProject.name.placeholder", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                        ForEach(CanvasSize.allCases) { size in
                            sizeChip(size)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("newProject.size.section")
                } footer: {
                    Text("newProject.size.footer")
                }
            }
            .navigationTitle("newProject.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("newProject.create") { create() }
                        .bold()
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(highlightedFeature: .largeCanvas)
            }
        }
    }

    private func sizeChip(_ size: CanvasSize) -> some View {
        let locked = size.requiresPro && !purchaseManager.isProUnlocked
        let isSelected = selectedSize == size
        return Button {
            if locked {
                showingPaywall = true
            } else {
                selectedSize = size
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "square.grid.2x2")
                    .font(.title3)
                Text(size.label)
                    .font(.subheadline.weight(.medium))
                if locked {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(locked ? Color.secondary : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? NSLocalizedString("newProject.defaultName", comment: "") : trimmed
        onCreate(finalName, selectedSize.rawValue)
        dismiss()
    }
}

#Preview {
    NewProjectSheet { _, _ in }
        .environmentObject(PurchaseManager())
}
