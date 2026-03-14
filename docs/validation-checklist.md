# macOS Validation Checklist

Run these on a macOS machine with Xcode installed.

## Build
1. Open the package in Xcode
2. Build the `LivePhotoPairerApp` target
3. Confirm no signing changes are needed for local run

## Smoke test
1. Launch app
2. Select a test folder with `.heic/.jpg/.jpeg/.mov`
3. Run scan
4. Confirm matched / unmatched / ambiguous tabs populate
5. Export report
6. Apply rename on disposable fixtures
7. Rollback last apply

## Metadata validation
Use at least these fixture categories:
- obvious shared-ID pair
- timestamp-only pair
- ambiguous candidates
- unmatched image
- unmatched MOV
- collision case
- already-normalized pair

## Fallback decision
If native metadata fails to surface Apple pairing identifiers reliably enough:
- add `exiftool` fallback for metadata extraction
- prefer native first, `exiftool` second
