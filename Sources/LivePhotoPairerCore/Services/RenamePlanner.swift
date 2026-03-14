import Foundation

struct PlannedRename: Identifiable, Hashable {
    let id: UUID
    let pairID: UUID
    let sourceURL: URL
    let destinationURL: URL

    init(id: UUID = UUID(), pairID: UUID, sourceURL: URL, destinationURL: URL) {
        self.id = id
        self.pairID = pairID
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
    }
}

struct RenamePlanner {
    func plan(for pairs: [MatchPair]) -> [PlannedRename] {
        var reserved = Set<String>()
        var plans: [PlannedRename] = []

        for pair in pairs {
            let imageTarget = uniqueTarget(for: pair.image.url, baseName: pair.proposedBaseName, reserved: &reserved)
            let videoTarget = uniqueTarget(for: pair.video.url, baseName: pair.proposedBaseName, reserved: &reserved)
            plans.append(PlannedRename(pairID: pair.id, sourceURL: pair.image.url, destinationURL: imageTarget))
            plans.append(PlannedRename(pairID: pair.id, sourceURL: pair.video.url, destinationURL: videoTarget))
        }

        return plans
    }

    private func uniqueTarget(for sourceURL: URL, baseName: String, reserved: inout Set<String>) -> URL {
        let folder = sourceURL.deletingLastPathComponent()
        let ext = sourceURL.pathExtension.lowercased()
        var candidateBase = baseName
        var index = 1

        while true {
            let candidate = folder.appendingPathComponent(candidateBase).appendingPathExtension(ext)
            let key = candidate.path
            let exists = FileManager.default.fileExists(atPath: candidate.path) && candidate.path != sourceURL.path
            if !exists && !reserved.contains(key) {
                reserved.insert(key)
                return candidate
            }
            index += 1
            candidateBase = "\(baseName)_\(String(format: "%02d", index))"
        }
    }
}
