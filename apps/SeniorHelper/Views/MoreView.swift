//
//  MoreView.swift
//  SeniorHelper
//
//  「更多」标签页：顶部紧急联系人快捷拨号，下方进入联系人管理与设置。
//  把一键拨号放在最显眼处，是银发场景的安全考量。
//

import SwiftUI
import SwiftData
import UIKit

struct MoreView: View {
    @Query(sort: \EmergencyContact.sortOrder)
    private var contacts: [EmergencyContact]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.padding) {
                    emergencyQuickDial
                    navigationCards
                }
                .padding(Theme.padding)
            }
            .background(Theme.pageBackground)
            .navigationTitle(Text("更多"))
        }
    }

    // MARK: - 紧急快捷拨号

    private var emergencyQuickDial: some View {
        VStack(alignment: .leading, spacing: Theme.smallPadding) {
            Label("紧急联系人", systemImage: "phone.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            if contacts.isEmpty {
                NavigationLink {
                    EmergencyContactView()
                } label: {
                    HStack {
                        Image(systemName: "phone.badge.plus")
                            .font(.title2)
                        Text("添加家人电话，紧急时一键拨打")
                            .font(.body.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(Theme.accent)
                }
                .cardStyle()
            } else {
                ForEach(contacts.prefix(3)) { contact in
                    QuickDialButton(contact: contact)
                }
            }
        }
    }

    // MARK: - 导航卡片

    private var navigationCards: some View {
        VStack(spacing: Theme.padding) {
            NavigationCard(
                icon: "phone.circle.fill",
                title: "管理紧急联系人",
                subtitle: "添加、编辑或删除联系人"
            ) {
                EmergencyContactView()
            }

            NavigationCard(
                icon: "gearshape.fill",
                title: "设置",
                subtitle: "语音、字号、通知与购买"
            ) {
                SettingsView()
            }
        }
    }
}

// MARK: - 快捷拨号大按钮

private struct QuickDialButton: View {
    @Environment(SpeechManager.self) private var speechManager
    let contact: EmergencyContact

    var body: some View {
        Button {
            dial()
        } label: {
            HStack(spacing: Theme.padding) {
                Image(systemName: "phone.fill")
                    .font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.title3.weight(.bold))
                    Text(contact.phoneNumber)
                        .font(.body.monospacedDigit())
                        .opacity(0.9)
                }
                Spacer()
            }
            .padding(Theme.padding)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.primaryButtonHeight)
            .background(Theme.callAction)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .accessibilityLabel(Text("拨打 \(contact.name)"))
    }

    private func dial() {
        Haptics.tap()
        speechManager.speak(String(format: String(localized: "正在拨打%@"), contact.name))
        guard let url = contact.dialURL, UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - 通用导航卡片

private struct NavigationCard<Destination: View>: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: Theme.padding) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .cardStyle()
        }
    }
}

#Preview {
    MoreView()
        .environment(PurchaseManager())
        .environment(SpeechManager())
        .modelContainer(for: [Medication.self, EmergencyContact.self], inMemory: true)
}
