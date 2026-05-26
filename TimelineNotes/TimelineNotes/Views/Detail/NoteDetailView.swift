import SwiftUI
import SwiftData

struct NoteDetailView: View {
    let note: Note
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var fullScreenMediaIndex: Int?

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
                                .onTapGesture { fullScreenMediaIndex = index }
                        }
                    }
                }

                if let tags = note.tags, !tags.isEmpty {
                    FlowLayoutView(spacing: 6) {
                        ForEach(tags) { tag in
                            Text("#\(tag.name)")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color(.systemGray6)))
                                .foregroundColor(.primary)
                        }
                    }
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
                        Button { showEditSheet = true } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        Button(role: .destructive) { showDeleteAlert = true } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle").font(.title3)
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
        .fullScreenCover(item: Binding(
            get: { fullScreenMediaIndex.map { note.sortedMedia[$0] } },
            set: { _ in fullScreenMediaIndex = nil }
        )) { attachment in
            FullScreenMediaView(attachment: attachment)
        }
    }
}
