import Foundation

public struct ReportGenerator {
    public init() {}

    public func write(scanResult: ScanResult, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(scanResult).write(to: url)
    }
}
