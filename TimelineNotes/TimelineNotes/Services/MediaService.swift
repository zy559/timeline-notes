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
