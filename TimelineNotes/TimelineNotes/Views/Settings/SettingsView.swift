import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timeline.sortOrder) private var timelines: [Timeline]
    @Query private var allNotes: [Note]

    var body: some View {
        NavigationStack {
            List {
                Section("时间线管理") {
                    NavigationLink {
                        TimelineManagementView()
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            Text("\(timelines.count) 条时间线")
                        }
                    }
                }

                Section("数据") {
                    HStack {
                        Image(systemName: "note.text")
                        Text("共 \(allNotes.count) 条笔记")
                    }
                    Button {
                        exportData()
                    } label: {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("平台")
                        Spacer()
                        Text("iOS 17+").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }

    private func exportData() {
        let exportData: [String: Any] = [
            "exportedAt": ISO8601DateFormatter().string(from: Date()),
            "timelines": timelines.map { ["name": $0.name, "id": $0.id.uuidString] },
            "notes": allNotes.map { note in
                var dict: [String: Any] = [
                    "id": note.id.uuidString,
                    "content": note.content,
                    "createdAt": note.createdAt.ISO8601Format(),
                    "tags": note.tagNames
                ]
                if let timeline = note.timeline {
                    dict["timeline"] = timeline.name
                }
                return dict
            }
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("timeline_export_\(ISO8601DateFormatter().string(from: Date())).json")
            try? jsonString.write(to: tempURL, atomically: true, encoding: .utf8)
        }
    }
}
