import SwiftData
import Foundation

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(inverse: \Note.tags) var notes: [Note]?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
