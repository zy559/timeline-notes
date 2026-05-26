import SwiftData
import Foundation

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var content: String
    var createdAt: Date
    var editedAt: Date?
    var isPinned: Bool
    var timeline: Timeline?
    @Relationship(deleteRule: .cascade) var tags: [Tag]?
    @Relationship(deleteRule: .cascade) var media: [MediaAttachment]?

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        editedAt: Date? = nil,
        isPinned: Bool = false,
        timeline: Timeline? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.isPinned = isPinned
        self.timeline = timeline
    }

    var sortedMedia: [MediaAttachment] {
        (media ?? []).sorted { $0.order < $1.order }
    }

    var tagNames: [String] {
        (tags ?? []).map { $0.name }
    }
}
