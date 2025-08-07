import AppKit
import Combine

enum AccentColorTag : Int64 {
    case Red = 0
    case Orange = 1
    case Yellow = 2
    case Green = 3
    case Blue = 4
    case Purple = 5
    case Pink = 6
    case Multicolor = 7
}

class AccentBackend: ObservableObject {
    private var activeScreen: AccentScreen = AccentScreen(inselected: true, inscreen: NSScreen.main)
    @Published var screens: [AccentScreen] = []
    var timer = Timer()
    var manually_set = false
    
    func collectScreens() {
        let raw_screens = NSScreen.screens
        screens = raw_screens.map { AccentScreen(inselected: $0.hash == activeScreen.id, inscreen: $0) }
        print("screens collected")
    }
    
    func setActiveScreen() {
        if let currentScreen = NSScreen.main {
            print("screen was valid")
            if currentScreen != activeScreen.screen {
                print("new screen - set!")
                activeScreen = AccentScreen(inselected: true, inscreen: currentScreen)
            }
        }
    }
    
    func setActiveScreenFromTag(_ t: Int?) {
        print("set!!")
        activeScreen = screens.first(where: { $0.id == t}) ?? AccentScreen(inselected: true, inscreen: NSScreen.main)
        activeScreen.selected = true
    }
    
    func setAccentColor(color: AccentColorTag) {
        AccentHelper.setUserAccentColorUser(color.rawValue, shouldRet: 1)
    }
    
    func startJob() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            print("job!!")
            self?.collectScreens()
            if (self?.manually_set != nil && !(self!.manually_set)) {
                self?.setActiveScreen()
            }
        })
    }
    
    func stopJob() {
        timer.invalidate()
    }
}

struct AccentScreen: Identifiable {
    var selected = false
    var screen: NSScreen?
    var id: Int?
    
    init(inselected: Bool, inscreen: NSScreen?) {
        selected = inselected
        screen = inscreen
        id = inscreen?.hash
    }
}
