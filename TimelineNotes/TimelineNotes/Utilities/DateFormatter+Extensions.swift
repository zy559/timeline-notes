import Foundation

extension DateFormatter {
    static let noteDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let relativeDate: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter
    }()

    static func displayString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        if interval >= 0 && interval < 86400 {
            return relativeDate.localizedString(for: date, relativeTo: now)
        }
        return noteDisplay.string(from: date)
    }
}
