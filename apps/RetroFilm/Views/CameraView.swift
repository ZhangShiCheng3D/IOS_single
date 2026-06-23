//
//  CameraView.swift
//  RetroFilm
//
//  The viewfinder. Shows a live, film-filtered preview and hosts all capture
//  controls: the film wheel, shutter, fine-tune panel, and top toolbar.
//

import SwiftUI
import SwiftData
import AVFoundation

struct CameraView: View {
    @EnvironmentObject private var store: PurchaseManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var camera = CameraViewModel()

    /// Hop to the gallery tab after saving (provided by ContentView).
    var onSwitchToGallery: () -> Void = {}

    @State private var showAdjustments = false
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var lastSavedThumb: UIImage?
    @State private var saveConfirmation = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                preview(in: geo.size)

                // White shutter flash.
                if camera.flashScreen {
                    Color.white.ignoresSafeArea().transition(.opacity)
                }

                VStack {
                    topToolbar
                    Spacer()
                    bottomControls
                }
                .padding(.horizontal)

                if camera.permissionDenied {
                    permissionOverlay
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onAppear {
            camera.stock = store.isAvailable(camera.stock) ? camera.stock : .kodakGold
            camera.onPhotoCaptured = handleCapture
            camera.start()
        }
        .onDisappear { camera.stop() }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
        .sheet(isPresented: $showAdjustments) {
            AdjustmentPanel(settings: $camera.settings)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) { saveToast }
    }

    // MARK: - Preview

    @ViewBuilder
    private func preview(in size: CGSize) -> some View {
        ZStack {
            if let cg = camera.previewImage {
                Image(decorative: cg, scale: 1, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        focusTap(at: location, in: size)
                    }
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
    }

    private func focusTap(at location: CGPoint, in size: CGSize) {
        let normalized = CGPoint(x: location.y / size.height, y: 1 - location.x / size.width)
        camera.focus(at: normalized)
        HapticManager.selection()
    }

    // MARK: - Top toolbar

    private var topToolbar: some View {
        HStack {
            toolbarButton(camera.torchOn ? "bolt.fill" : "bolt.slash.fill", label: "a11y.flash") {
                camera.toggleTorch()
            }
            .disabled(camera.cameraPosition == .front)

            Spacer()

            Toggle(isOn: $camera.settings.dateStampEnabled) {
                Label("camera.datestamp", systemImage: "calendar")
            }
            .toggleStyle(.button)
            .labelStyle(.iconOnly)
            .tint(camera.settings.dateStampEnabled ? Theme.accent : .white)
            .font(.title3)
            .padding(8)
            .background(.ultraThinMaterial, in: Circle())

            Spacer()

            toolbarButton("gearshape.fill", label: "settings.title") { showSettings = true }
        }
        .padding(.top, 8)
    }

    private func toolbarButton(_ icon: String,
                               label: LocalizedStringKey,
                               action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel(Text(label))
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            FilmWheelView(
                selected: $camera.stock,
                isUnlocked: store.isUnlocked,
                onLockedTapped: { showPaywall = true }
            )

            HStack(alignment: .center) {
                // Gallery shortcut / last photo thumbnail.
                Button(action: onSwitchToGallery) {
                    Group {
                        if let thumb = lastSavedThumb {
                            Image(uiImage: thumb).resizable().scaledToFill()
                        } else {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.3)))
                }
                .accessibilityLabel(Text("tab.gallery"))

                Spacer()

                ShutterButton(isCapturing: camera.isCapturing) {
                    camera.capturePhoto()
                }

                Spacer()

                VStack(spacing: 10) {
                    toolbarButton("arrow.triangle.2.circlepath.camera.fill", label: "a11y.switchCamera") {
                        camera.switchCamera()
                    }
                    toolbarButton("slider.horizontal.3", label: "adjust.title") {
                        showAdjustments = true
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Overlays

    private var permissionOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("camera.permission.title").font(.headline)
            Text("camera.permission.body")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("camera.permission.open") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.85))
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var saveToast: some View {
        if saveConfirmation {
            Label("camera.saved", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .softShadow(radius: 10, y: 4)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Capture handling

    /// Persists the captured pair into SwiftData + disk and shows a toast.
    private func handleCapture(original: UIImage, rendered: UIImage) {
        let id = UUID()
        do {
            let files = try PhotoStorage.shared.save(original: original, rendered: rendered, id: id)
            let photo = CapturedPhoto(
                id: id,
                filmStockID: camera.stock.id,
                settings: camera.settings,
                originalFileName: files.original,
                renderedFileName: files.rendered,
                thumbnailFileName: files.thumbnail
            )
            modelContext.insert(photo)
            try? modelContext.save()

            lastSavedThumb = rendered.downscaled(toMaxDimension: 120)
            withAnimation(.spring) { saveConfirmation = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation { saveConfirmation = false }
            }
        } catch {
            HapticManager.warning()
        }
    }
}

// MARK: - Shutter button

private struct ShutterButton: View {
    let isCapturing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: Theme.shutterSize, height: Theme.shutterSize)
                Circle()
                    .fill(Theme.warmGradient)
                    .frame(width: Theme.shutterSize - 16, height: Theme.shutterSize - 16)
                    .scaleEffect(isCapturing ? 0.82 : 1)
                    .animation(.spring(response: 0.2), value: isCapturing)
            }
        }
        .accessibilityLabel(Text("camera.shutter"))
        .disabled(isCapturing)
    }
}

#Preview {
    CameraView()
        .environmentObject(PurchaseManager())
        .modelContainer(for: CapturedPhoto.self, inMemory: true)
}
