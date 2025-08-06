import SwiftUI

@available(macOS 13.0, *)
@main struct AccentPaperApp: App {
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    var body: some Scene {
        MenuBarExtra("AccentPaperControls", systemImage: "rainbow") {
            AppBar()
        }
    }
}
