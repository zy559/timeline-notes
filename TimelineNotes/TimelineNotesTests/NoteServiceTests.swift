import XCTest
import SwiftData
@testable import TimelineNotes

@MainActor
final class NoteServiceTests: XCTestCase {
    var container: ModelContainer!
    var service: NoteService!

    override func setUp() async throws {
        let schema = Schema([Note.self, Timeline.self, Tag.self, MediaAttachment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        service = NoteService(modelContext: container.mainContext)
    }

    override func tearDown() async throws {
        container = nil
        service = nil
    }

    func testCreateNote() throws {
        let note = try service.createNote(content: "Hello #world", timeline: nil)
        XCTAssertEqual(note.content, "Hello #world")
        XCTAssertEqual(note.tags?.count, 1)
        XCTAssertEqual(note.tags?.first?.name, "world")
    }

    func testUpdateNote() throws {
        let note = try service.createNote(content: "Original", timeline: nil)
        try service.updateNote(note, content: "Updated #new", timeline: nil)
        XCTAssertEqual(note.content, "Updated #new")
        XCTAssertNotNil(note.editedAt)
    }

    func testDeleteNote() throws {
        let note = try service.createNote(content: "Delete me", timeline: nil)
        try service.deleteNote(note)
        let results = try service.fetchNotes()
        XCTAssertFalse(results.contains { $0.id == note.id })
    }

    func testTogglePin() throws {
        let note = try service.createNote(content: "Pin me", timeline: nil)
        XCTAssertFalse(note.isPinned)
        try service.togglePin(note)
        XCTAssertTrue(note.isPinned)
    }

    func testFetchNotesWithSearch() throws {
        _ = try service.createNote(content: "Apple pie", timeline: nil)
        _ = try service.createNote(content: "Banana bread", timeline: nil)
        let results = try service.fetchNotes(searchText: "apple")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "Apple pie")
    }

    func testFetchNotesPinnedFirst() throws {
        let note1 = try service.createNote(content: "First", timeline: nil)
        let note2 = try service.createNote(content: "Second", timeline: nil)
        try service.togglePin(note2)
        let results = try service.fetchNotes()
        XCTAssertEqual(results.first?.id, note2.id)
    }
}
