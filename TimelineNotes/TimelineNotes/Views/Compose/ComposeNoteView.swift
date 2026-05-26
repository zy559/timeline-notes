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

    struct MediaData: Identifiable {
        let id = UUID()
        let data: Data
        let type: MediaType
    }

    @Query(sort: \Timeline.sortOrder) private var timelines: [Timeline]
    @State private var didLoadInitialValues = false

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
            .onAppear {
                guard !didLoadInitialValues else { return }
                didLoadInitialValues = true
                if let note = editingNote {
                    content = note.content
                    selectedTimeline = note.timeline
                    manualTags = note.tags?.map { $0.name } ?? []
                }
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
