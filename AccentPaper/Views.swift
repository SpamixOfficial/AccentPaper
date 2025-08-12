import SwiftUI

struct AppBar: View {
    @State private var syncAutomatically = true
    @State private var syncScreenAutomatically = true
    @State private var chosenScreenHash: Int? = 0
    @StateObject private var backend = AccentBackend()

    var body: some View {
        VStack {
            Toggle(isOn: $syncAutomatically) {
                Text("Sync to wallpaper automatically")
            }.toggleStyle(.automatic).onChange(
                of: syncAutomatically,
                {
                    backend.do_not_sync = syncAutomatically
                }
            )
            Toggle(isOn: $syncScreenAutomatically) {
                Text("Choose screen automatically")
            }.toggleStyle(.automatic)
                .onChange(
                    of: syncScreenAutomatically,
                    {
                        backend.manually_set = syncScreenAutomatically
                    }
                )
            Picker(selection: $chosenScreenHash, label: Text("Chosen Screen")) {
                ForEach(backend.screens) { screen in
                    Text(screen.screen?.localizedName ?? "Generic Display").tag(
                        screen.id
                    )
                }
            }.onChange(of: chosenScreenHash) {
                backend.setActiveScreenFromTag(chosenScreenHash)
            }.onReceive(backend.$activeScreen) { x in
                chosenScreenHash = x.id
            }.disabled(syncScreenAutomatically)
            Divider()
            Button("Sync now") {
                Task {
                    await backend.sync()
                }
            }.keyboardShortcut("S", modifiers: [.shift]).disabled(
                syncAutomatically
            )
            Button("Quit") {
                NSApp.terminate(nil)
            }.keyboardShortcut("Q", modifiers: [.command, .shift])
        }
    }
}

#Preview("StatusBar") {
    AppBar()
}
