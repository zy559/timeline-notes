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
