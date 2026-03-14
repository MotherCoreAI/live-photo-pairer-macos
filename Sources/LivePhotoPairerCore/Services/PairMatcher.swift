import Foundation

public struct PairMatcher {
    public let includeLowConfidence: Bool
    public let timeThreshold: TimeInterval

    public init(includeLowConfidence: Bool = false, timeThreshold: TimeInterval = 3) {
        self.includeLowConfidence = includeLowConfidence
        self.timeThreshold = timeThreshold
    }

    public func match(rootFolder: URL, mediaFiles: [MediaFile]) -> ScanResult {
        let images = mediaFiles.filter { $0.kind == .image }
        let videos = mediaFiles.filter { $0.kind == .video }

        var matchedPairs: [MatchPair] = []
        var usedImages = Set<UUID>()
        var usedVideos = Set<UUID>()
        var ambiguous: [AmbiguousCandidate] = []
        var index = 1

        for image in images {
            let candidates = videos.compactMap { video -> (MediaFile, MatchConfidence, [String], Int)? in
                guard let score = score(image: image, video: video) else { return nil }
                return (video, score.confidence, score.reasons, score.numericScore)
            }
            .sorted { lhs, rhs in
                if lhs.3 != rhs.3 { return lhs.3 > rhs.3 }
                return (lhs.0.createdAt ?? .distantPast) < (rhs.0.createdAt ?? .distantPast)
            }

            guard let best = candidates.first else { continue }
            if usedImages.contains(image.id) || usedVideos.contains(best.0.id) { continue }

            let closeAlternatives = candidates.filter { $0.3 == best.3 }
            if closeAlternatives.count > 1 && best.1 != .high {
                ambiguous.append(AmbiguousCandidate(
                    image: image,
                    candidates: closeAlternatives.map(\.0),
                    reasons: ["multiple_equal_candidates"]
                ))
                continue
            }

            if best.1 == .low && !includeLowConfidence {
                ambiguous.append(AmbiguousCandidate(
                    image: image,
                    candidates: [best.0],
                    reasons: ["low_confidence_excluded"] + best.2
                ))
                continue
            }

            usedImages.insert(image.id)
            usedVideos.insert(best.0.id)
            let baseDate = image.createdAt ?? best.0.createdAt ?? Date()
            matchedPairs.append(MatchPair(
                image: image,
                video: best.0,
                confidence: best.1,
                reasons: best.2,
                proposedBaseName: Formatting.basename(for: baseDate, index: index)
            ))
            index += 1
        }

        let unmatchedImages = images.filter { !usedImages.contains($0.id) }
        let unmatchedVideos = videos.filter { !usedVideos.contains($0.id) }

        var summary = ScanSummary()
        summary.filesScanned = mediaFiles.count
        summary.images = images.count
        summary.videos = videos.count
        summary.pairsMatched = matchedPairs.count
        summary.unmatchedImages = unmatchedImages.count
        summary.unmatchedVideos = unmatchedVideos.count
        summary.ambiguous = ambiguous.count

        return ScanResult(
            rootFolder: rootFolder,
            scannedAt: Date(),
            mediaFiles: mediaFiles,
            pairs: matchedPairs,
            unmatchedImages: unmatchedImages,
            unmatchedVideos: unmatchedVideos,
            ambiguous: ambiguous,
            summary: summary
        )
    }

    private func score(image: MediaFile, video: MediaFile) -> (confidence: MatchConfidence, reasons: [String], numericScore: Int)? {
        var score = 0
        var reasons: [String] = []

        if let imageID = image.contentIdentifier,
           let videoID = video.contentIdentifier,
           !imageID.isEmpty,
           imageID == videoID {
            score += 100
            reasons.append("shared_content_identifier")
        }

        if let imageDate = image.createdAt,
           let videoDate = video.createdAt {
            let delta = abs(imageDate.timeIntervalSince(videoDate))
            if delta <= timeThreshold {
                score += 30
                reasons.append("timestamp_within_\(Int(timeThreshold))s")
            } else if delta <= 10 {
                score += 10
                reasons.append("timestamp_within_10s")
            } else {
                return nil
            }
        }

        let imageStem = normalizedStem(image.originalStem)
        let videoStem = normalizedStem(video.originalStem)
        if imageStem == videoStem {
            score += 20
            reasons.append("matching_filename_stem")
        } else if imageStem.hasSuffix(videoStem) || videoStem.hasSuffix(imageStem) {
            score += 8
            reasons.append("similar_filename_stem")
        }

        if let duration = video.durationSeconds, duration > 0, duration <= 4.5 {
            score += 10
            reasons.append("live_photo_like_duration")
        }

        if let iw = image.pixelWidth, let vw = video.pixelWidth, abs(iw - vw) < 2500 {
            score += 3
            reasons.append("plausible_dimensions")
        }

        guard score > 0 else { return nil }

        let confidence: MatchConfidence
        if score >= 100 {
            confidence = .high
        } else if score >= 35 {
            confidence = .medium
        } else {
            confidence = .low
        }

        return (confidence, reasons, score)
    }

    private func normalizedStem(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "img_e", with: "img_")
            .replacingOccurrences(of: "live", with: "")
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }
}
