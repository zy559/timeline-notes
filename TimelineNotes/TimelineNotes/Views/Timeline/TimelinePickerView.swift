import SwiftUI
import SwiftData

struct TimelinePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timeline.sortOrder) private var timelines: [Timeline]
    @Binding var selectedTimeline: Timeline?
    @State private var showNewTimelineAlert = false
    @State private var newTimelineName = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(name: "全部", isSelected: selectedTimeline == nil) {
                    selectedTimeline = nil
                }

                ForEach(timelines) { timeline in
                    filterChip(name: timeline.name, isSelected: selectedTimeline?.id == timeline.id) {
                        selectedTimeline = timeline
                    }
                }

                Button {
                    showNewTimelineAlert = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .alert("新建时间线", isPresented: $showNewTimelineAlert) {
            TextField("名称", text: $newTimelineName)
            Button("取消", role: .cancel) { }
            Button("创建") {
                let trimmed = newTimelineName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let service = TimelineService(modelContext: modelContext)
                try? service.createTimeline(name: trimmed)
                newTimelineName = ""
            }
        }
    }

    @ViewBuilder
    private func filterChip(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .clipShape(Capsule())
        }
    }
}
