//
//  ContentView.swift
//  LumenPuzzle
//
//  主菜单。极简、克制：一束光、标题、几个入口。
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager

    /// 主光晕的呼吸动画状态。
    @State private var glow = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lumenBackground
                    .ignoresSafeArea()

                // 背景柔光：随呼吸缓缓放大缩小，呼应"光影"主题。
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.lumenAccent.opacity(0.55), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 260
                        )
                    )
                    .frame(width: 420, height: 420)
                    .scaleEffect(glow ? 1.08 : 0.92)
                    .opacity(glow ? 0.9 : 0.6)
                    .blur(radius: 8)
                    .offset(y: -120)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: glow)

                VStack(spacing: 0) {
                    Spacer()
                    header
                    Spacer()
                    menu
                    Spacer()
                    footer
                }
                .padding(.horizontal, 32)
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
            .onAppear { glow = true }
        }
    }

    // MARK: - 区块

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.lumenAccent)
                .shadow(color: Color.lumenAccent.opacity(0.6), radius: 18)
                .accessibilityHidden(true)

            Text("app.title")
                .font(.system(size: 40, weight: .semibold, design: .serif))
                .foregroundStyle(Color.lumenText)
                .tracking(2)

            Text("app.tagline")
                .font(.subheadline)
                .foregroundStyle(Color.lumenTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var menu: some View {
        VStack(spacing: 16) {
            NavigationLink(value: Route.levelSelect) {
                MenuButtonLabel(titleKey: "menu.play", systemImage: "play.fill", prominent: true)
            }
            NavigationLink(value: Route.achievements) {
                MenuButtonLabel(titleKey: "menu.achievements", systemImage: "rosette")
            }
            NavigationLink(value: Route.settings) {
                MenuButtonLabel(titleKey: "menu.settings", systemImage: "gearshape")
            }
        }
    }

    private var footer: some View {
        Text("menu.footer")
            .font(.caption2)
            .foregroundStyle(Color.lumenTextSecondary.opacity(0.7))
            .padding(.bottom, 12)
    }

    // MARK: - 路由

    enum Route: Hashable {
        case levelSelect
        case achievements
        case settings
        case game(Int)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .levelSelect:
            LevelSelectView()
        case .achievements:
            AchievementsView()
        case .settings:
            SettingsView()
        case .game(let levelID):
            if let level = LevelCatalog.level(id: levelID) {
                GameView(level: level)
            } else {
                Text("level.missing")
            }
        }
    }
}

/// 菜单按钮的统一样式。
private struct MenuButtonLabel: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    var prominent: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
            Text(titleKey)
                .font(.headline)
            Spacer()
        }
        .foregroundStyle(prominent ? Color.black : Color.lumenText)
        .padding(.vertical, 18)
        .padding(.horizontal, 22)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(prominent ? AnyShapeStyle(Color.lumenAccent) : AnyShapeStyle(Color.lumenSurface.opacity(0.5)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(prominent ? 0 : 0.08), lineWidth: 1)
        )
        .modifier(ConditionalAccentShadow(active: prominent))
    }
}

/// 仅对主操作按钮施加暖金辉光投影；次要按钮保持克制的扁平质感。
private struct ConditionalAccentShadow: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active { content.lumenAccentShadow() } else { content }
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager())
        .modelContainer(for: [LevelProgress.self, AchievementRecord.self], inMemory: true)
}
