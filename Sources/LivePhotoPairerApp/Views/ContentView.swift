import SwiftUI
import LivePhotoPairerCore

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showApplyConfirmation = false
    @State private var showRollbackConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            controls
            summary
            results
            statusBar
        }
        .padding(20)
        .confirmationDialog(
            "Apply rename batch?",
            isPresented: $showApplyConfirmation,
            titleVisibility: .visible
        ) {
            Button("Apply Rename", role: .destructive) {
                viewModel.applyRename()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will rename \(viewModel.pairs.count * 2) files in place and write rollback data.")
        }
        .confirmationDialog(
            "Rollback last apply?",
            isPresented: $showRollbackConfirmation,
            titleVisibility: .visible
        ) {
            Button("Rollback", role: .destructive) {
                viewModel.rollbackLastApply()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will attempt to restore the last rename batch from the rollback file in the selected folder.")
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("Select Folder") { viewModel.chooseFolder() }
                .disabled(viewModel.isBusy)

            Text(viewModel.selectedFolder?.path ?? "No folder selected")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .textSelection(.enabled)

            Spacer()

            Toggle("Include low confidence", isOn: $viewModel.includeLowConfidence)
                .toggleStyle(.switch)
                .frame(width: 190)
                .disabled(viewModel.isBusy)

            Button(viewModel.isScanning ? "Scanning…" : "Scan") {
                Task { await viewModel.scan() }
            }
            .disabled(viewModel.selectedFolder == nil || viewModel.isBusy)

            Button("Apply Rename") { showApplyConfirmation = true }
                .disabled(!viewModel.canApplyRename)

            Button("Export Report") { viewModel.exportReport() }
                .disabled(!viewModel.canExportReport)

            Button("Rollback Last Apply") { showRollbackConfirmation = true }
                .disabled(!viewModel.canRollback)
        }
    }

    private var summary: some View {
        GroupBox("Summary") {
            let s = viewModel.scanResult?.summary
            HStack(spacing: 20) {
                stat("Files", s?.filesScanned ?? 0)
                stat("Images", s?.images ?? 0)
                stat("Videos", s?.videos ?? 0)
                stat("Pairs", s?.pairsMatched ?? 0)
                stat("Unmatched images", s?.unmatchedImages ?? 0)
                stat("Unmatched videos", s?.unmatchedVideos ?? 0)
                stat("Ambiguous", s?.ambiguous ?? 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var results: some View {
        if viewModel.isScanning && !viewModel.hasResults {
            ContentUnavailableView("Scanning…", systemImage: "magnifyingglass")
        } else if !viewModel.hasResults {
            ContentUnavailableView(
                "No Results Yet",
                systemImage: "photo.on.rectangle.angled",
                description: Text("Select a folder and run a scan to preview matches, unmatched files, and ambiguous candidates.")
            )
        } else {
            TabView {
                pairsTable
                    .tabItem { Text("Matched Pairs") }
                unmatchedView(title: "Unmatched Images", files: viewModel.unmatchedImages)
                    .tabItem { Text("Unmatched Images") }
                unmatchedView(title: "Unmatched Videos", files: viewModel.unmatchedVideos)
                    .tabItem { Text("Unmatched Videos") }
                ambiguousView
                    .tabItem { Text("Ambiguous") }
            }
        }
    }

    private var pairsTable: some View {
        Table(viewModel.pairs) {
            TableColumn("Image") { pair in
                Text(pair.image.url.lastPathComponent)
            }
            TableColumn("Video") { pair in
                Text(pair.video.url.lastPathComponent)
            }
            TableColumn("Confidence") { pair in
                Text(pair.confidence.rawValue.capitalized)
                    .fontWeight(.semibold)
                    .foregroundStyle(color(for: pair.confidence))
            }
            TableColumn("Reasons") { pair in
                Text(pair.reasons.joined(separator: ", "))
                    .lineLimit(2)
            }
            TableColumn("Proposed Basename") { pair in
                Text(pair.proposedBaseName)
                    .textSelection(.enabled)
            }
            TableColumn("Status") { pair in
                Text(pair.status.rawValue.capitalized)
            }
        }
    }

    @ViewBuilder
    private func unmatchedView(title: String, files: [MediaFile]) -> some View {
        if files.isEmpty {
            ContentUnavailableView(
                title,
                systemImage: "checkmark.circle",
                description: Text("No items in this category.")
            )
        } else {
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                List(files) { file in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.url.lastPathComponent)
                        Text(file.url.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var ambiguousView: some View {
        if viewModel.ambiguous.isEmpty {
            ContentUnavailableView(
                "Ambiguous",
                systemImage: "checkmark.circle",
                description: Text("No ambiguous candidates.")
            )
        } else {
            List(viewModel.ambiguous) { candidate in
                VStack(alignment: .leading, spacing: 6) {
                    Text(candidate.image.url.lastPathComponent)
                        .font(.headline)
                    Text("Reasons: \(candidate.reasons.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(candidate.candidates) { video in
                        Text("Candidate: \(video.url.lastPathComponent)")
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var statusBar: some View {
        HStack {
            if viewModel.isBusy {
                ProgressView()
                    .controlSize(.small)
            }
            Text(viewModel.statusMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func stat(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.title3)
                .bold()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func color(for confidence: MatchConfidence) -> Color {
        switch confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}
