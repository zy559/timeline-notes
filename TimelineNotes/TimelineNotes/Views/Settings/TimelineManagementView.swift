import SwiftUI
import SwiftData

struct TimelineManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timeline.sortOrder) private var timelines: [Timeline]
    @State private var showNewAlert = false
    @State private var newName = ""
    @State private var editingTimeline: Timeline?
    @State private var editName = ""
    @State private var editIcon = "list.bullet"
    @State private var editColor = "#007AFF"

    let iconOptions = ["list.bullet", "star", "heart", "bookmark", "flag", "leaf", "flame", "bolt", "brain", "lightbulb"]
    let colorOptions = ["#007AFF", "#FF3B30", "#34C759", "#FF9500", "#AF52DE", "#5856D6", "#FF2D55", "#00C7BE"]

    var body: some View {
        List {
            ForEach(timelines) { timeline in
                HStack {
                    Image(systemName: timeline.icon)
                        .foregroundColor(Color(hex: timeline.color))
                    Text(timeline.name)
                    Spacer()
                }
                .swipeActions(edge: .trailing) {
                    Button("编辑") {
                        editingTimeline = timeline
                        editName = timeline.name
                        editIcon = timeline.icon
                        editColor = timeline.color
                    }
                    .tint(.blue)

                    Button("删除", role: .destructive) {
                        let service = TimelineService(modelContext: modelContext)
                        try? service.deleteTimeline(timeline)
                    }
                }
            }
            .onMove { source, destination in
                var reordered = timelines
                reordered.move(fromOffsets: source, toOffset: destination)
                let service = TimelineService(modelContext: modelContext)
                try? service.reorderTimelines(reordered)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewAlert = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("新建时间线", isPresented: $showNewAlert) {
            TextField("名称", text: $newName)
            Button("取消", role: .cancel) { }
            Button("创建") {
                let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let service = TimelineService(modelContext: modelContext)
                try? service.createTimeline(name: trimmed)
                newName = ""
            }
        }
        .sheet(item: $editingTimeline) { timeline in
            NavigationStack {
                Form {
                    Section("名称") { TextField("名称", text: $editName) }
                    Section("图标") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .padding(8)
                                    .background(editIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { editIcon = icon }
                            }
                        }
                    }
                    Section("颜色") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 36, height: 36)
                                    .overlay(editColor == color ? Circle().stroke(Color.primary, lineWidth: 2) : nil)
                                    .onTapGesture { editColor = color }
                            }
                        }
                    }
                }
                .navigationTitle("编辑时间线")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            let service = TimelineService(modelContext: modelContext)
                            try? service.updateTimeline(timeline, name: editName, icon: editIcon, color: editColor)
                            editingTimeline = nil
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { editingTimeline = nil }
                    }
                }
            }
        }
        .navigationTitle("管理时间线")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
