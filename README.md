# Live Photo Pairer for macOS

Recover and normalize iPhone Live Photo still/video pairs from messy exports.

## What it does

This macOS desktop utility scans a folder recursively for:
- `.heic`
- `.jpg`
- `.jpeg`
- `.mov`

It then detects likely still/video pairs, previews proposed renames, and safely renames matched pairs to a shared basename while preserving extensions.

Example:
- `IMG_E1234.HEIC`
- `IMG_9384.MOV`

becomes:
- `LP_2024-08-17_14-22-31_001.HEIC`
- `LP_2024-08-17_14-22-31_001.MOV`

## Important limitations

This tool is **best-effort only**.

- Some export workflows strip the metadata needed for reliable matching.
- Matching names alone may **not** restore Live Photo behavior in Apple Photos or other apps.
- Users should always preview matches before applying renames.
- The app will avoid silent overwrite and will generate rollback data for applied rename batches.

## Planned confidence levels

- **High**: shared content identifier / strong asset metadata match
- **Medium**: timestamp proximity plus supporting signals
- **Low**: weak heuristic guess

## Planned features

- Native macOS app built with Swift + SwiftUI
- Folder picker
- Recursive media scan
- Pair detection with confidence + reasons
- Preview table
- Safe rename apply flow
- Rollback last apply
- Export JSON report

## Supported file types

- Images: `.heic`, `.jpg`, `.jpeg`
- Videos: `.mov`

## Build / Run

Planned stack:
- Xcode 15+
- Swift 5.10+
- macOS 14+

Project scaffolding is being built.

## Development status

Initial repository scaffold only. App implementation to follow in small conventional commits.

## License

MIT
