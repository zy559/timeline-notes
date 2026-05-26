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
            return tag.lowercased()
        }.filter { !$0.isEmpty }
    }
}
