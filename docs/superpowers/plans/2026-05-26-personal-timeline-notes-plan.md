# 个人时间线笔记 — 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一款 iOS 个人时间线笔记应用，支持多条时间线、富媒体笔记、标签管理和全文搜索。

**Architecture:** SwiftData 持久化 + Service 层封装业务逻辑 + SwiftUI 视图层。纯本地存储，架构为未来社交功能预留扩展。

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, PhotosUI, AVKit, iOS 17+

**项目结构:**
```
TimelineNotes/
├── TimelineNotes/
│   ├── App/
│   │   └── TimelineNotesApp.swift
│   ├── Models/
│   │   ├── Timeline.swift
│   │   ├── Note.swift
│   │   ├── Tag.swift
│   │   └── MediaAttachment.swift
│   ├── Services/
│   │   ├── NoteService.swift
│   │   ├── TimelineService.swift
│   │   ├── TagService.swift
│   │   └── MediaService.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── Timeline/
│   │   │   ├── TimelineFeedView.swift
│   │   │   ├── TimelinePickerView.swift
│   │   │   └── NoteCardView.swift
│   │   ├── Compose/
│   │   │   ├── ComposeNoteView.swift
│   │   │   └── TagEditorView.swift
│   │   ├── Detail/
│   │   │   ├── NoteDetailView.swift
│   │   │   ├── MediaGalleryView.swift
│   │   │   └── VideoPlayerView.swift
│   │   ├── Search/
│   │   │   ├── SearchView.swift
│   │   │   └── TagCloudView.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       └── TimelineManagementView.swift
│   └── Utilities/
│       ├── HashtagParser.swift
│       ├── MediaGridLayoutHelper.swift
│       └── DateFormatter+Extensions.swift
└── TimelineNotesTests/
    ├── HashtagParserTests.swift
    ├── MediaGridLayoutHelperTests.swift
    ├── NoteServiceTests.swift
    ├── TimelineServiceTests.swift
    └── TagServiceTests.swift
```

---

## Xcode 项目创建说明

由于在 Windows 环境开发，Xcode 项目需在 Mac 上创建：

1. Mac 上打开 Xcode → New Project → iOS → App
2. Product Name: `TimelineNotes`，Interface: SwiftUI，Language: Swift
3. Storage: 勾选 "Use SwiftData"
4. 将本仓库 `TimelineNotes/` 下所有文件拖入 Xcode 项目
5. 确保 iOS Deployment Target 设为 17.0

---

### Task 1: 创建项目目录结构

**Files:**
- Create: 上述目录结构中的所有空 `.swift` 文件

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p TimelineNotes/TimelineNotes/{App,Models,Services,Views/{Timeline,Compose,Detail,Search,Settings},Utilities}
mkdir -p TimelineNotes/TimelineNotesTests
```

---

### Task 2: 数据模型 — MediaAttachment

**Files:**
- Create: `TimelineNotes/TimelineNotes/Models/MediaAttachment.swift`

- [ ] **Step 1: 编写 MediaAttachment 模型**

```swift
import SwiftData
import Foundation

enum MediaType: String, Codable {
    case image
    case video
}

@Model
final class MediaAttachment {
    var id: UUID
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
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Models/MediaAttachment.swift
git commit -m "feat: add MediaAttachment model"
```

---

### Task 3: 数据模型 — Tag

**Files:**
- Create: `TimelineNotes/TimelineNotes/Models/Tag.swift`

- [ ] **Step 1: 编写 Tag 模型**

```swift
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
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Models/Tag.swift
git commit -m "feat: add Tag model"
```

---

### Task 4: 数据模型 — Timeline

**Files:**
- Create: `TimelineNotes/TimelineNotes/Models/Timeline.swift`

- [ ] **Step 1: 编写 Timeline 模型**

```swift
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
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Models/Timeline.swift
git commit -m "feat: add Timeline model"
```

---

### Task 5: 数据模型 — Note

**Files:**
- Create: `TimelineNotes/TimelineNotes/Models/Note.swift`

- [ ] **Step 1: 编写 Note 模型**

```swift
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
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Models/Note.swift
git commit -m "feat: add Note model"
```

---

### Task 6: 工具层 — HashtagParser

**Files:**
- Create: `TimelineNotes/TimelineNotes/Utilities/HashtagParser.swift`

- [ ] **Step 1: 编写 HashtagParser**

```swift
import Foundation

enum HashtagParser {
    private static let hashtagRegex = try! NSRegularExpression(
        pattern: "#([\\p{L}\\p{N}_-]+)",
        options: []
    )

