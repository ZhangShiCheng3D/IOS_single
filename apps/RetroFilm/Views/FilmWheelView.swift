//
//  FilmWheelView.swift
//  RetroFilm
//
//  Horizontal, snap-scrolling selector of film stocks — the signature control
//  of the camera screen. Premium stocks show a lock until purchased and, when
//  tapped, route to the paywall instead of selecting.
//

import SwiftUI

struct FilmWheelView: View {
    @Binding var selected: FilmStock
    let isUnlocked: Bool
    let onLockedTapped: () -> Void

    private let stocks = FilmStock.catalog

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(stocks) { stock in
                        chip(for: stock)
                            .id(stock.id)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(height: Theme.filmStripHeight)
            .onAppear {
                proxy.scrollTo(selected.id, anchor: .center)
            }
            .onChange(of: selected) { _, new in
                withAnimation(.spring(response: 0.35)) {
                    proxy.scrollTo(new.id, anchor: .center)
                }
            }
        }
    }

    private func chip(for stock: FilmStock) -> some View {
        let isSelected = stock.id == selected.id
        let locked = stock.isPremium && !isUnlocked

        return Button {
            if locked {
                onLockedTapped()
            } else if !isSelected {
                selected = stock
                HapticManager.selection()
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(stock.swatch.gradient)
                        .frame(width: 58, height: 58)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: isSelected ? Theme.accent.opacity(0.55) : .clear,
                                radius: 9, y: 2)
                        .overlay(
                            Text(stock.shortLabel)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        )
                        .opacity(locked ? 0.55 : 1)

                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(.black.opacity(0.5), in: Circle())
                            .offset(x: 20, y: -20)
                    }
                }
                Text(LocalizedStringKey(stock.id))
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                    .lineLimit(1)
                    .fixedSize()
            }
            .scaleEffect(isSelected ? 1.05 : 1)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedStringKey(stock.id)))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(locked ? Text("a11y.locked") : Text(""))
    }
}

#Preview {
    ZStack {
        Color.black
        FilmWheelView(selected: .constant(.kodakGold), isUnlocked: false, onLockedTapped: {})
    }
}
