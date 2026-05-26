import SwiftData
import Foundation

@MainActor
@Observable
final class NoteService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createNote(
        content: String,
        timeline: Timeline?,
        tags: [String] = [],
        mediaAttachments: [MediaAttachment] = []
    ) throws -> Note {
        let hashtags = HashtagParser.extractHashtags(from: content)
        let allTags = Set(tags + hashtags)
        let note = Note(content: content, timeline: timeline)
        modelContext.insert(note)
        let tagService = TagService(modelContext: modelContext)
        for tagName in allTags {
            let tag = try tagService.fetchOrCreate(name: tagName)
            note.tags?.append(tag)
        }
        for (index, media) in mediaAttachments.enumerated() {
            media.order = index
            note.media?.append(media)
        }
        try modelContext.save()
        return note
    }

    func updateNote(_ note: Note, content: String, timeline: Timeline?, manualTags: [String] = []) throws {
        note.content = content
        note.timeline = timeline
        note.editedAt = Date()
        let hashtags = HashtagParser.extractHashtags(from: content)
        let allTags = Set(manualTags + hashtags)
        let tagService = TagService(modelContext: modelContext)
        try tagService.syncTags(for: note, from: Array(allTags))
        try modelContext.save()
    }

    func deleteNote(_ note: Note) throws {
        modelContext.delete(note)
        try modelContext.save()
    }

    func togglePin(_ note: Note) throws {
        note.isPinned.toggle()
        try modelContext.save()
    }

    func fetchNotes(
        for timeline: Timeline? = nil,
        searchText: String = "",
        tags: [Tag] = [],
        startDate: Date? = nil,
        endDate: Date? = nil,
        page: Int = 0,
        pageSize: Int = 20
    ) throws -> [Note] {
        var descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.isPinned, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let start = startDate, let end = endDate {
            descriptor.predicate = #Predicate { $0.createdAt >= start && $0.createdAt <= end }
        } else if let start = startDate {
            descriptor.predicate = #Predicate { $0.createdAt >= start }
        } else if let end = endDate {
            descriptor.predicate = #Predicate { $0.createdAt <= end }
        }
        var allNotes = try modelContext.fetch(descriptor)

        if let timeline = timeline {
            let tid = timeline.id
            allNotes = allNotes.filter { $0.timeline?.id == tid }
        }

        if !searchText.isEmpty {
            allNotes = allNotes.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }

        if !tags.isEmpty {
            allNotes = allNotes.filter { note in
                let noteTags = Set((note.tags ?? []).map { $0.id })
                let filterTagIds = Set(tags.map { $0.id })
                return !noteTags.isDisjoint(with: filterTagIds)
            }
        }

        let startIndex = page * pageSize
        guard startIndex < allNotes.count else { return [] }
        let endIndex = min(startIndex + pageSize, allNotes.count)
        return Array(allNotes[startIndex..<endIndex])
    }
}
