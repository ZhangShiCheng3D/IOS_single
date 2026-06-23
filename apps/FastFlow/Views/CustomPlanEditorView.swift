//
//  CustomPlanEditorView.swift
//  FastFlow
//
//  自定义断食方案编辑器（高级功能）。设定断食/进食小时数与名称。
//

import SwiftUI

struct CustomPlanEditorView: View {
    /// 保存回调：(名称, 断食小时, 进食小时)。
    let onSave: (String, Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var fastingHours = 16
    @State private var eatingHours = 8

    /// 断食 + 进食应等于 24 小时，UI 引导但不强制。
    private var totalHours: Int { fastingHours + eatingHours }

    var body: some View {
        NavigationStack {
            Form {
                Section("plan.custom.name") {
                    TextField("plan.custom.name.placeholder", text: $name)
                }

                Section {
                    Stepper(value: $fastingHours, in: 1...23) {
                        labelRow(titleKey: "plan.custom.fasting", value: fastingHours)
                    }
                    .onChange(of: fastingHours) { _, newValue in
                        eatingHours = max(1, 24 - newValue)
                    }
                    Stepper(value: $eatingHours, in: 1...23) {
                        labelRow(titleKey: "plan.custom.eating", value: eatingHours)
                    }
                    .onChange(of: eatingHours) { _, newValue in
                        fastingHours = max(1, 24 - newValue)
                    }
                } header: {
                    Text("plan.custom.window")
                } footer: {
                    Text(String(
                        format: NSLocalizedString("plan.custom.total.format", comment: ""),
                        totalHours
                    ))
                    .foregroundStyle(totalHours == 24 ? .secondary : .orange)
                }

                Section {
                    previewCard
                }
            }
            .navigationTitle("plan.custom.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        onSave(name.trimmingCharacters(in: .whitespaces), fastingHours, eatingHours)
                        dismiss()
                    }
                }
            }
        }
    }

    private func labelRow(titleKey: LocalizedStringKey, value: Int) -> some View {
        HStack {
            Text(titleKey)
            Spacer()
            Text(String(format: NSLocalizedString("plan.custom.hours", comment: ""), value))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var previewCard: some View {
        HStack {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading) {
                Text(name.isEmpty ? "\(fastingHours):\(eatingHours)" : name)
                    .font(.headline)
                Text(String(
                    format: NSLocalizedString("plan.subtitle.format", comment: ""),
                    fastingHours, eatingHours
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CustomPlanEditorView { _, _, _ in }
}
