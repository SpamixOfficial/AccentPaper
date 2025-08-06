import SwiftUI

struct AppBar: View {
    @State private var syncAutomatically = true
    
    var body: some View {
        Text("Options")
        Toggle(isOn: $syncAutomatically) {
            Text("Sync to wallpaper automatically")
        }.toggleStyle(.automatic)
        Divider()
        Button("Sync now") {
            setAccentColor()
        }.keyboardShortcut("S", modifiers: [.shift])
    }
}

#Preview("StatusBar") {
    AppBar()
}
