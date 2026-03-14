import XCTest
@testable import LivePhotoPairerApp

final class RenamePlannerTests: XCTestCase {
    func testPlannerPreservesSharedBaseNameAcrossPair() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let image = MediaFile(
            url: URL(fileURLWithPath: "/tmp/one.heic"),
            kind: .image,
            createdAt: date,
            contentIdentifier: nil,
            originalStem: "one",
            fileSize: nil,
            durationSeconds: nil,
            pixelWidth: nil,
            pixelHeight: nil
        )
        let video = MediaFile(
            url: URL(fileURLWithPath: "/tmp/two.mov"),
            kind: .video,
            createdAt: date,
            contentIdentifier: nil,
            originalStem: "two",
            fileSize: nil,
            durationSeconds: 2,
            pixelWidth: nil,
            pixelHeight: nil
        )
        let pair = MatchPair(image: image, video: video, confidence: .medium, reasons: ["timestamp"], proposedBaseName: "LP_2024-01-01_10-00-00_001")

        let plans = RenamePlanner().plan(for: [pair])
        XCTAssertEqual(plans.count, 2)
        XCTAssertEqual(plans[0].destinationURL.deletingPathExtension().lastPathComponent, "LP_2024-01-01_10-00-00_001")
        XCTAssertEqual(plans[1].destinationURL.deletingPathExtension().lastPathComponent, "LP_2024-01-01_10-00-00_001")
    }
}
