//
//  ContentView.swift
//  DocScanPro
//
//  应用根视图。底部 Tab 导航：文档库 / 文件夹 / 设置。
//  中央悬浮按钮发起扫描。
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var appSettings: AppSettings

    /// 当前选中 Tab。
    @State private var selectedTab: Tab = .library

    /// 是否展示扫描相机。
    @State private var isShowingScanner = false

    /// 是否展示付费墙。
    @State private var isShowingPaywall = false

    enum Tab: Hashable {
        case library, folders, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DocumentListView(onScan: startScan)
                .tabItem {
                    Label("tab.library", systemImage: "doc.text.fill")
                }
                .tag(Tab.library)

            FolderListView()
                .tabItem {
                    Label("tab.folders", systemImage: "folder.fill")
                }
                .tag(Tab.folders)

            SettingsView(onShowPaywall: { isShowingPaywall = true })
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.accentColor)
        .overlay(alignment: .bottom) {
            scanFloatingButton
        }
        .fullScreenCover(isPresented: $isShowingScanner) {
            ScanFlowView(targetFolder: nil)
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
    }

    /// 中央扫描悬浮按钮，位于 Tab 栏上方。
    private var scanFloatingButton: some View {
        Button {
            startScan()
        } label: {
            Image(systemName: "doc.viewfinder.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle().fill(Color.accentColor)
                        .dsShadow(.accent(.accentColor))
                )
        }
        .accessibilityLabel(Text("scan.start"))
        .accessibilityHint(Text("scan.start.hint"))
        .padding(.bottom, 54)
    }

    private func startScan() {
        Haptics.tapMedium()
        isShowingScanner = true
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager.shared)
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
