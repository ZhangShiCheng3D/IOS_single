//
//  ContentView.swift
//  BakeCalc
//
//  主界面：烘焙工具仪表盘。以卡片网格陈列全部计算器，
//  专业功能带皇冠角标，点击后由各页面的 ProGate 处理解锁分流。
//

import SwiftUI

/// 仪表盘上的一个功能入口描述。
struct FeatureEntry: Identifiable {
    let id = UUID()
    let feature: AppFeature
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey
    let systemImage: String
    let tint: Color
}

struct ContentView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager

    /// 功能分区：基础（免费）与专业。
    private let freeFeatures: [FeatureEntry] = [
        .init(feature: .unitConversion, titleKey: "feature.unitConversion",
              subtitleKey: "feature.unitConversion.sub", systemImage: "scalemass.fill", tint: .orange),
        .init(feature: .temperature, titleKey: "feature.temperature",
              subtitleKey: "feature.temperature.sub", systemImage: "thermometer.medium", tint: .red),
        .init(feature: .ovenReference, titleKey: "feature.ovenReference",
              subtitleKey: "feature.ovenReference.sub", systemImage: "oven.fill", tint: .brown)
    ]

    private let proFeatures: [FeatureEntry] = [
        .init(feature: .recipeScaling, titleKey: "feature.recipeScaling",
              subtitleKey: "feature.recipeScaling.sub", systemImage: "arrow.up.left.and.arrow.down.right", tint: .pink),
        .init(feature: .densityTable, titleKey: "feature.densityTable",
              subtitleKey: "feature.densityTable.sub", systemImage: "list.bullet.rectangle.fill", tint: .teal),
        .init(feature: .savedRecipes, titleKey: "feature.savedRecipes",
              subtitleKey: "feature.savedRecipes.sub", systemImage: "book.closed.fill", tint: .indigo),
        .init(feature: .panConversion, titleKey: "feature.panConversion",
              subtitleKey: "feature.panConversion.sub", systemImage: "circle.grid.cross.fill", tint: .purple),
        .init(feature: .eggConversion, titleKey: "feature.eggConversion",
              subtitleKey: "feature.eggConversion.sub", systemImage: "oval.portrait.fill", tint: .yellow)
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCMetrics.sectionSpacing) {
                    if !purchaseManager.isPro {
                        upgradeBanner
                    }

                    section(titleKey: "home.section.basic", entries: freeFeatures)
                    section(titleKey: "home.section.pro", entries: proFeatures)
                }
                .padding()
            }
            .background(Color.bcBackground.ignoresSafeArea())
            .navigationTitle(Text("app.name"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel(Text("settings.title"))
                }
            }
            .navigationDestination(for: AppFeature.self) { feature in
                destination(for: feature)
            }
        }
    }

    // MARK: - 分区与卡片

    private func section(titleKey: LocalizedStringKey, entries: [FeatureEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titleKey)
                .font(.headline)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(entries) { entry in
                    NavigationLink(value: entry.feature) {
                        FeatureCard(
                            entry: entry,
                            locked: !purchaseManager.isUnlocked(entry.feature)
                        )
                    }
                    .buttonStyle(BCPressableStyle())
                }
            }
        }
    }

    private var upgradeBanner: some View {
        NavigationLink(value: AppFeature.recipeScaling) {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("home.banner.title")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("home.banner.subtitle")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(16)
            .background(
                LinearGradient(colors: [Color.bcAccent, Color.bcSecondary],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: BCMetrics.cornerRadius, style: .continuous))
            .shadow(color: Color.bcAccent.opacity(0.25), radius: 10, y: 4)
        }
        .buttonStyle(BCPressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 路由

    @ViewBuilder
    private func destination(for feature: AppFeature) -> some View {
        switch feature {
        case .unitConversion:
            UnitConversionView()
        case .temperature:
            TemperatureView()
        case .ovenReference:
            OvenReferenceView()
        case .recipeScaling:
            RecipeScalingView().proGate(.recipeScaling, titleKey: "feature.recipeScaling")
        case .densityTable:
            IngredientDensityView().proGate(.densityTable, titleKey: "feature.densityTable")
        case .savedRecipes:
            SavedRecipesView().proGate(.savedRecipes, titleKey: "feature.savedRecipes")
        case .panConversion:
            PanConversionView().proGate(.panConversion, titleKey: "feature.panConversion")
        case .eggConversion:
            EggConversionView().proGate(.eggConversion, titleKey: "feature.eggConversion")
        }
    }
}

/// 仪表盘功能卡片。
private struct FeatureCard: View {
    let entry: FeatureEntry
    let locked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: entry.systemImage)
                    .font(.title2)
                    .foregroundStyle(entry.tint)
                    .frame(width: BCMetrics.iconSize, height: BCMetrics.iconSize)
                Spacer()
                if locked {
                    ProBadge()
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.titleKey)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(entry.subtitleKey)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(14)
        .background(Color.bcCard)
        .clipShape(RoundedRectangle(cornerRadius: BCMetrics.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("主界面") {
    ContentView()
        .environmentObject(PurchaseManager())
        .modelContainer(for: [SavedRecipe.self, SavedIngredient.self], inMemory: true)
}
