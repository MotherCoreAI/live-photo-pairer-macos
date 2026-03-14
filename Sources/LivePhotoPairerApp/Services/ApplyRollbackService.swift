import Foundation

struct ApplyRollbackService {
    func apply(scanResult: ScanResult, plans: [PlannedRename]) throws -> RollbackBatch {
        let tempSuffix = ".moved-aside"
        var staged: [(from: URL, temp: URL)] = []
        var operations: [RenameOperation] = []

        do {
            for plan in plans {
                let tempURL = plan.sourceURL.deletingLastPathComponent().appendingPathComponent(plan.sourceURL.lastPathComponent + tempSuffix)
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.moveItem(at: plan.sourceURL, to: tempURL)
                staged.append((from: plan.sourceURL, temp: tempURL))
            }

            for item in staged {
                guard let plan = plans.first(where: { $0.sourceURL.lastPathComponent + tempSuffix == item.temp.lastPathComponent }) else {
                    continue
                }
                try FileManager.default.moveItem(at: item.temp, to: plan.destinationURL)
                operations.append(RenameOperation(originalPath: plan.sourceURL.path, newPath: plan.destinationURL.path))
            }
        } catch {
            for item in staged.reversed() {
                if FileManager.default.fileExists(atPath: item.temp.path) {
                    try? FileManager.default.moveItem(at: item.temp, to: item.from)
                }
            }
            throw error
        }

        let batch = RollbackBatch(createdAt: Date(), rootFolder: scanResult.rootFolder.path, operations: operations)
        try write(batch: batch, in: scanResult.rootFolder)
        return batch
    }

    func rollbackLastBatch(in folderURL: URL) throws -> Int {
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
            try FileManager.default.moveItem(at: newURL, to: originalURL)
            count += 1
        }

        return count
    }

    private func write(batch: RollbackBatch, in folderURL: URL) throws {
        let rollbackURL = folderURL.appendingPathComponent(".live-photo-pairer-rollback.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(batch).write(to: rollbackURL)
    }
}
