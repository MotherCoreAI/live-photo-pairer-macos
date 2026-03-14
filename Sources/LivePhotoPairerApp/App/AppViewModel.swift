#if canImport(AppKit)
import AppKit
#endif
import Foundation
import SwiftUI
import LivePhotoPairerCore

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedFolder: URL?
    @Published var scanResult: ScanResult?
    @Published var includeLowConfidence = false
    @Published var isScanning = false
    @Published var statusMessage = "Select a folder to begin."

    private let scanner = FolderScanner()
    private let metadataExtractor = MetadataExtractor()
    private let renamePlanner = RenamePlanner()
    private let applyRollbackService = ApplyRollbackService()
    private let reportGenerator = ReportGenerator()

    var pairs: [MatchPair] { scanResult?.pairs ?? [] }
    var unmatchedImages: [MediaFile] { scanResult?.unmatchedImages ?? [] }
    var unmatchedVideos: [MediaFile] { scanResult?.unmatchedVideos ?? [] }
    var ambiguous: [AmbiguousCandidate] { scanResult?.ambiguous ?? [] }

    func chooseFolder() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        if panel.runModal() == .OK {
            selectedFolder = panel.url
            scanResult = nil
            statusMessage = "Folder selected: \(panel.url?.path ?? "")"
        }
        #endif
    }

    func scan() async {
        guard let selectedFolder else {
            statusMessage = "Select a folder first."
            return
        }

        isScanning = true
        defer { isScanning = false }

        do {
            let urls = try scanner.scan(folderURL: selectedFolder)
            let mediaFiles = urls.map { metadataExtractor.extract(from: $0) }
            let matcher = PairMatcher(includeLowConfidence: includeLowConfidence)
            scanResult = matcher.match(rootFolder: selectedFolder, mediaFiles: mediaFiles)
            if let summary = scanResult?.summary {
                statusMessage = "Scanned \(summary.filesScanned) files. Matched \(summary.pairsMatched) pairs."
            }
        } catch {
            statusMessage = "Scan failed: \(error.localizedDescription)"
        }
    }

    func applyRename() {
        guard let scanResult else {
            statusMessage = "Nothing to apply."
            return
        }

        do {
            let plans = renamePlanner.plan(for: scanResult.pairs)
            let batch = try applyRollbackService.apply(scanResult: scanResult, plans: plans)
            statusMessage = "Applied \(batch.operations.count) file renames."
            Task { await scan() }
        } catch {
            statusMessage = "Apply failed: \(error.localizedDescription)"
        }
    }

    func rollbackLastApply() {
        guard let selectedFolder else {
            statusMessage = "Select a folder first."
            return
        }

        do {
            let count = try applyRollbackService.rollbackLastBatch(in: selectedFolder)
            statusMessage = "Rolled back \(count) file renames."
            Task { await scan() }
        } catch {
            statusMessage = "Rollback failed: \(error.localizedDescription)"
        }
    }

    func exportReport() {
        guard let scanResult else {
            statusMessage = "Nothing to export."
            return
        }

        #if canImport(AppKit)
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "report.json"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try reportGenerator.write(scanResult: scanResult, to: url)
                statusMessage = "Report exported to \(url.path)."
            } catch {
                statusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
        #endif
    }
}
