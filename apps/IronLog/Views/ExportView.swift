//
//  ExportView.swift
//  IronLog
//
//  导出训练日志为 CSV，通过系统分享面板保存/发送。Pro 功能。
//

import SwiftUI

struct ExportView: View {
    let sessions: [WorkoutSession]

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var includeWarmups = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section("export.options") {
                    Toggle("export.warmups", isOn: $includeWarmups)
                    LabeledContent("export.count", value: "\(sessions.count)")
                    LabeledContent("export.unit", value: settings.weightUnit.symbol)
                }

                Section {
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("export.share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.ironAccent)
                    } else {
                        Button {
                            generate()
                        } label: {
                            Label("export.generate", systemImage: "doc.badge.gearshape")
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.ironAccent)
                    }
                } footer: {
                    Text("export.footer")
                }
            }
            .navigationTitle("export.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done") { dismiss() }
                }
            }
        }
    }

    /// 生成 CSV 文件至临时目录。
    private func generate() {
        let csv = buildCSV()
        let filename = "IronLog-Export.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            // 加 BOM 以便 Excel 正确识别 UTF-8 中文。
            var data = Data([0xEF, 0xBB, 0xBF])
            data.append(Data(csv.utf8))
            try data.write(to: url, options: .atomic)
            exportURL = url
        } catch {
            // 写入失败时保持按钮可重试。
            exportURL = nil
        }
    }

    /// 构造 CSV 文本。一行一组。
    private func buildCSV() -> String {
        let unit = settings.weightUnit
        var rows: [String] = [
            "Date,Workout,Exercise,Muscle,Set,Weight(\(unit.symbol)),Reps,RPE,Warmup,Volume(\(unit.symbol))"
        ]

        let sorted = sessions.sorted { $0.date < $1.date }
        for session in sorted {
            let dateStr = Fmt.dateTime(session.date)
            let workoutName = escape(session.name.isEmpty ? "Untitled" : session.name)
            for group in session.setsGrouped() {
                let exName = escape(group.exercise.name)
                let muscle = group.exercise.muscleGroupRaw
                let ordered = group.sets.sorted { $0.order < $1.order }
                for (index, set) in ordered.enumerated() {
                    if set.isWarmup && !includeWarmups { continue }
                    let weight = Fmt.weight(unit.display(fromKg: set.weight))
                    let volume = Fmt.weight(unit.display(fromKg: set.volume))
                    let rpe = set.rpe > 0 ? Fmt.weight(set.rpe) : ""
                    rows.append(
                        "\(dateStr),\(workoutName),\(exName),\(muscle),\(index + 1),\(weight),\(set.reps),\(rpe),\(set.isWarmup ? "Y" : "N"),\(volume)"
                    )
                }
            }
        }
        return rows.joined(separator: "\n")
    }

    /// CSV 字段转义（含逗号/引号时包引号）。
    private func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

#Preview {
    ExportView(sessions: [PreviewData.sampleSession])
        .environmentObject(AppSettings())
}
