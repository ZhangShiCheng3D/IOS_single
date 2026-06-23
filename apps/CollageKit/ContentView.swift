//
//  ContentView.swift
//  CollageKit
//
//  根视图，承载首页。
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager())
        .modelContainer(for: [CollageProject.self, CollagePhoto.self,
                              CollageText.self, UserPreset.self], inMemory: true)
}
