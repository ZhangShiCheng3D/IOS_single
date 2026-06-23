//
//  RootView.swift
//  OneWord
//
//  Top-level container that overlays the privacy lock when enabled, and
//  re-locks when the app leaves the foreground.
//

import SwiftUI

struct RootView: View {
    @Environment(AppLock.self) private var appLock
    @Environment(\.scenePhase) private var scenePhase

    /// First-run flag. Onboarding shows until the user finishes or skips it.
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var onboardingDone = false

    var body: some View {
        ContentView()
            .overlay {
                if appLock.isLocked {
                    LockView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: appLock.isLocked)
            .fullScreenCover(isPresented: .constant(!hasOnboarded)) {
                OnboardingView(done: $onboardingDone)
                    .onChange(of: onboardingDone) { _, done in
                        if done { hasOnboarded = true }
                    }
            }
            .onChange(of: scenePhase) { _, phase in
                // Re-lock as soon as we leave the foreground so a quick glance
                // at the app switcher doesn't reveal the journal.
                if phase == .background {
                    appLock.lock()
                }
            }
    }
}

#Preview {
    RootView()
        .environment(AppLock())
        .environment(PurchaseManager())
        .modelContainer(PreviewData.container)
}
