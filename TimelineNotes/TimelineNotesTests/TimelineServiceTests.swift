import XCTest
import SwiftData
@testable import TimelineNotes

@MainActor
final class TimelineServiceTests: XCTestCase {
    var container: ModelContainer!
    var service: TimelineService!

    override func setUp() async throws {
        let schema = Schema([Note.self, Timeline.self, Tag.self, MediaAttachment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        service = TimelineService(modelContext: container.mainContext)
    }

    override func tearDown() async throws {
        container = nil
        service = nil
    }

    func testCreateTimeline() throws {
        let timeline = try service.createTimeline(name: "Test", icon: "star", color: "#FF0000")
        XCTAssertEqual(timeline.name, "Test")
        XCTAssertEqual(timeline.icon, "star")
        XCTAssertEqual(timeline.sortOrder, 0)
    }

    func testFetchAllTimelines() throws {
        _ = try service.createTimeline(name: "A")
        _ = try service.createTimeline(name: "B")
        let all = try service.fetchAllTimelines()
        XCTAssertEqual(all.count, 2)
    }

    func testUpdateTimeline() throws {
        let timeline = try service.createTimeline(name: "Old")
        try service.updateTimeline(timeline, name: "New", icon: "heart", color: "#00FF00")
        XCTAssertEqual(timeline.name, "New")
        XCTAssertEqual(timeline.icon, "heart")
    }

    func testDeleteTimelineNullifiesNotes() throws {
        let timeline = try service.createTimeline(name: "ToDelete")
        let noteService = NoteService(modelContext: container.mainContext)
        let note = try noteService.createNote(content: "Test", timeline: timeline)
        try service.deleteTimeline(timeline)
        XCTAssertNil(note.timeline)
    }

    func testReorderTimelines() throws {
        let t1 = try service.createTimeline(name: "First")
        let t2 = try service.createTimeline(name: "Second")
        try service.reorderTimelines([t2, t1])
        XCTAssertEqual(t2.sortOrder, 0)
        XCTAssertEqual(t1.sortOrder, 1)
    }
}
