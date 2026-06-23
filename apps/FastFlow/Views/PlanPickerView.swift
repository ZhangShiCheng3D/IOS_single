//
//  PlanPickerView.swift
//  FastFlow
//
//  断食方案选择器。内置方案 + 自定义方案（高级功能，受付费墙保护）。
//

import SwiftUI
import SwiftData

struct PlanPickerView: View {
    @Binding var selectedPlanID: UUID?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager

    @Query(sort: \FastingPlan.createdAt, order: .forward) private var plans: [FastingPlan]

    @State private var showCustomEditor = false
    @State private var showPaywall = false

    private var builtInPlans: [FastingPlan] { plans.filter { !$0.isCustom } }
    private var customPlans: [FastingPlan] { plans.filter { $0.isCustom } }

    var body: some View {
        NavigationStack {
            List {
                Section("plan.section.builtin") {
                    ForEach(builtInPlans) { plan in
                        planRow(plan)
                    }
                }

                Section {
                    ForEach(customPlans) { plan in
                        planRow(plan)
                    }
                    .onDelete(perform: deleteCustom)

                    Button {
                        if purchaseManager.isPremiumUnlocked {
                            showCustomEditor = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Label {
                            HStack {
                                Text("plan.addCustom")
                                if !purchaseManager.isPremiumUnlocked {
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                } header: {
                    Text("plan.section.custom")
                } footer: {
                    if !purchaseManager.isPremiumUnlocked {
                        Text("plan.custom.locked.footer")
                    }
                }
            }
            .navigationTitle("plan.picker.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCustomEditor) {
                CustomPlanEditorView { name, fasting, eating in
                    addCustomPlan(name: name, fasting: fasting, eating: eating)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func planRow(_ plan: FastingPlan) -> some View {
        Button {
            selectedPlanID = plan.id
            Haptics.tap()
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name).font(.headline)
                    Text(plan.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if plan.id == selectedPlanID {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func addCustomPlan(name: String, fasting: Int, eating: Int) {
        let plan = FastingPlan(
            name: name.isEmpty ? "\(fasting):\(eating)" : name,
            fastingHours: fasting,
            eatingHours: eating,
            isCustom: true
        )
        modelContext.insert(plan)
        try? modelContext.save()
        selectedPlanID = plan.id
    }

    private func deleteCustom(at offsets: IndexSet) {
        for index in offsets {
            let plan = customPlans[index]
            if plan.id == selectedPlanID { selectedPlanID = builtInPlans.first?.id }
            modelContext.delete(plan)
        }
        try? modelContext.save()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: FastingSession.self, FastingPlan.self, WaterEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    FastingPlan.seedDefaultPlansIfNeeded(in: container.mainContext)
    return PlanPickerView(selectedPlanID: .constant(nil))
        .modelContainer(container)
        .environment(PurchaseManager())
}
