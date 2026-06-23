//
//  GalleryView.swift
//  RetroFilm
//
//  The in-app library. A SwiftData @Query renders captured photos newest-first
//  in a thumbnail grid; tapping opens the detail / re-edit screen.
//

import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CapturedPhoto.createdAt, order: .reverse) private var photos: [CapturedPhoto]

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 3)]

    var body: some View {
        NavigationStack {
            Group {
                if photos.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 3) {
                            ForEach(photos) { photo in
                                NavigationLink(value: photo) {
                                    Thumbnail(photo: photo)
                                }
                            }
                        }
                        .padding(.horizontal, 3)
                    }
                }
            }
            .navigationTitle("gallery.title")
            .navigationDestination(for: CapturedPhoto.self) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("gallery.empty.title", systemImage: "photo.stack")
        } description: {
            Text("gallery.empty.body")
        }
    }
}

/// A single grid cell. Loads its thumbnail off the main thread and shows the
/// film badge so the look is recognizable at a glance.
private struct Thumbnail: View {
    let photo: CapturedPhoto
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: geo.size.width, height: geo.size.width)
                        .overlay(ProgressView())
                }

                Text(photo.filmStock.shortLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(.black.opacity(0.45), in: Capsule())
                    .padding(5)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("a11y.photoPrefix") + Text(" ") + Text(LocalizedStringKey(photo.filmStock.id)))
        .accessibilityAddTraits(.isButton)
        .task {
            if image == nil {
                let name = photo.thumbnailFileName
                image = await Task.detached { PhotoStorage.shared.load(name) }.value
            }
        }
    }
}

#Preview {
    GalleryView()
        .modelContainer(for: CapturedPhoto.self, inMemory: true)
}
