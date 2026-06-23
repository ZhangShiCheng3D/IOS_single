//
//  ContentView.swift
//  SeniorHelper
//
//  主界面：极简 3 标签导航——放大镜 / 用药提醒 / 更多。
//  标签栏图标与文字均放大，符合银发友好原则。
//

import SwiftUI

struct ContentView: View {
    @Environment(SpeechManager.self) private var speechManager

    /// 当前选中的标签，便于切换时语音播报页面名。
    @State private var selection: Tab = .magnifier

    enum Tab: Hashable {
        case magnifier, medication, more
    }

    var body: some View {
        TabView(selection: $selection) {
            MagnifierView()
                .tabItem {
                    Label("放大镜", systemImage: "magnifyingglass.circle.fill")
                }
                .tag(Tab.magnifier)

            MedicationListView()
                .tabItem {
                    Label("用药提醒", systemImage: "pills.circle.fill")
                }
                .tag(Tab.medication)

            MoreView()
                .tabItem {
                    Label("更多", systemImage: "person.crop.circle.fill")
                }
                .tag(Tab.more)
        }
        .tint(Theme.accent)
        .onChange(of: selection) { _, newValue in
            speak(for: newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { note in
            // Siri 快捷指令触发的标签切换。
            guard let raw = note.userInfo?[ShortcutTarget.key] as? String,
                  let target = ShortcutTarget(rawValue: raw) else { return }
            switch target {
            case .magnifier: selection = .magnifier
            case .medication: selection = .medication
            }
        }
    }

    /// 切换标签时语音提示当前页面。
    private func speak(for tab: Tab) {
        let name: String
        switch tab {
        case .magnifier: name = String(localized: "放大镜")
        case .medication: name = String(localized: "用药提醒")
        case .more: name = String(localized: "更多")
        }
        speechManager.speak(name)
    }
}

#Preview {
    ContentView()
        .environment(PurchaseManager())
        .environment(SpeechManager())
        .modelContainer(for: [Medication.self, EmergencyContact.self], inMemory: true)
}
