//
//  PhotoPickerButton.swift
//  OneWord
//
//  PhotosPicker wrapper that loads a chosen image, downsizes it, and returns
//  JPEG data. Keeps the SwiftData store light by capping the stored size.
//

import SwiftUI
import PhotosUI

struct PhotoPickerButton: View {
    @Binding var photoData: Data?
    var onChange: (() -> Void)?

    @State private var selection: PhotosPickerItem?

    /// Max edge length for stored photos.
    private let maxDimension: CGFloat = 1280

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if let data = photoData, let image = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))

                    Button {
                        photoData = nil
                        selection = nil
                        onChange?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.4))
                            .padding(Theme.Spacing.sm)
                    }
                    .accessibilityLabel("editor.removePhoto")
                }
            }

            PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                Label(
                    photoData == nil ? "editor.addPhoto" : "editor.changePhoto",
                    systemImage: "photo.on.rectangle.angled"
                )
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .fill(Theme.accent.opacity(0.12))
                )
                .foregroundStyle(Theme.accent)
            }
        }
        .onChange(of: selection) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        let resized = image.downsized(to: maxDimension)
        let jpeg = resized.jpegData(compressionQuality: 0.8)
        await MainActor.run {
            photoData = jpeg
            onChange?()
        }
    }
}

private extension UIImage {
    /// Scales the image down so its longest edge is at most `maxEdge`.
    func downsized(to maxEdge: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxEdge else { return self }

        let scale = maxEdge / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

#Preview {
    StatefulPreviewWrapper(Data?.none) { binding in
        PhotoPickerButton(photoData: binding)
            .padding()
    }
}
