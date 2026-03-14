# Live Photo Pairer for macOS

Recover and normalize iPhone Live Photo still/video pairs from messy exports.

## What it does

Live Photo Pairer is a lightweight native macOS utility that:
- lets you choose a folder recursively containing exported iPhone media
- scans `.heic`, `.jpg`, `.jpeg`, and `.mov`
- detects likely Live Photo still/video pairs
- shows confidence, reasons, unmatched files, and ambiguous candidates
- previews the proposed shared basename before any rename happens
- safely renames matched pairs while preserving extensions
- writes rollback data so the last batch can be undone
- exports a JSON report

Example rename:
- `IMG_E1234.HEIC`
- `IMG_9384.MOV`

becomes:
- `LP_2024-08-17_14-22-31_001.heic`
- `LP_2024-08-17_14-22-31_001.mov`

## Important limitations

This tool is **best-effort only**.

- Some export workflows strip metadata needed for reliable matching.
- Matching names alone may **not** restore Live Photo behavior in Apple Photos or other downstream apps.
- Native metadata extraction may not expose every Apple-specific pairing field in every file.
- Users should always preview results before applying renames.

## Supported file types

- Images: `.heic`, `.jpg`, `.jpeg`
- Videos: `.mov`

## Confidence levels

- **High**
  - shared content identifier or equivalent strong pairing metadata
- **Medium**
  - timestamp proximity plus supporting signals such as filename similarity or plausible companion video duration
- **Low**
  - weak heuristic guess; intended for review, not blind apply

## Safety behavior

- Preview before apply
- No silent overwrite
- Collision-safe target naming with suffixes
- Rollback file written for applied rename batches
- Clear status reporting for failures

Rollback file location:
- `.live-photo-pairer-rollback.json` in the selected root folder

## Current implementation status

MVP desktop app structure is implemented with:
- folder picker
- recursive file discovery
- metadata extraction using native APIs
- confidence-based pairing
- preview UI for matched / unmatched / ambiguous results
- apply rename
- rollback last apply
- JSON report export

## Architecture

Main code layout:
- `Sources/LivePhotoPairerApp/App`
- `Sources/LivePhotoPairerApp/Views`
- `Sources/LivePhotoPairerApp/Domain`
- `Sources/LivePhotoPairerApp/Services`
- `Sources/LivePhotoPairerApp/Utilities`

Key services:
- `FolderScanner`
- `MetadataExtractor`
- `PairMatcher`
- `RenamePlanner`
- `ApplyRollbackService`
- `ReportGenerator`

## Build and run

Requirements:
- macOS 14+
- Xcode 15+
- Swift 5.10+

### Option 1: Open as Swift package in Xcode
1. Clone the repository
2. Open Xcode
3. Choose **Open Package...**
4. Select this repository folder
5. Build and run the `LivePhotoPairerApp` target

### Option 2: Command line build on macOS
```bash
swift build
```

Note: this project targets macOS and uses SwiftUI/AppKit APIs. Full app execution requires macOS.

## Usage

1. Launch the app
2. Click **Select Folder**
3. Choose the root folder containing exported media
4. Optionally enable **Include low confidence**
5. Click **Scan**
6. Review:
   - matched pairs
   - confidence
   - reasons
   - proposed basename
   - unmatched images
   - unmatched videos
   - ambiguous candidates
7. Click **Apply Rename** to perform the rename batch
8. Click **Rollback Last Apply** if needed
9. Click **Export Report** to save a JSON report

## Report output

The app exports a JSON report describing:
- scan timestamp
- root folder
- summary counts
- matched pairs
- unmatched images/videos
- ambiguous candidates

## Screenshots

Not yet included. Add after first macOS build verification.

## Future fallback if needed

If native metadata extraction proves insufficient for real-world files, the intended fallback is `exiftool` for deeper Apple/QuickTime metadata inspection.

## License

MIT
