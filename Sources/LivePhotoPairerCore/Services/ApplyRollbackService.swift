import Foundation

public struct ApplyRollbackService {
    public init() {}

    private struct StagedRename {
        let plan: PlannedRename
        let tempURL: URL
    }

    public func apply(scanResult: ScanResult, plans: [PlannedRename]) throws -> RollbackBatch {
        let tempSuffix = ".moved-aside"
        var staged: [StagedRename] = []
        var operations: [RenameOperation] = []

        do {
            for plan in plans {
                let tempURL = temporaryURL(for: plan.sourceURL, suffix: tempSuffix)
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.moveItem(at: plan.sourceURL, to: tempURL)
                staged.append(StagedRename(plan: plan, tempURL: tempURL))
            }

            for item in staged {
                try FileManager.default.moveItem(at: item.tempURL, to: item.plan.destinationURL)
                operations.append(RenameOperation(originalPath: item.plan.sourceURL.path, newPath: item.plan.destinationURL.path))
            }
        } catch {
            rollbackStagedMoves(staged)
            throw error
        }

        let batch = RollbackBatch(createdAt: Date(), rootFolder: scanResult.rootFolder.path, operations: operations)
        try write(batch: batch, in: scanResult.rootFolder)
        return batch
    }

    public func rollbackLastBatch(in folderURL: URL) throws -> Int {
        let rollbackURL = folderURL.appendingPathComponent(".live-photo-pairer-rollback.json")
        let data = try Data(contentsOf: rollbackURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let batch = try decoder.decode(RollbackBatch.self, from: data)
        var count = 0

        for op in batch.operations.reversed() {
            let newURL = URL(fileURLWithPath: op.newPath)
            let originalURL = URL(fileURLWithPath: op.originalPath)
            guard FileManager.default.fileExists(atPath: newURL.path) else { continue }
            guard !FileManager.default.fileExists(atPath: originalURL.path) else { continue }
            try FileManager.default.moveItem(at: newURL, to: originalURL)
            count += 1
        }

        return count
    }

    private func rollbackStagedMoves(_ staged: [StagedRename]) {
        for item in staged.reversed() {
            if FileManager.default.fileExists(atPath: item.tempURL.path) {
                try? FileManager.default.moveItem(at: item.tempURL, to: item.plan.sourceURL)
            }
        }
    }

    private func temporaryURL(for sourceURL: URL, suffix: String) -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let fileName = sourceURL.lastPathComponent
        var candidate = directory.appendingPathComponent(fileName + suffix)
        var index = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent(fileName + suffix + ".\(index)")
            index += 1
        }

        return candidate
    }

    private func write(batch: RollbackBatch, in folderURL: URL) throws {
        let rollbackURL = folderURL.appendingPathComponent(".live-photo-pairer-rollback.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(batch).write(to: rollbackURL)
    }
}
