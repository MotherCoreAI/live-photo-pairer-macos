import SwiftUI

@main
struct LivePhotoPairerApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.titleBar)
    }
}
