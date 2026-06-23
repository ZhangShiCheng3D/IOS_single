//
//  ContentView.swift
//  PixelStudio
//
//  根视图。当前作品库即首页，后续如需 Tab 可在此扩展。
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GalleryView()
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
        .environmentObject(PurchaseManager())
}
