import SwiftData
import Foundation

@Model
final class Timeline {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String
    var sortOrder: Int
    var createdAt: Date
    @Relationship(deleteRule: .nullify, inverse: \Note.timeline) var notes: [Note]?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "list.bullet",
        color: String = "#007AFF",
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
