import SwiftData
import Foundation

@MainActor
@Observable
final class TimelineService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllTimelines() throws -> [Timeline] {
        let descriptor = FetchDescriptor<Timeline>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }

    func createTimeline(name: String, icon: String = "list.bullet", color: String = "#007AFF") throws -> Timeline {
        let count = (try? fetchAllTimelines().count) ?? 0
        let timeline = Timeline(name: name, icon: icon, color: color, sortOrder: count)
        modelContext.insert(timeline)
        try modelContext.save()
        return timeline
    }

    func updateTimeline(_ timeline: Timeline, name: String, icon: String, color: String) throws {
        timeline.name = name
        timeline.icon = icon
        timeline.color = color
        try modelContext.save()
    }

    func deleteTimeline(_ timeline: Timeline) throws {
        let notes = try fetchNotesForTimeline(timeline)
        for note in notes {
            note.timeline = nil
        }
        modelContext.delete(timeline)
        try modelContext.save()
    }

    func reorderTimelines(_ timelines: [Timeline]) throws {
        for (index, timeline) in timelines.enumerated() {
            timeline.sortOrder = index
        }
        try modelContext.save()
    }

    private func fetchNotesForTimeline(_ timeline: Timeline) throws -> [Note] {
        let descriptor = FetchDescriptor<Note>(predicate: #Predicate { $0.timeline?.id == timeline.id })
        return try modelContext.fetch(descriptor)
    }
}
