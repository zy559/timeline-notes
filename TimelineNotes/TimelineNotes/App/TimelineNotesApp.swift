import SwiftUI
import SwiftData

@main
struct TimelineNotesApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Note.self, Timeline.self, Tag.self, MediaAttachment.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
            SeedData.seedIfNeeded(modelContext: container.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
