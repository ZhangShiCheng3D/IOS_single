//
//  ExportPreviewView.swift
//  CollageKit
//
//  导出预览：展示最终合成图，提供保存到相册、系统分享，
//  未解锁 Pro 时提示水印并引导去水印。
//

import SwiftUI

struct ExportPreviewView: View {
    @Bindable var project: CollageProject
    @ObservedObject var viewModel: EditorViewModel
    @EnvironmentObject private var store: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var rendered: UIImage?
    @State private var showShare = false
    @State private var showPaywall = false
    @State private var isSaving = false
    @State private var savedOK = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let rendered {
                        Image(uiImage: rendered)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                            .padding(.horizontal, 24)
                    } else {
                        ProgressView().frame(height: 280)
                    }

                    if !store.isPro {
                        watermarkNotice
                    }

                    actionButtons
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("export_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("done") { dismiss() }
                }
            }
            .task { renderImage() }
            .onChange(of: store.isPro) { _, _ in renderImage() }
            .sheet(isPresented: $showShare) {
                if let rendered { ShareSheet(items: [rendered]) }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(store)
            }
            .overlay(alignment: .bottom) {
                if savedOK { savedToast }
            }
        }
    }

    private var watermarkNotice: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "drop.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("export_watermark_title").font(.subheadline.weight(.semibold))
                    Text("export_watermark_sub").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 24)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    isSaving = true
                    await viewModel.exportToAlbum(project: project, isPro: store.isPro)
                    isSaving = false
                    if viewModel.statusMessage == nil {
                        DesignSystem.Haptics.success()
                        withAnimation { savedOK = true }
                        try? await Task.sleep(for: .seconds(1.6))
                        withAnimation { savedOK = false }
                    }
                }
            } label: {
                HStack {
                    if isSaving { ProgressView().tint(.white) }
                    else { Label("export_save", systemImage: "square.and.arrow.down") }
                }
            }
            .buttonStyle(PrimaryButtonStyle(height: 52))
            .disabled(rendered == nil || isSaving)

            Button {
                showShare = true
            } label: {
                Label("export_share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(SecondaryButtonStyle(height: 52))
            .disabled(rendered == nil)
        }
        .padding(.horizontal, 24)
    }

    private var savedToast: some View {
        Label("export_saved", systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 30)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func renderImage() {
        rendered = viewModel.render(project: project, isPro: store.isPro)
    }
}
