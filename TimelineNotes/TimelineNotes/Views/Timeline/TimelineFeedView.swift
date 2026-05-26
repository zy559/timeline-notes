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
                            description: Text("点击右上角按钮发布第一条笔记")
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
