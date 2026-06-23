//
//  MedicationEditView.swift
//  SeniorHelper
//
//  新增 / 编辑用药计划：药品名、剂量、药盒拍照、每日提醒时间。
//

import SwiftUI
import SwiftData

struct MedicationEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let viewModel: MedicationViewModel
    /// nil 表示新增。
    let medication: Medication?

    // 表单状态
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var times: [Date] = []
    @State private var isEnabled: Bool = true

    // 照片状态
    @State private var pickedImage: UIImage?
    @State private var removePhoto = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showPhotoOptions = false

    private var isEditing: Bool { medication != nil }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                infoSection
                reminderSection
                if isEditing {
                    enabledSection
                }
            }
            .navigationTitle(Text(isEditing ? "编辑用药" : "添加用药"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .font(.body.weight(.semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .font(.body.weight(.bold))
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    pickedImage = image
                    removePhoto = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showLibrary) {
                ImagePicker(sourceType: .photoLibrary) { image in
                    pickedImage = image
                    removePhoto = false
                }
                .ignoresSafeArea()
            }
            .confirmationDialog(Text("药盒照片"), isPresented: $showPhotoOptions, titleVisibility: .visible) {
                Button("拍照") { showCamera = true }
                Button("从相册选择") { showLibrary = true }
                if currentImage != nil {
                    Button("移除照片", role: .destructive) {
                        pickedImage = nil
                        removePhoto = true
                    }
                }
                Button("取消", role: .cancel) {}
            }
            .onAppear(perform: loadExisting)
        }
    }

    // MARK: - 照片

    private var currentImage: UIImage? {
        if removePhoto { return nil }
        if let pickedImage { return pickedImage }
        return ImageStore.load(medication?.photoFileName)
    }

    private var photoSection: some View {
        Section {
            Button {
                Haptics.tap()
                showPhotoOptions = true
            } label: {
                HStack {
                    Spacer()
                    if let image = currentImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                            .overlay(alignment: .bottomTrailing) {
                                Label("更换", systemImage: "camera.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(8)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .padding(8)
                            }
                    } else {
                        VStack(spacing: Theme.smallPadding) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 44))
                            Text("拍摄药盒照片")
                                .font(.title3.weight(.semibold))
                            Text("方便确认是哪一种药")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(Theme.accent)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("药盒照片")
        }
    }

    // MARK: - 基本信息

    private var infoSection: some View {
        Section {
            LabeledField(title: "药品名称", text: $name, placeholder: "例如：降压药")
            LabeledField(title: "服用说明", text: $dosage, placeholder: "例如：每次 1 片，饭后")
        } header: {
            Text("药品信息")
        }
    }

    // MARK: - 提醒时间

    private var reminderSection: some View {
        Section {
            ForEach(times.indices, id: \.self) { index in
                HStack {
                    DatePicker(
                        selection: Binding(
                            get: { times[index] },
                            set: { times[index] = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    ) {
                        Text("第 \(index + 1) 次")
                            .font(.body.weight(.medium))
                    }
                    .datePickerStyle(.compact)

                    Button(role: .destructive) {
                        times.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Theme.danger)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Text("删除该时间"))
                }
            }

            Button {
                addTime()
            } label: {
                Label("添加提醒时间", systemImage: "plus.circle.fill")
                    .font(.body.weight(.semibold))
            }
        } header: {
            Text("每日提醒时间")
        } footer: {
            Text("到点会发出通知提醒服药，可设置多个时间。")
        }
    }

    private var enabledSection: some View {
        Section {
            Toggle(isOn: $isEnabled) {
                Text("启用提醒")
                    .font(.body.weight(.medium))
            }
            .tint(Theme.success)
        }
    }

    // MARK: - 逻辑

    private func loadExisting() {
        guard let medication, name.isEmpty else { return }
        name = medication.name
        dosage = medication.dosage
        times = medication.reminderTimes
        isEnabled = medication.isEnabled
    }

    private func addTime() {
        // 默认新增一个 08:00 的提醒。
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        times.append(date)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        viewModel.save(
            in: context,
            existing: medication,
            name: trimmedName,
            dosage: dosage.trimmingCharacters(in: .whitespaces),
            times: times,
            isEnabled: isEnabled,
            newImage: pickedImage,
            removePhoto: removePhoto
        )
        dismiss()
    }
}

// MARK: - 大字号输入字段

private struct LabeledField: View {
    let title: LocalizedStringKey
    @Binding var text: String
    let placeholder: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .font(.title3)
                .textInputAutocapitalization(.never)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MedicationEditView(viewModel: MedicationViewModel(), medication: nil)
        .modelContainer(for: [Medication.self, EmergencyContact.self], inMemory: true)
}
