import Foundation

struct FolderScanner {
    private let supportedExtensions = Set(["heic", "jpg", "jpeg", "mov"])

    func scan(folderURL: URL) throws -> [URL] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isSymbolicLinkKey]
        let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        var urls: [URL] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            let values = try fileURL.resourceValues(forKeys: keys)
            guard values.isRegularFile == true else { continue }
            guard values.isSymbolicLink != true else { continue }

            let ext = fileURL.pathExtension.lowercased()
            if supportedExtensions.contains(ext) {
                urls.append(fileURL)
            }
        }

        return urls.sorted { $0.path < $1.path }
    }
}
