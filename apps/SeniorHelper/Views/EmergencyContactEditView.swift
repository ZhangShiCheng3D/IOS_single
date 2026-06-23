//
//  EmergencyContactEditView.swift
//  SeniorHelper
//
//  新增 / 编辑紧急联系人。
//

import SwiftUI
import SwiftData

struct EmergencyContactEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil 表示新增。
    let contact: EmergencyContact?
    /// 新增时的排序序号。
    let nextSortOrder: Int

    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var relationship = ""

    private var isEditing: Bool { contact != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    field("称呼", text: $name, placeholder: "例如：女儿", keyboard: .default)
                    field("电话号码", text: $phoneNumber, placeholder: "例如：13800138000", keyboard: .phonePad)
                    field("关系（可选）", text: $relationship, placeholder: "例如：家人", keyboard: .default)
                } footer: {
                    Text("电话号码用于一键拨号，请填写完整可拨打的号码。")
                }
            }
            .navigationTitle(Text(isEditing ? "编辑联系人" : "添加联系人"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .font(.body.weight(.semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .font(.body.weight(.bold))
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func field(
        _ title: LocalizedStringKey,
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .font(.title3)
                .keyboardType(keyboard)
        }
        .padding(.vertical, 4)
    }

    private func loadExisting() {
        guard let contact, name.isEmpty else { return }
        name = contact.name
        phoneNumber = contact.phoneNumber
        relationship = contact.relationship
    }

    private func save() {
        guard canSave else { return }
        if let contact {
            contact.name = name.trimmingCharacters(in: .whitespaces)
            contact.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespaces)
            contact.relationship = relationship.trimmingCharacters(in: .whitespaces)
        } else {
            let new = EmergencyContact(
                name: name.trimmingCharacters(in: .whitespaces),
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces),
                relationship: relationship.trimmingCharacters(in: .whitespaces),
                sortOrder: nextSortOrder
            )
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

#Preview {
    EmergencyContactEditView(contact: nil, nextSortOrder: 0)
        .modelContainer(for: [Medication.self, EmergencyContact.self], inMemory: true)
}
