import SwiftUI

@available(macOS 15.0, *)
@main struct AccentPaperApp: App {
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    var body: some Scene {
        MenuBarExtra("AccentPaperControls", systemImage: "rainbow") {
            AppBar()
        }
    }
}
