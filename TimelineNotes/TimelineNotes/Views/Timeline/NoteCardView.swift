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
        let attributed = parseContent(text)
        Text(attributed)
            .lineSpacing(4)
    }

    private func parseContent(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        let pattern = try! Regex("#([\\p{L}\\p{N}_-]+)")
        for match in text.matches(of: pattern) {
            if let range = attributed.range(of: String(match.0)) {
                attributed[range].foregroundColor = .accentColor
                attributed[range].font = .body.weight(.medium)
            }
        }
        return attributed
    }
}
