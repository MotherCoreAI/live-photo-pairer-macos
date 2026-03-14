import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(ImageIO)
import ImageIO
#endif

public struct MetadataExtractor {
    public init() {}

    public func extract(from url: URL) async -> MediaFile {
        let ext = url.pathExtension.lowercased()
        let kind: MediaKind = ext == "mov" ? .video : .image

        let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey, .fileSizeKey])
        let fallbackDate = values?.creationDate ?? values?.contentModificationDate
        let fileSize = values?.fileSize.map(Int64.init)
        let stem = url.deletingPathExtension().lastPathComponent

        switch kind {
        case .image:
            let imageMetadata = extractImageMetadata(from: url)
            return MediaFile(
                url: url,
                kind: .image,
                createdAt: imageMetadata.createdAt ?? fallbackDate,
                contentIdentifier: imageMetadata.contentIdentifier,
                originalStem: stem,
                fileSize: fileSize,
                durationSeconds: nil,
                pixelWidth: imageMetadata.width,
                pixelHeight: imageMetadata.height
            )
        case .video:
            let videoMetadata = await extractVideoMetadata(from: url)
            return MediaFile(
                url: url,
                kind: .video,
                createdAt: videoMetadata.createdAt ?? fallbackDate,
                contentIdentifier: videoMetadata.contentIdentifier,
                originalStem: stem,
                fileSize: fileSize,
                durationSeconds: videoMetadata.durationSeconds,
                pixelWidth: videoMetadata.width,
                pixelHeight: videoMetadata.height
            )
        }
    }

    private func extractImageMetadata(from url: URL) -> (createdAt: Date?, contentIdentifier: String?, width: Int?, height: Int?) {
        #if canImport(ImageIO)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return (nil, nil, nil, nil)
        }

        let width = properties[kCGImagePropertyPixelWidth] as? Int
        let height = properties[kCGImagePropertyPixelHeight] as? Int

        var createdAt: Date?
        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
            createdAt = parseExifDate(dateString)
        }

        let makerApple = properties["{MakerApple}" as CFString] as? [String: Any]
        let contentIdentifier = makerApple?["17"] as? String
            ?? makerApple?["ContentIdentifier"] as? String

        return (createdAt, contentIdentifier, width, height)
        #else
        return (nil, nil, nil, nil)
        #endif
    }

    private func extractVideoMetadata(from url: URL) async -> (createdAt: Date?, contentIdentifier: String?, durationSeconds: Double?, width: Int?, height: Int?) {
        #if canImport(AVFoundation)
        let asset = AVURLAsset(url: url)

        let durationTime = try? await asset.load(.duration)
        let durationValue = durationTime.map { time in
            let seconds = CMTimeGetSeconds(time)
            return seconds.isFinite ? seconds : nil
        } ?? nil

        var createdAt: Date?
        var contentIdentifier: String?
        var width: Int?
        var height: Int?

        if let track = try? await asset.loadTracks(withMediaType: .video).first {
            let size = try? await track.load(.naturalSize)
            let transform = try? await track.load(.preferredTransform)
            if let size, let transform {
                let transformed = size.applying(transform)
                width = Int(abs(transformed.width))
                height = Int(abs(transformed.height))
            }
        }

        if let metadataItems = try? await asset.load(.commonMetadata) {
            for item in metadataItems {
                if createdAt == nil,
                   let key = item.commonKey?.rawValue.lowercased(),
                   key.contains("creation") || key.contains("date") {
                    let dateValue = try? await item.load(.dateValue)
                    let stringValue = try? await item.load(.stringValue)
                    createdAt = dateValue ?? parseLooseDate(stringValue ?? nil)
                }

                if contentIdentifier == nil {
                    if let key = item.key as? String,
                       key.lowercased().contains("content.identifier") || key.lowercased().contains("live-photo") {
                        let stringValue = try? await item.load(.stringValue)
                        contentIdentifier = stringValue ?? nil
                    } else if let identifier = item.identifier?.rawValue.lowercased(),
                              identifier.contains("content.identifier") || identifier.contains("live-photo") {
                        let stringValue = try? await item.load(.stringValue)
                        contentIdentifier = stringValue ?? nil
                    }
                }
            }
        }

        return (createdAt, contentIdentifier, durationValue, width, height)
        #else
        return (nil, nil, nil, nil)
        #endif
    }

    private func parseExifDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: value)
    }

    private func parseLooseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) { return date }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: value)
    }
}
