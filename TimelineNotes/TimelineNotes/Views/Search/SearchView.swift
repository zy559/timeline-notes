import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedTags: [Tag] = []
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
            pageSize: 100
        )) ?? []
        hasSearched = true
    }
}
