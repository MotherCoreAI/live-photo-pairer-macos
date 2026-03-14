import Foundation

enum MediaKind: String, Codable, CaseIterable {
    case image
    case video
}

enum MatchConfidence: String, Codable, CaseIterable, Comparable {
    case high
    case medium
    case low

    static func < (lhs: MatchConfidence, rhs: MatchConfidence) -> Bool {
        order(lhs) < order(rhs)
    }

    private static func order(_ value: MatchConfidence) -> Int {
        switch value {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
}

enum PairStatus: String, Codable {
    case planned
    case applied
    case skipped
    case failed
}

struct MediaFile: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
    let kind: MediaKind
    let createdAt: Date?
    let contentIdentifier: String?
    let originalStem: String
    let fileSize: Int64?
    let durationSeconds: Double?
    let pixelWidth: Int?
    let pixelHeight: Int?

    init(
        id: UUID = UUID(),
        url: URL,
        kind: MediaKind,
        createdAt: Date?,
        contentIdentifier: String?,
        originalStem: String,
        fileSize: Int64?,
        durationSeconds: Double?,
        pixelWidth: Int?,
        pixelHeight: Int?
    ) {
        self.id = id
        self.url = url
        self.kind = kind
        self.createdAt = createdAt
        self.contentIdentifier = contentIdentifier
        self.originalStem = originalStem
        self.fileSize = fileSize
        self.durationSeconds = durationSeconds
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

struct MatchPair: Identifiable, Hashable, Codable {
    let id: UUID
    let image: MediaFile
    let video: MediaFile
    let confidence: MatchConfidence
    let reasons: [String]
    let proposedBaseName: String
    var status: PairStatus
    var failureReason: String?

    init(
        id: UUID = UUID(),
        image: MediaFile,
        video: MediaFile,
        confidence: MatchConfidence,
        reasons: [String],
        proposedBaseName: String,
        status: PairStatus = .planned,
        failureReason: String? = nil
    ) {
        self.id = id
        self.image = image
        self.video = video
        self.confidence = confidence
        self.reasons = reasons
        self.proposedBaseName = proposedBaseName
        self.status = status
        self.failureReason = failureReason
    }
}

struct AmbiguousCandidate: Identifiable, Hashable, Codable {
    let id: UUID
    let image: MediaFile
    let candidates: [MediaFile]
    let reasons: [String]

    init(id: UUID = UUID(), image: MediaFile, candidates: [MediaFile], reasons: [String]) {
        self.id = id
        self.image = image
        self.candidates = candidates
        self.reasons = reasons
    }
}

struct ScanSummary: Codable {
    var filesScanned: Int = 0
    var images: Int = 0
    var videos: Int = 0
    var pairsMatched: Int = 0
    var pairsApplied: Int = 0
    var unmatchedImages: Int = 0
    var unmatchedVideos: Int = 0
    var ambiguous: Int = 0
}

struct ScanResult: Codable {
    var rootFolder: URL
    var scannedAt: Date
    var mediaFiles: [MediaFile]
    var pairs: [MatchPair]
    var unmatchedImages: [MediaFile]
    var unmatchedVideos: [MediaFile]
    var ambiguous: [AmbiguousCandidate]
    var summary: ScanSummary
}

struct RenameOperation: Identifiable, Hashable, Codable {
    let id: UUID
    let originalPath: String
    let newPath: String
    let appliedAt: Date

    init(id: UUID = UUID(), originalPath: String, newPath: String, appliedAt: Date = Date()) {
        self.id = id
        self.originalPath = originalPath
        self.newPath = newPath
        self.appliedAt = appliedAt
    }
}

struct RollbackBatch: Codable {
    let createdAt: Date
    let rootFolder: String
    let operations: [RenameOperation]
}
