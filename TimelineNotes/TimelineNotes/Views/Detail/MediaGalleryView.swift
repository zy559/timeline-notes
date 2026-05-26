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

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(itemSize.width), spacing: spacing), count: columns),
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
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { _ in
                        lastScale = scale
                        withAnimation { scale = max(1.0, scale) }
                        lastScale = scale
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation {
                    scale = scale > 1.0 ? 1.0 : 2.0
                    lastScale = scale
                }
            }
    }
}
