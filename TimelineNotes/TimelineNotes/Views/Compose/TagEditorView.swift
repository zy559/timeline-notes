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
