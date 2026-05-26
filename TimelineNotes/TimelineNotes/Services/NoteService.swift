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
        let descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor<Note>(\.createdAt, order: .reverse)]
        )
        let fetched: [Note] = try modelContext.fetch(descriptor)

        var results = fetched.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.createdAt > b.createdAt
        }

        if let timeline = timeline {
            let tid = timeline.id
            results = results.filter { $0.timeline?.id == tid }
        }

        if !searchText.isEmpty {
            results = results.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }

        if !tags.isEmpty {
            let filterIds = Set(tags.map { $0.id })
            results = results.filter { note in
                let noteIds = Set((note.tags ?? []).map { $0.id })
                return !noteIds.isDisjoint(with: filterIds)
            }
        }

        if let start = startDate {
            results = results.filter { $0.createdAt >= start }
        }
        if let end = endDate {
            results = results.filter { $0.createdAt <= end }
        }

        let startIndex = page * pageSize
        guard startIndex < results.count else { return [] }
        let endIndex = min(startIndex + pageSize, results.count)
        return Array(results[startIndex..<endIndex])
    }
}
