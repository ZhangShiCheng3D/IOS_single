//
//  MedicationListView.swift
//  SeniorHelper
//
//  用药提醒列表。付费功能：未解锁时展示锁定引导。
//

import SwiftUI
import SwiftData

struct MedicationListView: View {
    @Environment(\.modelContext) private var context
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(SpeechManager.self) private var speechManager

    /// 按创建时间倒序读取全部用药计划。
    @Query(sort: \Medication.createdAt, order: .reverse)
    private var medications: [Medication]

    @State private var viewModel = MedicationViewModel()
    @State private var editingMedication: Medication?
    @State private var isCreating = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if !purchaseManager.isUnlocked {
                    lockedView
                } else if medications.isEmpty {
                    emptyView
                } else {
                    medicationList
                }
            }
            .background(Theme.pageBackground)
            .navigationTitle(Text("用药提醒"))
            .toolbar {
                if purchaseManager.isUnlocked {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            startCreate()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .accessibilityLabel(Text("添加用药"))
                        }
                    }
                }
            }
            .sheet(isPresented: $isCreating) {
                MedicationEditView(viewModel: viewModel, medication: nil)
            }
            .sheet(item: $editingMedication) { med in
                MedicationEditView(viewModel: viewModel, medication: med)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - 列表

    private var medicationList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.padding) {
                ForEach(medications) { med in
                    MedicationRow(
                        medication: med,
                        onToggle: { viewModel.toggleEnabled(med, in: context) },
                        onSpeak: { speechManager.speak(med.spokenDescription, force: true) },
                        onEdit: { editingMedication = med },
                        onDelete: { viewModel.delete(med, in: context) }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(Theme.padding)
            .animation(.snappy(duration: 0.3), value: medications.count)
        }
    }

    // MARK: - 空状态

    private var emptyView: some View {
        ContentUnavailableView {
            Label("还没有用药计划", systemImage: "pills")
        } description: {
            Text("点击右上角加号，拍下药盒并设置提醒时间")
                .font(.title3)
        } actions: {
            Button {
                startCreate()
            } label: {
                Text("添加第一条用药")
            }
            .buttonStyle(.seniorPrimary)
            .padding(.horizontal, Theme.largePadding)
        }
    }

    // MARK: - 未解锁

    private var lockedView: some View {
        VStack(spacing: Theme.largePadding) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.accent)

            VStack(spacing: Theme.smallPadding) {
                Text("用药提醒是高级功能")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("拍下药盒，设置每日提醒，按时吃药更安心。解锁后永久使用。")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.padding)
            }

            Button {
                showPaywall = true
            } label: {
                Text("解锁完整版")
            }
            .buttonStyle(.seniorPrimary)
            .padding(.horizontal, Theme.largePadding)
            Spacer()
            Spacer()
        }
        .padding(Theme.padding)
    }

    // MARK: - 动作

    private func startCreate() {
        Haptics.tap()
        Task {
            // 进入编辑前确保已有通知权限。
            await viewModel.ensureNotificationPermission()
            isCreating = true
        }
    }
}

// MARK: - 单行卡片

private struct MedicationRow: View {
    let medication: Medication
    let onToggle: () -> Void
    let onSpeak: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.smallPadding) {
            HStack(alignment: .top, spacing: Theme.padding) {
                photoThumbnail

                VStack(alignment: .leading, spacing: 6) {
                    Text(medication.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    if !medication.dosage.isEmpty {
                        Text(medication.dosage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Label(medication.reminderTimesDescription, systemImage: "clock.fill")
                        .font(.body.weight(.medium))
                        .foregroundStyle(medication.isEnabled ? Theme.accent : .secondary)
                }
                Spacer(minLength: 0)
            }

            Divider()

            // 操作行：开关 / 朗读 / 编辑
            HStack(spacing: Theme.padding) {
                Toggle(isOn: Binding(get: { medication.isEnabled }, set: { _ in onToggle() })) {
                    Text(medication.isEnabled ? "提醒开" : "提醒关")
                        .font(.body.weight(.semibold))
                }
                .toggleStyle(.switch)
                .tint(Theme.success)
                .fixedSize()

                Spacer()

                Button(action: onSpeak) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .frame(width: 48, height: 48)
                }
                .accessibilityLabel(Text("朗读"))

                Button(action: onEdit) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .frame(width: 48, height: 48)
                }
                .accessibilityLabel(Text("编辑"))

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .frame(width: 48, height: 48)
                }
                .accessibilityLabel(Text("删除"))
            }
        }
        .cardStyle()
        .confirmationDialog(
            Text("确定删除「\(medication.name)」吗？"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive, action: onDelete)
            Button("取消", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var photoThumbnail: some View {
        if let image = ImageStore.load(medication.photoFileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: Theme.smallCornerRadius))
        } else {
            RoundedRectangle(cornerRadius: Theme.smallCornerRadius)
                .fill(Theme.accent.opacity(0.15))
                .frame(width: 76, height: 76)
                .overlay {
                    Image(systemName: "pills.fill")
                        .font(.title)
                        .foregroundStyle(Theme.accent)
                }
        }
    }
}

#Preview {
    MedicationListView()
        .environment(PurchaseManager())
        .environment(SpeechManager())
        .modelContainer(for: [Medication.self, EmergencyContact.self], inMemory: true)
}
