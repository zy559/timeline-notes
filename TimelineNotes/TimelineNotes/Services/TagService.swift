import SwiftData
import Foundation

@Observable
final class TagService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }

    func fetchOrCreate(name: String) throws -> Tag {
        let lowercased = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = try fetchTag(named: lowercased) {
            return existing
        }
        let tag = Tag(name: lowercased)
        modelContext.insert(tag)
        try modelContext.save()
        return tag
    }

    func syncTags(for note: Note, from hashtags: [String]) throws {
        let currentTags = note.tags ?? []
        let currentNames = Set(currentTags.map { $0.name })
        let newNames = Set(hashtags.map { $0.lowercased() })
        let toRemove = currentTags.filter { !newNames.contains($0.name) }
        for tag in toRemove {
            tag.notes?.removeAll { $0.id == note.id }
        }
        for name in newNames.subtracting(currentNames) {
            let tag = try fetchOrCreate(name: name)
            note.tags?.append(tag)
        }
        try modelContext.save()
    }

    func popularTags(limit: Int = 20) throws -> [Tag] {
        let all = try fetchAllTags()
        let sorted = all.sorted { ($0.notes?.count ?? 0) > ($1.notes?.count ?? 0) }
        return Array(sorted.prefix(limit))
    }

    private func fetchTag(named name: String) throws -> Tag? {
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == name })
        return try modelContext.fetch(descriptor).first
    }
}
