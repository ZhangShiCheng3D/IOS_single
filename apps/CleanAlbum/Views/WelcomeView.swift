//
//  WelcomeView.swift
//  CleanAlbum
//
//  首次进入的欢迎/扫描引导页。突出隐私卖点。
//

import SwiftUI

struct WelcomeView: View {
    let onScan: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                hero
                privacyPoints
                scanButton
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
    }

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.brand.opacity(0.3), .brand.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 130, height: 130)
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Color.brand)
            }
            .padding(.top, 32)

            Text("welcome.title")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("welcome.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var privacyPoints: some View {
        VStack(spacing: 14) {
            WelcomePoint(icon: "lock.shield.fill", titleKey: "welcome.point.privacy", descKey: "welcome.point.privacy.desc")
            WelcomePoint(icon: "cpu.fill", titleKey: "welcome.point.onDevice", descKey: "welcome.point.onDevice.desc")
            WelcomePoint(icon: "wand.and.stars", titleKey: "welcome.point.smart", descKey: "welcome.point.smart.desc")
        }
    }

    private var scanButton: some View {
        Button(action: onScan) {
            Label("welcome.scan", systemImage: "magnifyingglass")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(colors: [.brand, .brand.opacity(0.8)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 8)
    }
}

private struct WelcomePoint: View {
    let icon: String
    let titleKey: LocalizedStringKey
    let descKey: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.brand)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(titleKey).font(.subheadline.weight(.semibold))
                Text(descKey).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .cardSurface()
    }
}

#Preview {
    WelcomeView(onScan: {})
}
