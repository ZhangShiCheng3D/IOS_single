//
//  HabitFormView.swift
//  HabitGrid
//
//  新建/编辑习惯表单：名称、图标、颜色、频率、提醒。
//

import SwiftUI
import SwiftData

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// 编辑目标；nil 表示新建。
    let habit: Habit?
    /// 当前习惯总数（用于新建时的 sortOrder）。
    let existingCount: Int

    // 表单字段
    @State private var name: String = ""
    @State private var iconName: String = HabitAssets.icons[0]
    @State private var colorHex: String = HabitAssets.colors[0]
    @State private var frequency: HabitFrequency = .daily
    @State private var weeklyTarget: Int = 5
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Self.defaultReminderTime

    @FocusState private var nameFocused: Bool

    private var isEditing: Bool { habit != nil }
    private var selectedColor: Color { Color(hex: colorHex) ?? .green }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    private static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 预览卡片
                Section {
                    previewCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // MARK: 名称
                Section("form.name") {
                    TextField("form.name.placeholder", text: $name)
                        .focused($nameFocused)
                        .submitLabel(.done)
                }

                // MARK: 图标
                Section("form.icon") {
                    iconGrid
                }

                // MARK: 颜色
                Section("form.color") {
                    colorGrid
                }

                // MARK: 频率
                Section("form.frequency") {
                    Picker("form.frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .pickerStyle(.menu)

                    if frequency == .custom {
                        Stepper(value: $weeklyTarget, in: 1...7) {
                            Text("form.weeklyTarget \(weeklyTarget)")
                        }
                    }
                }

                // MARK: 提醒
                Section {
                    Toggle("form.reminder", isOn: $reminderEnabled.animation())
                    if reminderEnabled {
                        DatePicker("form.reminderTime", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                } footer: {
                    if reminderEnabled {
                        Text("form.reminder.footer")
                    }
                }
            }
            .navigationTitle(isEditing ? "form.title.edit" : "form.title.new")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    // MARK: - 预览卡片

    private var previewCard: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 34))
                .foregroundStyle(selectedColor)
                .frame(width: 72, height: 72)
                .background(selectedColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text(trimmedName.isEmpty ? String(localized: "form.preview.placeholder") : trimmedName)
                .font(.headline)
                .foregroundStyle(trimmedName.isEmpty ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - 图标网格

    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
            ForEach(HabitAssets.icons, id: \.self) { icon in
                Button {
                    Haptics.selection()
                    iconName = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title3)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(iconName == icon ? .white : selectedColor)
                        .background(
                            iconName == icon ? selectedColor : selectedColor.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 颜色网格

    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
            ForEach(HabitAssets.colors, id: \.self) { hex in
                Button {
                    Haptics.selection()
                    colorHex = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if colorHex == hex {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay {
                            Circle().strokeBorder(.white.opacity(colorHex == hex ? 0.8 : 0), lineWidth: 2)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 载入与保存

    private func loadIfEditing() {
        guard let habit else {
            // 新建：自动聚焦名称输入框。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nameFocused = true }
            return
        }
        name = habit.name
        iconName = habit.iconName
        colorHex = habit.colorHex
        frequency = habit.frequency
        weeklyTarget = habit.weeklyTarget
        reminderEnabled = habit.reminderEnabled
        reminderTime = habit.reminderTime ?? Self.defaultReminderTime
    }

    private func save() {
        guard canSave else { return }
        let vm = HabitViewModel(context: modelContext)

        if let habit {
            habit.name = trimmedName
            habit.iconName = iconName
            habit.colorHex = colorHex
            habit.frequency = frequency
            habit.weeklyTarget = weeklyTarget
            habit.reminderEnabled = reminderEnabled
            habit.reminderTime = reminderEnabled ? reminderTime : nil
            vm.update(habit)
        } else {
            _ = vm.createHabit(
                name: trimmedName,
                iconName: iconName,
                colorHex: colorHex,
                frequency: frequency,
                weeklyTarget: weeklyTarget,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderEnabled ? reminderTime : nil,
                currentCount: existingCount
            )
        }
        WidgetDataBridge.sync(from: modelContext)
        dismiss()
    }
}

#Preview("New Habit") {
    HabitFormView(habit: nil, existingCount: 0)
        .modelContainer(PreviewData.container)
}
