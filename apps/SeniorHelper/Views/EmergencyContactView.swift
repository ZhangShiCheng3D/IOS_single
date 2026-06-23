//
//  EmergencyContactView.swift
//  SeniorHelper
//
//  紧急联系人管理：新增 / 编辑 / 删除 / 一键拨号。
//

import SwiftUI
import SwiftData
import UIKit

struct EmergencyContactView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \EmergencyContact.sortOrder)
    private var contacts: [EmergencyContact]

    @State private var editingContact: EmergencyContact?
    @State private var isCreating = false

    var body: some View {
        Group {
            if contacts.isEmpty {
                emptyView
            } else {
                contactList
            }
        }
        .background(Theme.pageBackground)
        .navigationTitle(Text("紧急联系人"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    isCreating = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .accessibilityLabel(Text("添加联系人"))
                }
            }
        }
        .sheet(isPresented: $isCreating) {
            EmergencyContactEditView(contact: nil, nextSortOrder: contacts.count)
        }
        .sheet(item: $editingContact) { contact in
            EmergencyContactEditView(contact: contact, nextSortOrder: contact.sortOrder)
        }
    }

    private var contactList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.padding) {
                ForEach(contacts) { contact in
                    ContactCard(
                        contact: contact,
                        onEdit: { editingContact = contact },
                        onDelete: { delete(contact) }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(Theme.padding)
            .animation(.snappy(duration: 0.3), value: contacts.count)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("还没有紧急联系人", systemImage: "phone.badge.plus")
        } description: {
            Text("添加家人或医生的电话，紧急时一键拨打")
                .font(.title3)
        } actions: {
            Button {
                isCreating = true
            } label: {
                Text("添加联系人")
            }
            .buttonStyle(.seniorPrimary)
            .padding(.horizontal, Theme.largePadding)
        }
    }

    private func delete(_ contact: EmergencyContact) {
        context.delete(contact)
        try? context.save()
    }
}

// MARK: - 联系人卡片（含大号拨号按钮）

private struct ContactCard: View {
    @Environment(SpeechManager.self) private var speechManager
    let contact: EmergencyContact
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: Theme.smallPadding) {
            HStack(spacing: Theme.padding) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.title2.weight(.bold))
                    if !contact.relationship.isEmpty {
                        Text(contact.relationship)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    Text(contact.phoneNumber)
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            // 大号拨号按钮
            Button {
                dial()
            } label: {
                Label("拨打电话", systemImage: "phone.fill")
            }
            .buttonStyle(.seniorPrimary(background: Theme.callAction))
            .accessibilityHint(Text("拨打 \(contact.name) 的电话"))

            HStack(spacing: Theme.padding) {
                Button(action: onEdit) {
                    Label("编辑", systemImage: "square.and.pencil")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("删除", systemImage: "trash")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderless)
            }
        }
        .cardStyle()
        .confirmationDialog(
            Text("确定删除「\(contact.name)」吗？"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive, action: onDelete)
            Button("取消", role: .cancel) {}
        }
    }

    private func dial() {
        Haptics.tap()
        speechManager.speak(String(format: String(localized: "正在拨打%@"), contact.name))
        guard let url = contact.dialURL, UIApplication.shared.canOpenURL(url) else {
            speechManager.speak(String(localized: "电话号码无效"), force: true)
            return
        }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        EmergencyContactView()
    }
    .environment(SpeechManager())
    .modelContainer(for: [Medication.self, EmergencyContact.self], inMemory: true)
}
