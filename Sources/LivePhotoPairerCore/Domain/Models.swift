import Foundation

public enum MediaKind: String, Codable, CaseIterable {
    case image
    case video
}

public enum MatchConfidence: String, Codable, CaseIterable, Comparable {
    case high
    case medium
    case low

    public static func < (lhs: MatchConfidence, rhs: MatchConfidence) -> Bool {
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

public enum PairStatus: String, Codable {
    case planned
    case applied
    case skipped
    case failed
}

public struct MediaFile: Identifiable, Hashable, Codable {
    public let id: UUID
    public let url: URL
    public let kind: MediaKind
    public let createdAt: Date?
    public let contentIdentifier: String?
    public let originalStem: String
    public let fileSize: Int64?
    public let durationSeconds: Double?
    public let pixelWidth: Int?
    public let pixelHeight: Int?

    public init(
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

public struct MatchPair: Identifiable, Hashable, Codable {
    public let id: UUID
    public let image: MediaFile
    public let video: MediaFile
    public let confidence: MatchConfidence
    public let reasons: [String]
    public let proposedBaseName: String
    public var status: PairStatus
    public var failureReason: String?

    public init(
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

public struct AmbiguousCandidate: Identifiable, Hashable, Codable {
    public let id: UUID
    public let image: MediaFile
    public let candidates: [MediaFile]
    public let reasons: [String]

    public init(id: UUID = UUID(), image: MediaFile, candidates: [MediaFile], reasons: [String]) {
        self.id = id
        self.image = image
        self.candidates = candidates
        self.reasons = reasons
    }
}

public struct ScanSummary: Codable {
    public var filesScanned: Int = 0
    public var images: Int = 0
    public var videos: Int = 0
    public var pairsMatched: Int = 0
    public var pairsApplied: Int = 0
    public var unmatchedImages: Int = 0
    public var unmatchedVideos: Int = 0
    public var ambiguous: Int = 0

    public init() {}
}

public struct ScanResult: Codable {
    public var rootFolder: URL
    public var scannedAt: Date
    public var mediaFiles: [MediaFile]
    public var pairs: [MatchPair]
    public var unmatchedImages: [MediaFile]
    public var unmatchedVideos: [MediaFile]
    public var ambiguous: [AmbiguousCandidate]
    public var summary: ScanSummary

    public init(rootFolder: URL, scannedAt: Date, mediaFiles: [MediaFile], pairs: [MatchPair], unmatchedImages: [MediaFile], unmatchedVideos: [MediaFile], ambiguous: [AmbiguousCandidate], summary: ScanSummary) {
        self.rootFolder = rootFolder
        self.scannedAt = scannedAt
        self.mediaFiles = mediaFiles
        self.pairs = pairs
        self.unmatchedImages = unmatchedImages
        self.unmatchedVideos = unmatchedVideos
        self.ambiguous = ambiguous
        self.summary = summary
    }
}

public struct RenameOperation: Identifiable, Hashable, Codable {
    public let id: UUID
    public let originalPath: String
    public let newPath: String
    public let appliedAt: Date

    public init(id: UUID = UUID(), originalPath: String, newPath: String, appliedAt: Date = Date()) {
        self.id = id
        self.originalPath = originalPath
        self.newPath = newPath
        self.appliedAt = appliedAt
    }
}

public struct RollbackBatch: Codable {
    public let createdAt: Date
    public let rootFolder: String
    public let operations: [RenameOperation]

    public init(createdAt: Date, rootFolder: String, operations: [RenameOperation]) {
        self.createdAt = createdAt
        self.rootFolder = rootFolder
        self.operations = operations
    }
}
