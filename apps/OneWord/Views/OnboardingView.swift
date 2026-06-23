//
//  OnboardingView.swift
//  OneWord
//
//  First-run, three-page introduction shown once. Frames the three pillars
//  international users need up front: zero-pressure journaling, on-device
//  insight, and the privacy promise.
//

import SwiftUI

struct OnboardingView: View {
    /// Set to true when the user finishes or skips onboarding.
    @Binding var done: Bool

    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let glyph: String
        let title: LocalizedStringKey
        let body: LocalizedStringKey
    }

    private let pages: [Page] = [
        Page(glyph: "✍️", title: "onboarding.p1.title", body: "onboarding.p1.body"),
        Page(glyph: "🧠", title: "onboarding.p2.title", body: "onboarding.p2.body"),
        Page(glyph: "🔒", title: "onboarding.p3.title", body: "onboarding.p3.body")
    ]

    var body: some View {
        VStack {
            HStack {
                Spacer()
                if page < pages.count - 1 {
                    Button("onboarding.skip") { finish() }
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: Theme.Spacing.lg) {
                        Text(item.glyph).font(.system(size: 72))
                        Text(item.title)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        Text(item.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page == pages.count - 1 ? "onboarding.start" : "onboarding.next") {
                if page == pages.count - 1 {
                    finish()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func finish() {
        withAnimation { done = true }
    }
}

#Preview {
    OnboardingView(done: .constant(false))
}
