import Foundation

enum Formatting {
    static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()

    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    static func basename(for date: Date, index: Int) -> String {
        String(format: "LP_%@_%03d", timestampFormatter.string(from: date), index)
    }
}
