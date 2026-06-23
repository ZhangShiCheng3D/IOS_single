//
//  ContentView.swift
//  RetroFilm
//
//  Root container. A two-tab experience: the camera (capture) and the library
//  (browse + re-edit). The camera is the default and visually dominant screen.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PurchaseManager
    @State private var selectedTab: Tab = .camera

    enum Tab: Hashable { case camera, gallery }

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView(onSwitchToGallery: { selectedTab = .gallery })
                .tag(Tab.camera)
                .tabItem {
                    Label("tab.camera", systemImage: "camera.fill")
                }

            GalleryView()
                .tag(Tab.gallery)
                .tabItem {
                    Label("tab.gallery", systemImage: "photo.stack.fill")
                }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager())
        .modelContainer(for: CapturedPhoto.self, inMemory: true)
}