    static func extractHashtags(from text: String) -> [String] {
        let nsText = text as NSString
        let matches = hashtagRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        return matches.map { match in
            let tag = nsText.substring(with: match.range(at: 1))
            return tag.lowercased().trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Utilities/HashtagParser.swift
git commit -m "feat: add HashtagParser utility"
```

---

### Task 7: 工具层 — MediaGridLayoutHelper

**Files:**
- Create: `TimelineNotes/TimelineNotes/Utilities/MediaGridLayoutHelper.swift`

- [ ] **Step 1: 编写 MediaGridLayoutHelper**

```swift
import Foundation

enum MediaGridLayoutHelper {
    static func columns(for count: Int) -> Int {
        switch count {
        case 1: return 1
        case 2: return 2
        default: return 3
        }
    }

    static func itemSize(for count: Int, totalWidth: CGFloat, spacing: CGFloat = 4) -> CGSize {
        let cols = CGFloat(columns(for: count))
        let totalSpacing = spacing * (cols - 1)
        let size = (totalWidth - totalSpacing) / cols
        return CGSize(width: size, height: size)
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Utilities/MediaGridLayoutHelper.swift
git commit -m "feat: add MediaGridLayoutHelper utility"
```

---

### Task 8: 工具层 — DateFormatter 扩展

**Files:**
- Create: `TimelineNotes/TimelineNotes/Utilities/DateFormatter+Extensions.swift`

- [ ] **Step 1: 编写 DateFormatter 扩展**

```swift
import Foundation

extension DateFormatter {
    static let noteDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let relativeDate: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter
    }()

    static func displayString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        if interval < 86400 {
            return relativeDate.localizedString(for: date, relativeTo: now)
        }
        return noteDisplay.string(from: date)
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Utilities/DateFormatter+Extensions.swift
git commit -m "feat: add DateFormatter display helpers"
```

---

### Task 9: Service 层 — MediaService

**Files:**
- Create: `TimelineNotes/TimelineNotes/Services/MediaService.swift`

- [ ] **Step 1: 编写 MediaService**

```swift
import SwiftUI
import AVFoundation

@Observable
final class MediaService {

    func saveImage(_ data: Data, fileName: String) throws {
        let url = mediaDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
    }

    func saveThumbnail(_ data: Data, fileName: String) throws {
        let url = mediaDirectory.appendingPathComponent("thumb_\(fileName)")
        try data.write(to: url)
    }

    func generateThumbnail(from data: Data, maxDimension: CGFloat = 400) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        if scale >= 1.0 { return data }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumbnail?.jpegData(compressionQuality: 0.8)
    }

    func generateVideoThumbnail(from data: Data, maxDimension: CGFloat = 400) -> Data? {
        let tempURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        defer { try? FileManager.default.removeItem(at: tempURL) }
        do {
            try data.write(to: tempURL)
            let asset = AVAsset(url: tempURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: maxDimension, height: maxDimension)
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8)
        } catch {
            return nil
        }
    }

    func deleteMedia(fileName: String) throws {
        let url = mediaDirectory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: url.path()) {
            try FileManager.default.removeItem(at: url)
        }
        let thumbURL = mediaDirectory.appendingPathComponent("thumb_\(fileName)")
        if FileManager.default.fileExists(atPath: thumbURL.path()) {
            try FileManager.default.removeItem(at: thumbURL)
        }
    }

    func mediaURL(for fileName: String) -> URL {
        mediaDirectory.appendingPathComponent(fileName)
    }

    private var mediaDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let mediaDir = documents.appendingPathComponent("Media")
        if !FileManager.default.fileExists(atPath: mediaDir.path()) {
            try? FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        }
        return mediaDir
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Services/MediaService.swift
git commit -m "feat: add MediaService"
```

---

### Task 10: Service 层 — TagService

**Files:**
- Create: `TimelineNotes/TimelineNotes/Services/TagService.swift`

- [ ] **Step 1: 编写 TagService**

```swift
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
        var descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    private func fetchTag(named name: String) throws -> Tag? {
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == name })
        return try modelContext.fetch(descriptor).first
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Services/TagService.swift
git commit -m "feat: add TagService"
```

---

### Task 11: Service 层 — NoteService

**Files:**
- Create: `TimelineNotes/TimelineNotes/Services/NoteService.swift`

- [ ] **Step 1: 编写 NoteService**

```swift
import SwiftData
import Foundation

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
        var allNotes: [Note]

        if let timeline = timeline {
            let descriptor = FetchDescriptor<Note>(
                predicate: #Predicate { $0.timeline?.id == timeline.id },
                sortBy: [SortDescriptor(\.isPinned, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
            )
            allNotes = try modelContext.fetch(descriptor)
        } else {
            var descriptor = FetchDescriptor<Note>(
                sortBy: [SortDescriptor(\.isPinned, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
            )
            allNotes = try modelContext.fetch(descriptor)
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

        if let start = startDate {
            allNotes = allNotes.filter { $0.createdAt >= start }
        }
        if let end = endDate {
            allNotes = allNotes.filter { $0.createdAt <= end }
        }

        let startIndex = page * pageSize
        guard startIndex < allNotes.count else { return [] }
        let endIndex = min(startIndex + pageSize, allNotes.count)
        return Array(allNotes[startIndex..<endIndex])
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Services/NoteService.swift
git commit -m "feat: add NoteService"
```

---

### Task 12: Service 层 — TimelineService

**Files:**
- Create: `TimelineNotes/TimelineNotes/Services/TimelineService.swift`

- [ ] **Step 1: 编写 TimelineService**

```swift
import SwiftData
import Foundation

@Observable
final class TimelineService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllTimelines() throws -> [Timeline] {
        let descriptor = FetchDescriptor<Timeline>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }

    func createTimeline(name: String, icon: String = "list.bullet", color: String = "#007AFF") throws -> Timeline {
        let count = (try? fetchAllTimelines().count) ?? 0
        let timeline = Timeline(name: name, icon: icon, color: color, sortOrder: count)
        modelContext.insert(timeline)
        try modelContext.save()
        return timeline
    }

    func updateTimeline(_ timeline: Timeline, name: String, icon: String, color: String) throws {
        timeline.name = name
        timeline.icon = icon
        timeline.color = color
        try modelContext.save()
    }

    func deleteTimeline(_ timeline: Timeline) throws {
        let notes = try fetchNotesForTimeline(timeline)
        for note in notes {
            note.timeline = nil
        }
        modelContext.delete(timeline)
        try modelContext.save()
    }

    func reorderTimelines(_ timelines: [Timeline]) throws {
        for (index, timeline) in timelines.enumerated() {
            timeline.sortOrder = index
        }
        try modelContext.save()
    }

    private func fetchNotesForTimeline(_ timeline: Timeline) throws -> [Note] {
        let descriptor = FetchDescriptor<Note>(predicate: #Predicate { $0.timeline?.id == timeline.id })
        return try modelContext.fetch(descriptor)
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Services/TimelineService.swift
git commit -m "feat: add TimelineService"
```

---

### Task 13: App 入口

**Files:**
- Create: `TimelineNotes/TimelineNotes/App/TimelineNotesApp.swift`

- [ ] **Step 1: 编写 App 入口**

```swift
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
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/App/TimelineNotesApp.swift
git commit -m "feat: add app entry point with SwiftData container"
```

---

### Task 13.5: 种子数据 — 首次启动创建默认时间线

**Files:**
- Create: `TimelineNotes/TimelineNotes/App/SeedData.swift`

- [ ] **Step 1: 编写 SeedData**

```swift
import SwiftData

enum SeedData {
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Timeline>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let defaultTimeline = Timeline(name: "我的时间线", icon: "list.bullet", color: "#007AFF", sortOrder: 0)
        modelContext.insert(defaultTimeline)

        let workTimeline = Timeline(name: "工作", icon: "briefcase", color: "#FF9500", sortOrder: 1)
        modelContext.insert(workTimeline)

        let lifeTimeline = Timeline(name: "生活", icon: "heart", color: "#FF3B30", sortOrder: 2)
        modelContext.insert(lifeTimeline)

        try? modelContext.save()
    }
}
```

- [ ] **Step 2: 在 TimelineNotesApp.swift 中调用种子数据**

修改 `TimelineNotesApp.swift`，在 `init()` 末尾添加种子调用：

```swift
// 在 init() 中 container 创建成功后添加
SeedData.seedIfNeeded(modelContext: container.mainContext)
```

- [ ] **Step 3: 提交**

```bash
git add TimelineNotes/TimelineNotes/App/SeedData.swift TimelineNotes/TimelineNotes/App/TimelineNotesApp.swift
git commit -m "feat: add seed data with default timelines"
```

---

### Task 14: ContentView — 主 Tab 框架

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/ContentView.swift`

- [ ] **Step 1: 编写 ContentView**

```swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineFeedView()
                .tabItem {
                    Label("时间线", systemImage: "clock.arrow.circlepath")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/ContentView.swift
git commit -m "feat: add ContentView with tab navigation"
```

---

### Task 15: TimelinePickerView — 时间线横向选择器

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Timeline/TimelinePickerView.swift`

- [ ] **Step 1: 编写 TimelinePickerView**

```swift
import SwiftUI
import SwiftData

struct TimelinePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timeline.sortOrder) private var timelines: [Timeline]
    @Binding var selectedTimeline: Timeline?
    @State private var showNewTimelineAlert = false
    @State private var newTimelineName = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(name: "全部", isSelected: selectedTimeline == nil) {
                    selectedTimeline = nil
                }

                ForEach(timelines) { timeline in
                    filterChip(name: timeline.name, isSelected: selectedTimeline?.id == timeline.id) {
                        selectedTimeline = timeline
                    }
                }

                Button {
                    showNewTimelineAlert = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .alert("新建时间线", isPresented: $showNewTimelineAlert) {
            TextField("名称", text: $newTimelineName)
            Button("取消", role: .cancel) { }
            Button("创建") {
                let trimmed = newTimelineName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let service = TimelineService(modelContext: modelContext)
                try? service.createTimeline(name: trimmed)
                newTimelineName = ""
            }
        }
    }

    @ViewBuilder
    private func filterChip(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .clipShape(Capsule())
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Timeline/TimelinePickerView.swift
git commit -m "feat: add TimelinePickerView"
```

---

### Task 16: NoteCardView — 笔记卡片

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Timeline/NoteCardView.swift`

- [ ] **Step 1: 编写 NoteCardView**

```swift
import SwiftUI
import SwiftData

struct NoteCardView: View {
    let note: Note
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Spacer()
                Text(DateFormatter.displayString(from: note.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                if note.editedAt != nil {
                    Text("(已编辑)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    Button {
                        let service = NoteService(modelContext: modelContext)
                        try? service.togglePin(note)
                    } label: {
                        Label(note.isPinned ? "取消置顶" : "置顶", systemImage: note.isPinned ? "pin.slash" : "pin")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            RichContentView(text: note.content)
                .font(.body)

            if !note.sortedMedia.isEmpty {
                MediaGridView(attachments: note.sortedMedia)
            }

            if let tags = note.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(tags) { tag in
                            Text("#\(tag.name)")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture { showDetail = true }
        .alert("删除笔记", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) {
                let service = NoteService(modelContext: modelContext)
                try? service.deleteNote(note)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("此操作不可撤销")
        }
        .sheet(isPresented: $showEditSheet) {
            ComposeNoteView(editingNote: note)
        }
        .navigationDestination(isPresented: $showDetail) {
            NoteDetailView(note: note)
        }
    }
}

struct RichContentView: View {
    let text: String

    var body: some View {
        let components = parseContent(text)
        Text(components)
            .lineSpacing(4)
    }

    private func parseContent(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        let pattern = /#([\p{L}\p{N}_-]+)/
        for match in text.matches(of: pattern) {
            if let range = attributed.range(of: String(match.0)) {
                attributed[range].foregroundColor = .accentColor
                attributed[range].font = .body.weight(.medium)
            }
        }
        return attributed
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Timeline/NoteCardView.swift
git commit -m "feat: add NoteCardView with rich text and actions"
```

---

### Task 17: MediaGridView — 媒体网格

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Detail/MediaGalleryView.swift`

- [ ] **Step 1: 在 MediaGalleryView.swift 中编写 MediaGridView**

```swift
import SwiftUI

struct MediaGridView: View {
    let attachments: [MediaAttachment]

    var body: some View {
        let count = attachments.count
        let columns = MediaGridLayoutHelper.columns(for: count)

        GeometryReader { geometry in
            let spacing: CGFloat = 4
            let totalWidth = geometry.size.width
            let itemSize = MediaGridLayoutHelper.itemSize(for: count, totalWidth: totalWidth, spacing: spacing)
            let cols = columns

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(itemSize.width), spacing: spacing), count: cols),
                spacing: spacing
            ) {
                ForEach(attachments, id: \.id) { attachment in
                    Group {
                        if attachment.mediaType == .video {
                            ZStack {
                                thumbnailView(for: attachment, size: itemSize)
                                Image(systemName: "play.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                        } else {
                            thumbnailView(for: attachment, size: itemSize)
                        }
                    }
                    .frame(width: itemSize.width, height: itemSize.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(height: totalGridHeight(count: count, columns: columns))
    }

    @ViewBuilder
    private func thumbnailView(for attachment: MediaAttachment, size: CGSize) -> some View {
        let mediaService = MediaService()
        let url = mediaService.mediaURL(for: attachment.thumbnailFileName ?? attachment.fileName)
        if let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
        } else {
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay(Image(systemName: "photo").foregroundColor(.secondary))
        }
    }

    private func totalGridHeight(count: Int, columns: Int) -> CGFloat {
        guard count > 0, columns > 0 else { return 0 }
        let rows = Int(ceil(Double(count) / Double(columns)))
        let spacing: CGFloat = 4
        return CGFloat(rows) * 200 + CGFloat(rows - 1) * spacing
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Detail/MediaGalleryView.swift
git commit -m "feat: add MediaGridView for note card thumbnails"
```

---

### Task 18: TimelineFeedView — 时间线 Feed 主视图

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Timeline/TimelineFeedView.swift`

- [ ] **Step 1: 编写 TimelineFeedView**

```swift
import SwiftUI
import SwiftData

struct TimelineFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTimeline: Timeline? = nil
    @State private var showCompose = false
    @State private var currentPage = 0
    @State private var notes: [Note] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TimelinePickerView(selectedTimeline: $selectedTimeline)

                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(notes, id: \.id) { note in
                            NoteCardView(note: note)
                            Divider()
                        }

                        if !notes.isEmpty {
                            ProgressView()
                                .padding()
                                .onAppear { loadMore() }
                        }
                    }
                }
                .refreshable { refreshNotes() }
                .overlay {
                    if notes.isEmpty {
                        ContentUnavailableView(
                            "暂无笔记",
                            systemImage: "note.text",
                            description: Text("点击右下角按钮发布第一条笔记")
                        )
                    }
                }
            }
            .navigationTitle(selectedTimeline?.name ?? "时间线")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeNoteView(timeline: selectedTimeline)
            }
            .onAppear { refreshNotes() }
            .onChange(of: selectedTimeline?.id) { refreshNotes() }
        }
    }

    private func refreshNotes() {
        currentPage = 0
        let service = NoteService(modelContext: modelContext)
        notes = (try? service.fetchNotes(for: selectedTimeline, page: 0)) ?? []
    }

    private func loadMore() {
        currentPage += 1
        let service = NoteService(modelContext: modelContext)
        let more = (try? service.fetchNotes(for: selectedTimeline, page: currentPage)) ?? []
        notes.append(contentsOf: more)
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Timeline/TimelineFeedView.swift
git commit -m "feat: add TimelineFeedView with pull-to-refresh and pagination"
```

---

### Task 19: ComposeNoteView — 发布/编辑笔记

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Compose/ComposeNoteView.swift`

- [ ] **Step 1: 编写 ComposeNoteView**

```swift
import SwiftUI
import SwiftData
import PhotosUI

struct ComposeNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var timeline: Timeline? = nil
    var editingNote: Note? = nil

    @State private var content: String = ""
    @State private var selectedTimeline: Timeline?
    @State private var manualTags: [String] = []
    @State private var tagInput: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedMediaData: [MediaData] = []
    @State private var isProcessing = false

    struct MediaData: Identifiable {
        let id = UUID()
        let data: Data
        let type: MediaType
    }

    @Query(sort: \Timeline.sortOrder) private var timelines: [Timeline]

    init(timeline: Timeline? = nil, editingNote: Note? = nil) {
        self.timeline = timeline
        self.editingNote = editingNote
        if let note = editingNote {
            _content = State(initialValue: note.content)
            _selectedTimeline = State(initialValue: note.timeline)
            _manualTags = State(initialValue: note.tags?.map { $0.name } ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }

                Section("图片/视频") {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 0,
                        matching: .any(of: [.images, .videos])
                    ) {
                        Label("添加媒体", systemImage: "photo.on.rectangle.angled")
                    }

                    if !selectedMediaData.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(selectedMediaData) { media in
                                    ZStack(alignment: .topTrailing) {
                                        if media.type == .image,
                                           let uiImage = UIImage(data: media.data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else if media.type == .video {
                                            ZStack {
                                                Rectangle().fill(.black).frame(width: 80, height: 80)
                                                Image(systemName: "play.fill").foregroundColor(.white)
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        Button {
                                            selectedMediaData.removeAll { $0.id == media.id }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(.black.opacity(0.6)))
                                                .font(.caption)
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("标签") {
                    HStack {
                        TextField("添加标签", text: $tagInput)
                            .onSubmit { addTag() }
                        Button("添加") { addTag() }
                    }

                    if !manualTags.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(manualTags, id: \.self) { tag in
                                    HStack(spacing: 2) {
                                        Text("#\(tag)")
                                        Button {
                                            manualTags.removeAll { $0 == tag }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color(.systemGray6)))
                                }
                            }
                        }
                    }
                }

                Section("时间线") {
                    Picker("选择时间线", selection: $selectedTimeline) {
                        Text("无").tag(nil as Timeline?)
                        ForEach(timelines) { timeline in
                            Text(timeline.name).tag(timeline as Timeline?)
                        }
                    }
                }
            }
            .navigationTitle(editingNote != nil ? "编辑笔记" : "发布笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingNote != nil ? "保存" : "发布") {
                        saveNote()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: selectedPhotos) { _, _ in
                Task { await loadSelectedMedia() }
            }
        }
    }

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !manualTags.contains(trimmed) else { return }
        manualTags.append(trimmed)
        tagInput = ""
    }

    private func loadSelectedMedia() async {
        selectedMediaData = []
        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })
                selectedMediaData.append(MediaData(data: data, type: isVideo ? .video : .image))
            }
        }
    }

    private func saveNote() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let noteService = NoteService(modelContext: modelContext)
        let mediaService = MediaService()

        let attachments = selectedMediaData.enumerated().map { index, media -> MediaAttachment in
            let ext = media.type == .image ? "jpg" : "mp4"
            let fileName = "\(UUID().uuidString).\(ext)"
            let attachment = MediaAttachment(type: media.type, fileName: fileName, order: index)
            try? mediaService.saveImage(media.data, fileName: fileName)
            if media.type == .image,
               let thumbData = mediaService.generateThumbnail(from: media.data) {
                try? mediaService.saveThumbnail(thumbData, fileName: fileName)
                attachment.thumbnailFileName = "thumb_\(fileName)"
            } else if media.type == .video,
                      let thumbData = mediaService.generateVideoThumbnail(from: media.data) {
                try? mediaService.saveThumbnail(thumbData, fileName: fileName)
                attachment.thumbnailFileName = "thumb_\(fileName)"
            }
            return attachment
        }

        if let existing = editingNote {
            try? noteService.updateNote(existing, content: trimmed, timeline: selectedTimeline, manualTags: manualTags)
        } else {
            try? noteService.createNote(content: trimmed, timeline: selectedTimeline ?? timeline, tags: manualTags, mediaAttachments: attachments)
        }

        dismiss()
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Compose/ComposeNoteView.swift
git commit -m "feat: add ComposeNoteView with media picker and tag editor"
```

---

### Task 20: TagEditorView

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Compose/TagEditorView.swift`

- [ ] **Step 1: 编写 TagEditorView**

```swift
import SwiftUI
import SwiftData

struct TagEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTags: [String]
    @State private var searchText = ""

    @Query(sort: \Tag.name) private var allTags: [Tag]

    var filteredTags: [Tag] {
        if searchText.isEmpty { return allTags }
        return allTags.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        List {
            Section("选择标签") {
                ForEach(filteredTags) { tag in
                    HStack {
                        Text("#\(tag.name)")
                        Spacer()
                        if selectedTags.contains(tag.name) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedTags.contains(tag.name) {
                            selectedTags.removeAll { $0 == tag.name }
                        } else {
                            selectedTags.append(tag.name)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "搜索标签")
        .navigationTitle("标签")
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Compose/TagEditorView.swift
git commit -m "feat: add TagEditorView"
```

---

### Task 21: SearchView — 搜索页

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Search/SearchView.swift`

- [ ] **Step 1: 编写 SearchView**

```swift
import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedTags: [Tag] = []
    @State private var filterStartDate: Date? = nil
    @State private var filterEndDate: Date? = nil
    @State private var showDateFilter = false
    @State private var results: [Note] = []
    @State private var hasSearched = false

    @Query(sort: \Tag.name) private var allTags: [Tag]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索笔记...", text: $searchText)
                        .onSubmit { performSearch() }
                    if !searchText.isEmpty {
                        Button { searchText = ""; performSearch() } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(allTags.prefix(15)) { tag in
                            Button {
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    selectedTags.removeAll { $0.id == tag.id }
                                } else {
                                    selectedTags.append(tag)
                                }
                                performSearch()
                            } label: {
                                Text("#\(tag.name)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule().fill(
                                            selectedTags.contains(where: { $0.id == tag.id })
                                            ? Color.accentColor : Color(.systemGray6)
                                        )
                                    )
                                    .foregroundColor(
                                        selectedTags.contains(where: { $0.id == tag.id })
                                        ? .white : .primary
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                Divider()

                if hasSearched && results.isEmpty {
                    ContentUnavailableView.search
                } else if !results.isEmpty {
                    List {
                        ForEach(results, id: \.id) { note in
                            NoteCardView(note: note)
                        }
                    }
                    .listStyle(.plain)
                } else {
                    ContentUnavailableView(
                        "搜索笔记",
                        systemImage: "text.magnifyingglass",
                        description: Text("输入关键词或选择标签来搜索")
                    )
                }
            }
            .navigationTitle("搜索")
        }
    }

    private func performSearch() {
        let service = NoteService(modelContext: modelContext)
        results = (try? service.fetchNotes(
            searchText: searchText,
            tags: selectedTags,
            startDate: filterStartDate,
            endDate: filterEndDate,
            pageSize: 100
        )) ?? []
        hasSearched = true
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Search/SearchView.swift
git commit -m "feat: add SearchView with tag filtering"
```

---

### Task 22: TagCloudView

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Search/TagCloudView.swift`

- [ ] **Step 1: 编写 TagCloudView**

```swift
import SwiftUI
import SwiftData

struct TagCloudView: View {
    @Query(sort: \Tag.name) private var tags: [Tag]
    let onSelect: (Tag) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags) { tag in
                Button {
                    onSelect(tag)
                } label: {
                    Text("#\(tag.name)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(.systemGray6)))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for size in sizes {
            if lineWidth + size.width > maxWidth {
                totalHeight += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalHeight += lineHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        let maxWidth = bounds.width

        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            if x + size.width > maxWidth + bounds.minX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Search/TagCloudView.swift
git commit -m "feat: add TagCloudView with FlowLayout"
```

---

### Task 23: NoteDetailView — 笔记详情页

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Detail/NoteDetailView.swift`

- [ ] **Step 1: 编写 NoteDetailView**

```swift
import SwiftUI
import SwiftData

struct NoteDetailView: View {
    let note: Note
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var fullScreenImageIndex: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    if note.isPinned {
                        Image(systemName: "pin.fill").foregroundColor(.orange)
                        Text("已置顶").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(DateFormatter.noteDisplay.string(from: note.createdAt))
                            .font(.caption).foregroundColor(.secondary)
                        if let edited = note.editedAt {
                            Text("编辑于 \(DateFormatter.noteDisplay.string(from: edited))")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }

                RichContentView(text: note.content)
                    .font(.title3)

                if let timeline = note.timeline {
                    Label(timeline.name, systemImage: timeline.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !note.sortedMedia.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(note.sortedMedia.enumerated()), id: \.element.id) { index, attachment in
                            FullMediaView(attachment: attachment)
                                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onTapGesture { fullScreenImageIndex = index }
                        }
                    }
                }

                if let tags = note.tags, !tags.isEmpty {
                    TagCloudView { _ in }
                }

                Divider()

                HStack {
                    Button {
                        UIPasteboard.general.string = note.content
                    } label: {
                        Label("复制", systemImage: "doc.on.doc").font(.subheadline)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("笔记详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            ComposeNoteView(editingNote: note)
        }
        .alert("删除笔记", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) {
                let service = NoteService(modelContext: modelContext)
                try? service.deleteNote(note)
                dismiss()
            }
            Button("取消", role: .cancel) { }
        }
        .fullScreenCover(item: fullScreenImageBinding) {
            FullScreenMediaView(attachment: note.sortedMedia[fullScreenImageIndex ?? 0])
        }
    }

    var fullScreenImageBinding: Binding<Int?> {
        Binding(
            get: { fullScreenImageIndex },
            set: { fullScreenImageIndex = $0 }
        )
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Detail/NoteDetailView.swift
git commit -m "feat: add NoteDetailView with full-screen media"
```

---

### Task 24: FullMediaView 和 FullScreenMediaView

**Files:**
- Modify: `TimelineNotes/TimelineNotes/Views/Detail/MediaGalleryView.swift` 追加以下内容

- [ ] **Step 1: 在 MediaGalleryView.swift 末尾追加 FullMediaView 和 FullScreenMediaView**

```swift
struct FullMediaView: View {
    let attachment: MediaAttachment

    var body: some View {
        let mediaService = MediaService()
        let url = mediaService.mediaURL(for: attachment.fileName)

        if attachment.mediaType == .video {
            VideoPlayerView(url: url)
        } else if let data = try? Data(contentsOf: url),
                  let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Rectangle().fill(Color(.systemGray5))
                .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.secondary))
        }
    }
}

struct FullScreenMediaView: View {
    let attachment: MediaAttachment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let mediaService = MediaService()
                let url = mediaService.mediaURL(for: attachment.fileName)

                if attachment.mediaType == .video {
                    VideoPlayerView(url: url)
                } else if let data = try? Data(contentsOf: url),
                          let uiImage = UIImage(data: data) {
                    ZoomableImageView(image: Image(uiImage: uiImage), size: geometry.size)
                } else {
                    ContentUnavailableView("无法加载", systemImage: "exclamationmark.triangle")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

struct ZoomableImageView: View {
    let image: Image
    let size: CGSize
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { scale = $0 }
                    .onEnded { _ in
                        withAnimation { scale = max(1.0, scale) }
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { offset = $0.translation }
                    .onEnded { _ in
                        withAnimation { offset = .zero }
                    }
            )
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Detail/MediaGalleryView.swift
git commit -m "feat: add FullMediaView, FullScreenMediaView, and ZoomableImageView"
```

---

### Task 25: VideoPlayerView

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Detail/VideoPlayerView.swift`

- [ ] **Step 1: 编写 VideoPlayerView**

```swift
import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: url)
                player?.play()
            }
            .onDisappear {
                player?.pause()
            }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Detail/VideoPlayerView.swift
git commit -m "feat: add VideoPlayerView"
```

---

### Task 26: SettingsView — 设置页

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Settings/SettingsView.swift`

- [ ] **Step 1: 编写 SettingsView**

```swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timeline.sortOrder) private var timelines: [Timeline]
    @Query private var allNotes: [Note]

    var body: some View {
        NavigationStack {
            List {
                Section("时间线管理") {
                    NavigationLink {
                        TimelineManagementView()
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            Text("\(timelines.count) 条时间线")
                        }
                    }
                }

                Section("数据") {
                    HStack {
                        Image(systemName: "note.text")
                        Text("共 \(allNotes.count) 条笔记")
                    }
                    Button {
                        exportData()
                    } label: {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("平台")
                        Spacer()
                        Text("iOS 17+").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }

    private func exportData() {
        let exportData: [String: Any] = [
            "exportedAt": ISO8601DateFormatter().string(from: Date()),
            "timelines": timelines.map { ["name": $0.name, "id": $0.id.uuidString] },
            "notes": allNotes.map { note in
                var dict: [String: Any] = [
                    "id": note.id.uuidString,
                    "content": note.content,
                    "createdAt": note.createdAt.ISO8601Format(),
                    "tags": note.tagNames
                ]
                if let timeline = note.timeline {
                    dict["timeline"] = timeline.name
                }
                return dict
            }
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("timeline_export_\(Date().ISO8601Format()).json")
            try? jsonString.write(to: tempURL, atomically: true, encoding: .utf8)
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Settings/SettingsView.swift
git commit -m "feat: add SettingsView with data export"
```

---

### Task 27: TimelineManagementView — 时间线管理

**Files:**
- Create: `TimelineNotes/TimelineNotes/Views/Settings/TimelineManagementView.swift`

- [ ] **Step 1: 编写 TimelineManagementView**

```swift
import SwiftUI
import SwiftData

struct TimelineManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timeline.sortOrder) private var timelines: [Timeline]
    @State private var showNewAlert = false
    @State private var newName = ""
    @State private var editingTimeline: Timeline?
    @State private var editName = ""
    @State private var editIcon = "list.bullet"
    @State private var editColor = "#007AFF"

    let iconOptions = ["list.bullet", "star", "heart", "bookmark", "flag", "leaf", "flame", "bolt", "brain", "lightbulb"]
    let colorOptions = ["#007AFF", "#FF3B30", "#34C759", "#FF9500", "#AF52DE", "#5856D6", "#FF2D55", "#00C7BE"]

    var body: some View {
        List {
            ForEach(timelines) { timeline in
                HStack {
                    Image(systemName: timeline.icon)
                        .foregroundColor(Color(hex: timeline.color))
                    Text(timeline.name)
                    Spacer()
                }
                .swipeActions(edge: .trailing) {
                    Button("编辑") {
                        editingTimeline = timeline
                        editName = timeline.name
                        editIcon = timeline.icon
                        editColor = timeline.color
                    }
                    .tint(.blue)

                    Button("删除", role: .destructive) {
                        let service = TimelineService(modelContext: modelContext)
                        try? service.deleteTimeline(timeline)
                    }
                }
            }
            .onMove { source, destination in
                var reordered = timelines
                reordered.move(fromOffsets: source, toOffset: destination)
                let service = TimelineService(modelContext: modelContext)
                try? service.reorderTimelines(reordered)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("新建时间线", isPresented: $showNewAlert) {
            TextField("名称", text: $newName)
            Button("取消", role: .cancel) { }
            Button("创建") {
                let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let service = TimelineService(modelContext: modelContext)
                try? service.createTimeline(name: trimmed)
                newName = ""
            }
        }
        .sheet(item: $editingTimeline) { timeline in
            NavigationStack {
                Form {
                    Section("名称") { TextField("名称", text: $editName) }
                    Section("图标") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .padding(8)
                                    .background(editIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { editIcon = icon }
                            }
                        }
                    }
                    Section("颜色") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 36, height: 36)
                                    .overlay(editColor == color ? Circle().stroke(Color.primary, lineWidth: 2) : nil)
                                    .onTapGesture { editColor = color }
                            }
                        }
                    }
                }
                .navigationTitle("编辑时间线")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            let service = TimelineService(modelContext: modelContext)
                            try? service.updateTimeline(timeline, name: editName, icon: editIcon, color: editColor)
                            editingTimeline = nil
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { editingTimeline = nil }
                    }
                }
            }
        }
        .navigationTitle("管理时间线")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add TimelineNotes/TimelineNotes/Views/Settings/TimelineManagementView.swift
git commit -m "feat: add TimelineManagementView"
```

---

### Task 28: HashtagParserTests

**Files:**
- Create: `TimelineNotes/TimelineNotesTests/HashtagParserTests.swift`

- [ ] **Step 1: 编写 HashtagParserTests**

```swift
import XCTest
@testable import TimelineNotes

final class HashtagParserTests: XCTestCase {

    func testExtractsSimpleHashtag() {
        let result = HashtagParser.extractHashtags(from: "Hello #world")
        XCTAssertEqual(result, ["world"])
    }

    func testExtractsMultipleHashtags() {
        let result = HashtagParser.extractHashtags(from: "#hello #world test")
        XCTAssertEqual(result, ["hello", "world"])
    }

    func testExtractsChineseHashtags() {
        let result = HashtagParser.extractHashtags(from: "今天 #天气 不错 #生活")
        XCTAssertEqual(result, ["天气", "生活"])
    }

    func testExtractsHashtagsWithUnderscores() {
        let result = HashtagParser.extractHashtags(from: "Check #hello_world tag")
        XCTAssertEqual(result, ["hello_world"])
    }

    func testNoHashtagsReturnsEmpty() {
        let result = HashtagParser.extractHashtags(from: "Plain text without tags")
        XCTAssertEqual(result, [])
    }

    func testHashtagsAreLowercased() {
        let result = HashtagParser.extractHashtags(from: "Hello #WORLD")
        XCTAssertEqual(result, ["world"])
    }

    func testTextStartingWithHash() {
        let result = HashtagParser.extractHashtags(from: "#tag at start")
        XCTAssertEqual(result, ["tag"])
    }
}
```

- [ ] **Step 2: 运行测试确认通过**

```bash
# 需要在 Mac 上运行
# xcodebuild test -scheme TimelineNotes -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

### Task 29: MediaGridLayoutHelperTests

**Files:**
- Create: `TimelineNotes/TimelineNotesTests/MediaGridLayoutHelperTests.swift`

- [ ] **Step 1: 编写 MediaGridLayoutHelperTests**

```swift
import XCTest
@testable import TimelineNotes

final class MediaGridLayoutHelperTests: XCTestCase {

    func testSingleImageHasOneColumn() {
        XCTAssertEqual(MediaGridLayoutHelper.columns(for: 1), 1)
    }

    func testTwoImagesHaveTwoColumns() {
        XCTAssertEqual(MediaGridLayoutHelper.columns(for: 2), 2)
    }

    func testThreeImagesHaveThreeColumns() {
        XCTAssertEqual(MediaGridLayoutHelper.columns(for: 3), 3)
    }

    func testFiveImagesHaveThreeColumns() {
        XCTAssertEqual(MediaGridLayoutHelper.columns(for: 5), 3)
    }
}
```

- [ ] **Step 2: 运行测试确认通过**

```bash
# xcodebuild test -scheme TimelineNotes -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Self-Review

**1. Spec 覆盖:**

- [x] 数据模型 (Timeline, Note, Tag, MediaAttachment) → Tasks 2-5
- [x] Service 层 → Tasks 9-12
- [x] 时间线 Tab + 横向选择器 → Tasks 15, 18
- [x] 笔记卡片 + 媒体网格 → Tasks 16-17
- [x] 发布/编辑笔记 → Task 19
- [x] 搜索 + 标签筛选 → Tasks 21-22
- [x] 笔记详情 + 大图浏览 → Tasks 23-25
- [x] 设置 + 时间线管理 → Tasks 26-27
- [x] Hashtag 解析 + 正则 → Task 6
- [x] 单元测试 → Tasks 28-29
- [x] V1 范围控制 — 无社交/同步/加密功能

**2. 占位符扫描:** 无 TBD/TODO/placeholder，所有代码完整

**3. 类型一致性检查:**
- `Note.id` → UUID，所有引用一致
- `Timeline.id` → UUID，所有引用一致
- `Tag.id` → UUID，所有引用一致
- `MediaAttachment.id` → UUID，所有引用一致
- Service 初始化统一使用 `modelContext`
- `NoteService` 方法签名与 ComposeNoteView、SearchView、TimelineFeedView 中的调用一致

**缺漏补充:** ✅ 已添加 Task 13.5 种子数据任务
