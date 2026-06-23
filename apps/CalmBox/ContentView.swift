//
//  ContentView.swift
//  CalmBox
//
//  主界面：展示解压场景网格，处理导航与付费墙弹出。
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(HapticManager.self) private var haptics

    @Query(sort: \FavoriteRecord.createdAt, order: .reverse)
    private var favorites: [FavoriteRecord]
    @Environment(\.modelContext) private var modelContext

    @State private var path = NavigationPath()
    @State private var showPaywall = false
    @State private var showSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: AppConstants.Design.cardSpacing),
        GridItem(.flexible(), spacing: AppConstants.Design.cardSpacing)
    ]

    /// 收藏的场景 id 集合，便于快速查询。
    private var favoriteIDs: Set<String> {
        Set(favorites.map(\.sceneID))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !favorites.isEmpty {
                        favoritesSection
                    }
                    allScenesSection
                    if !purchaseManager.hasUnlockedAll {
                        unlockBanner
                    }
                }
                .padding(AppConstants.Design.contentPadding)
            }
            .background(backgroundGradient)
            .navigationTitle("app.name")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("settings.title")
                }
            }
            .navigationDestination(for: RelaxScene.self) { scene in
                destination(for: scene)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - 区块

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("home.favorites", systemImage: "heart.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favoriteScenes) { scene in
                        Button {
                            open(scene)
                        } label: {
                            FavoriteChip(scene: scene)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var allScenesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("home.allScenes", systemImage: "square.grid.2x2.fill")
            LazyVGrid(columns: columns, spacing: AppConstants.Design.cardSpacing) {
                ForEach(RelaxScene.catalog) { scene in
                    SceneCard(
                        scene: scene,
                        isLocked: scene.isPremium && !purchaseManager.hasUnlockedAll,
                        isFavorite: favoriteIDs.contains(scene.id),
                        onTap: { open(scene) },
                        onToggleFavorite: { toggleFavorite(scene) }
                    )
                }
            }
        }
    }

    private var unlockBanner: some View {
        Button {
            haptics.playSelection()
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "lock.open.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("home.unlock.title")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("home.unlock.subtitle")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(18)
            .background(
                LinearGradient(colors: Theme.Palette.brandGradient,
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadius)
            )
            .cardShadow(Theme.Palette.brandStart)
        }
        .buttonStyle(.plain)
        .accessibilityHint("home.unlock.subtitle")
    }

    // MARK: - 辅助视图

    private func sectionHeader(_ key: LocalizedStringKey, systemImage: String) -> some View {
        Label(key, systemImage: systemImage)
            .font(.title3.bold())
            .foregroundStyle(.primary)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Theme.Palette.surfaceTint.opacity(0.3)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func destination(for scene: RelaxScene) -> some View {
        switch scene.kind {
        case .bubbleWrap: BubbleWrapView()
        case .spinner: SpinnerView()
        case .whiteNoise: WhiteNoiseView()
        case .breathing: BreathingView()
        case .meditation: MeditationTimerView()
        }
    }

    // MARK: - 数据

    private var favoriteScenes: [RelaxScene] {
        favorites.compactMap { RelaxScene.scene(for: $0.sceneID) }
    }

    // MARK: - 动作

    private func open(_ scene: RelaxScene) {
        haptics.playSelection()
        if scene.isPremium && !purchaseManager.hasUnlockedAll {
            showPaywall = true
        } else {
            path.append(scene)
        }
    }

    private func toggleFavorite(_ scene: RelaxScene) {
        haptics.playSelection()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let existing = favorites.first(where: { $0.sceneID == scene.id }) {
                modelContext.delete(existing)
            } else {
                modelContext.insert(FavoriteRecord(sceneID: scene.id))
            }
            try? modelContext.save()
        }
    }
}

// MARK: - 收藏快捷入口

private struct FavoriteChip: View {
    let scene: RelaxScene

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: scene.systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(colors: scene.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18)
                )
            Text(scene.titleKey)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(width: 72)
    }
}

#Preview {
    ContentView()
        .environment(PurchaseManager())
        .environment(AudioManager())
        .environment(HapticManager())
        .modelContainer(for: [FavoriteRecord.self, MeditationSession.self, MixerPreset.self], inMemory: true)
}
