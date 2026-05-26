import SwiftData
import Foundation

enum MediaType: String, Codable {
    case image
    case video
}

@Model
final class MediaAttachment {
    @Attribute(.unique) var id: UUID
    var type: MediaType.RawValue
    var fileName: String
    var thumbnailFileName: String?
    var order: Int
    @Relationship(inverse: \Note.media) var note: Note?

    init(
        id: UUID = UUID(),
        type: MediaType,
        fileName: String,
        thumbnailFileName: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.type = type.rawValue
        self.fileName = fileName
        self.thumbnailFileName = thumbnailFileName
        self.order = order
    }

    var mediaType: MediaType {
        MediaType(rawValue: type) ?? .image
    }
}
