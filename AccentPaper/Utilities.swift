import AppKit
import ColorThiefSwift
import Combine
import CoreGraphics

class AccentBackend: ObservableObject {
    @Published var activeScreen: AccentScreen = AccentScreen(
        inselected: true,
        inscreen: NSScreen.main
    )
    @Published var screens: [AccentScreen] = []
    var timer = Timer()
    var manually_set = false

    var desktop_uri: URL?
    var last_calculated_uri: URL?
    var is_image: Bool = true
    var wallpaper_plist: URL

    func collectScreens() {
        let raw_screens = NSScreen.screens
        screens = raw_screens.map {
            AccentScreen(inselected: $0.hash == activeScreen.id, inscreen: $0)
        }
    }

    func setActiveScreen() {
        if let currentScreen = NSScreen.main {
            if currentScreen != activeScreen.screen {
                activeScreen = AccentScreen(
                    inselected: true,
                    inscreen: currentScreen
                )
                let i = screens.firstIndex(where: { $0.id == activeScreen.id })
                screens[i!].selected = true
            }
        }
    }

    func setActiveScreenFromTag(_ t: Int?) {
        activeScreen =
            screens.first(where: { $0.id == t })
            ?? AccentScreen(inselected: true, inscreen: NSScreen.main)
        activeScreen.selected = true
    }

    func getWallpaper() {
        let decoder = PropertyListDecoder()

        guard let raw_data = try? Data(contentsOf: wallpaper_plist) else {
            is_image = false
            return
        }
        let plist_data = try! decoder.decode(
            WallpaperProperties.self,
            from: raw_data
        )

        let obj: Wallpaper.WallpaperConfig?

        if screens.count > 1 && plist_data.AllSpacesAndDisplays.Desktop == nil
            && !plist_data.Displays.isEmpty
        {
            guard
                let display = plist_data.Displays[activeScreen.d_id ?? ""]?
                    .Desktop
            else {
                is_image = false
                return
            }

            obj = display.Content.Choices.first

        } else {
            obj = plist_data.AllSpacesAndDisplays.Desktop?.Content.Choices.first
        }

        if let o = obj {
            if o.Files.first?.relative != nil {
                is_image = o.Provider == "com.apple.wallpaper.choice.image"
                desktop_uri = URL(string: o.Files.first?.relative ?? "")
                return
            }
        }
        is_image = false
    }

    func getProminentColorFromWallpaper() {
        if desktop_uri == nil || last_calculated_uri == desktop_uri {
            return
        }

        let uri: URL = desktop_uri!
        print(uri.absoluteString)

        guard let image_data = try? Data(contentsOf: uri),
            let image = NSImage(data: image_data)
        else {
            return
        }

        guard let colors = ColorThief.getColor(from: image) else {
            return
        }
        print(colors)
        //last_calculated_uri = desktop_uri
    }

    func setAccentColor(color: AccentColorTag) {
        AccentHelper.setUserAccentColorUser(color.rawValue, shouldRet: 1)
    }

    func startJob() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true,
            block: { [weak self] _ in
                self?.collectScreens()
                if self?.manually_set != nil && !(self!.manually_set) {
                    self?.setActiveScreen()
                }

                self?.getWallpaper()
                self?.getProminentColorFromWallpaper()
            }
        )
    }

    func stopJob() {
        timer.invalidate()
    }

    init() {
        wallpaper_plist = URL.applicationSupportDirectory.appending(
            path: "com.apple.wallpaper/Store/Index.plist"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startJob()
        }
    }
}

struct AccentScreen: Identifiable {
    var selected = false
    var selectable = true
    var screen: NSScreen?
    var id: Int?
    var d_id: String?

    init(inselected: Bool, inscreen: NSScreen?) {
        selected = inselected
        screen = inscreen
        id = inscreen?.hash
        if let num = inscreen?.deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? CGDirectDisplayID {
            guard
                let ref = CGDisplayCreateUUIDFromDisplayID(num)?
                    .takeRetainedValue()
            else {
                selectable = false
                return
            }

            d_id = CFUUIDCreateString(nil, ref) as String
        } else {
            selectable = false
        }
    }
}

func colorFromRgb(_ red: Int, _ green: Int, _ blue: Int, alpha: CGFloat = 1.0)
    -> NSColor
{
    return NSColor(
        red: CGFloat(red) / 255.0,
        green: CGFloat(green) / 255.0,
        blue: CGFloat(blue) / 255.0,
        alpha: alpha
    )
}
