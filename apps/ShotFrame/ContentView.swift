//
//  ContentView.swift
//  ShotFrame
//
//  Root view. The library of saved projects is the home screen; everything
//  else is reached from there.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        LibraryView()
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager())
        .modelContainer(for: ShotProject.self, inMemory: true)
}
