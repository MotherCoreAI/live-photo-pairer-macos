import XCTest
@testable import LivePhotoPairerApp

final class PairMatcherTests: XCTestCase {
    func testHighConfidenceContentIdentifierMatch() {
        let now = Date()
        let image = MediaFile(
            url: URL(fileURLWithPath: "/tmp/a.heic"),
            kind: .image,
            createdAt: now,
            contentIdentifier: "abc",
            originalStem: "IMG_E1234",
            fileSize: nil,
            durationSeconds: nil,
            pixelWidth: 4032,
            pixelHeight: 3024
        )
        let video = MediaFile(
            url: URL(fileURLWithPath: "/tmp/b.mov"),
            kind: .video,
            createdAt: now,
            contentIdentifier: "abc",
            originalStem: "IMG_9384",
            fileSize: nil,
            durationSeconds: 2.1,
            pixelWidth: 1920,
            pixelHeight: 1080
        )

        let result = PairMatcher().match(rootFolder: URL(fileURLWithPath: "/tmp"), mediaFiles: [image, video])
        XCTAssertEqual(result.pairs.count, 1)
        XCTAssertEqual(result.pairs.first?.confidence, .high)
    }

    func testLowConfidenceExcludedByDefault() {
        let now = Date()
        let image = MediaFile(
            url: URL(fileURLWithPath: "/tmp/a.heic"),
            kind: .image,
            createdAt: now,
            contentIdentifier: nil,
            originalStem: "a",
            fileSize: nil,
            durationSeconds: nil,
            pixelWidth: nil,
            pixelHeight: nil
        )
        let video = MediaFile(
            url: URL(fileURLWithPath: "/tmp/b.mov"),
            kind: .video,
            createdAt: now.addingTimeInterval(8),
            contentIdentifier: nil,
            originalStem: "b",
            fileSize: nil,
            durationSeconds: nil,
            pixelWidth: nil,
            pixelHeight: nil
        )

        let result = PairMatcher().match(rootFolder: URL(fileURLWithPath: "/tmp"), mediaFiles: [image, video])
        XCTAssertEqual(result.pairs.count, 0)
    }
}
