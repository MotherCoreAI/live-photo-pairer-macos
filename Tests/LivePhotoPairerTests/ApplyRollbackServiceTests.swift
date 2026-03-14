import XCTest
@testable import LivePhotoPairerCore

final class ApplyRollbackServiceTests: XCTestCase {
    func testApplyAndRollbackRoundTrip() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        let imageURL = root.appendingPathComponent("IMG_E1234.heic")
        let videoURL = root.appendingPathComponent("IMG_9384.mov")
        try Data("image".utf8).write(to: imageURL)
        try Data("video".utf8).write(to: videoURL)

        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let image = MediaFile(url: imageURL, kind: .image, createdAt: date, contentIdentifier: nil, originalStem: "IMG_E1234", fileSize: nil, durationSeconds: nil, pixelWidth: nil, pixelHeight: nil)
        let video = MediaFile(url: videoURL, kind: .video, createdAt: date, contentIdentifier: nil, originalStem: "IMG_9384", fileSize: nil, durationSeconds: 2, pixelWidth: nil, pixelHeight: nil)
        let pair = MatchPair(image: image, video: video, confidence: .medium, reasons: ["timestamp"], proposedBaseName: "LP_2024-01-01_10-00-00_001")
        let result = ScanResult(rootFolder: root, scannedAt: Date(), mediaFiles: [image, video], pairs: [pair], unmatchedImages: [], unmatchedVideos: [], ambiguous: [], summary: ScanSummary())

        let plans = RenamePlanner().plan(for: [pair])
        let service = ApplyRollbackService()
        let batch = try service.apply(scanResult: result, plans: plans)

        XCTAssertEqual(batch.operations.count, 2)
        XCTAssertTrue(fm.fileExists(atPath: root.appendingPathComponent("LP_2024-01-01_10-00-00_001.heic").path))
        XCTAssertTrue(fm.fileExists(atPath: root.appendingPathComponent("LP_2024-01-01_10-00-00_001.mov").path))

        let rolledBack = try service.rollbackLastBatch(in: root)
        XCTAssertEqual(rolledBack, 2)
        XCTAssertTrue(fm.fileExists(atPath: imageURL.path))
        XCTAssertTrue(fm.fileExists(atPath: videoURL.path))
    }
}
