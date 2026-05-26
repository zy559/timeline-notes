import SwiftData

enum SeedData {
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Timeline>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let defaultTimeline = Timeline(name: "我的时间线", icon: "list.bullet", color: "#007AFF", sortOrder: 0)
        modelContext.insert(defaultTimeline)

        let workTimeline = Timeline(name: "工作", icon: "briefcase", color: "#FF9500", sortOrder: 1)
        modelContext.insert(workTimeline)

        let lifeTimeline = Timeline(name: "生活", icon: "heart", color: "#FF3B30", sortOrder: 2)
        modelContext.insert(lifeTimeline)

        try? modelContext.save()
    }
}
