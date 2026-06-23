//
//  ContentView.swift
//  CleanAlbum
//
//  主界面：扫描入口 → 容量概览 → 分类卡片 → 底部清理操作。
//

import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(PurchaseManager.self) private var purchase
    @Environment(\.modelContext) private var modelContext

    /// 持久化设置（取首条，不存在则创建）。
    @Query private var settingsList: [AppSettings]

    @State private var viewModel = ScanViewModel()
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var result: CleanupResult?
    @State private var deleteError: String?

    /// 当前生效的设置。`ensureSettings()` 在 .task 中保证其存在并写入 SwiftData。
    @State private var settings = AppSettings()

    /// 确保设置实例存在（首启动时创建并持久化）。
    private func ensureSettings() {
        if let existing = settingsList.first {
            settings = existing
        } else {
            modelContext.insert(settings)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                content
                if viewModel.phase == .done && viewModel.selectedCount > 0 {
                    cleanupBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.selectedCount)
            .background(Color.appBackground)
            .navigationTitle("app.name")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel(Text("settings.title"))
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(onUnlocked: { showDeleteConfirm = true })
        }
        .sheet(item: $result) { res in
            CleanupResultView(
                deletedCount: res.count,
                freedBytes: res.freed,
                storageBefore: viewModel.storageBefore
            )
        }
        .alert("cleanup.confirm.title", isPresented: $showDeleteConfirm) {
            Button("cleanup.confirm.delete", role: .destructive) {
                Task { await performCleanup() }
            }
            Button("action.cancel", role: .cancel) {}
        } message: {
            Text(String(
                format: String(localized: "cleanup.confirm.message"),
                viewModel.selectedCount,
                viewModel.totalReclaimableBytes.readableSize
            ))
        }
        .alert("error.title", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("action.ok") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
        .task { ensureSettings() }
    }

    // MARK: - 内容分发

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            WelcomeView { Task { await startScan() } }
        case .requestingPermission, .fetching, .grouping:
            ScanProgressView(phase: viewModel.phase, onCancel: { viewModel.cancelScan() })
        case .analyzing(let progress):
            ScanProgressView(phase: .analyzing(progress: progress), onCancel: { viewModel.cancelScan() })
        case .noAccess:
            noAccessView
        case .empty:
            emptyView
        case .done:
            resultsView
        }
    }

    // MARK: - 结果

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: Layout.spacing) {
                StorageStatsView(
                    total: viewModel.storageBefore.total,
                    free: viewModel.storageBefore.free,
                    reclaimable: viewModel.totalReclaimableBytes
                )

                ForEach(PhotoGroupKind.allCases) { kind in
                    if viewModel.count(of: kind) > 0 {
                        NavigationLink {
                            GroupsListView(kind: kind, viewModel: viewModel)
                        } label: {
                            CategoryCard(
                                kind: kind,
                                photoCount: viewModel.count(of: kind),
                                groupCount: viewModel.groups(of: kind).count
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                rescanButton

                // 给底部清理条留空间
                Color.clear.frame(height: viewModel.selectedCount > 0 ? 80 : 0)
            }
            .padding()
        }
    }

    private var rescanButton: some View {
        Button {
            Task { await startScan() }
        } label: {
            Label("action.rescan", systemImage: "arrow.clockwise")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.brand)
    }

    // MARK: - 底部清理条

    private var cleanupBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: String(localized: "cleanup.selectedCount"), viewModel.selectedCount))
                        .font(.subheadline.weight(.semibold))
                    Text(viewModel.totalReclaimableBytes.readableSize)
                        .font(.caption)
                        .foregroundStyle(Color.brand)
                }
                Spacer()
                Button {
                    Haptics.light()
                    // 免费可扫描查看，批量清理需解锁。
                    if purchase.isPro {
                        showDeleteConfirm = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        if !purchase.isPro {
                            Image(systemName: "lock.fill")
                        }
                        Text("cleanup.action")
                    }
                    .font(.headline)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - 状态视图

    private var noAccessView: some View {
        ContentUnavailableView {
            Label("access.title", systemImage: "lock.shield")
        } description: {
            Text("access.desc")
        } actions: {
            Button("access.openSettings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("scan.empty.title", systemImage: "sparkles")
        } description: {
            Text("scan.empty.desc")
        } actions: {
            Button("action.rescan") { Task { await startScan() } }
                .buttonStyle(.bordered)
        }
    }

    // MARK: - 动作

    private func startScan() async {
        viewModel.similarityThreshold = settings.similarityThreshold
        viewModel.blurSensitivity = settings.blurSensitivity
        await viewModel.scan()
    }

    private func performCleanup() async {
        do {
            let outcome = try await viewModel.deleteSelected()

            // 记录历史。
            let record = CleanupRecord(
                deletedCount: outcome.count,
                freedBytes: outcome.freed,
                category: "mixed"
            )
            modelContext.insert(record)

            result = CleanupResult(count: outcome.count, freed: outcome.freed)
            Haptics.success()
        } catch {
            deleteError = String(localized: "cleanup.error")
            Haptics.error()
        }
    }
}

/// 清理结果载体（用于 sheet item）。
private struct CleanupResult: Identifiable {
    let id = UUID()
    let count: Int
    let freed: Int64
}

#Preview {
    ContentView()
        .environment(PurchaseManager())
        .modelContainer(for: [AppSettings.self, CleanupRecord.self], inMemory: true)
}
