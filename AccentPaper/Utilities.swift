import AppKit
import ColorThiefSwift
import Combine
import CoreGraphics
import ScreenCaptureKit

class AccentBackend: ObservableObject {
    // screens
    @Published var activeScreen: AccentScreen = AccentScreen(
        inselected: true,
        inscreen: NSScreen.main
    )
    @Published var screens: [AccentScreen] = []
    
    // safeguards and other stuff
    var setting_accent_color: Bool = false
    var timer = Timer()
    var manually_set = false

    // dynamic wallpaper specific stuff
    var provider: String?
    
    // static specific stuff
    var desktop_uri: URL?
    var last_calculated_uri: URL?
    var is_image: Bool = true
    
    // generic
    var wallpaper_plist: URL
    var color: NSColor?
    

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

        // if screens are over 1 we need to get the right screen, else just yolo it :3
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
            provider = o.Provider
            if o.Files.first?.relative != nil {
                is_image = provider == "com.apple.wallpaper.choice.image"
                desktop_uri = URL(string: o.Files.first?.relative ?? "")
                return
            }
        }
        is_image = false
    }

    func calculateAndSetAccentColor() async {
        setting_accent_color = true
        var result: Bool
        if is_image {
            result = getProminentColorFromWallpaper()
        } else {
            result = await getColorFromTray()
        }

        if color == nil || !result {
            return
        }

        guard let accentColor = getNearestColor(color!)
        else {
            last_calculated_uri = nil
            return
        }

        setAccentColor(color: accentColor)
        setting_accent_color = false
    }

    func getColorFromTray() async -> Bool {
        // if we can't find a provider the wallpaper service is probably experiencing huge issues and we should not try to proceed
        if provider == nil {
            return false
        }
        
        do {
            // Take 1x1 screenshot of (100,0)
            let sc = try await SCShareableContent.current
            guard
                let disp = sc.displays.first(where: {
                    $0.displayID == activeScreen.c_id
                })
            else {
                return false
            }

            let filter = SCContentFilter(
                display: disp,
                excludingApplications: [],
                exceptingWindows: []
            )
            let config = SCStreamConfiguration()
            config.width = disp.width
            config.height = disp.height
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            guard
                let crop: CGImage = image.cropping(
                    to: CGRect(x: 100, y: 0, width: 1, height: 1)
                )
            else {
                return false
            }

            // get data
            var data = [UInt8](repeating: 0, count: Int(4))  // rgba
            let context = CGContext(
                data: &data,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
            context?.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))

            
            // create rgb color
            color = NSColor(data[0], data[1], data[2])

            return true
        } catch {
            print("Screenshot or color extraction failed: \(error)")
        }
        return false
    }

    func getProminentColorFromWallpaper() -> Bool {
        if desktop_uri == nil || last_calculated_uri == desktop_uri {
            return false
        }

        let uri: URL = desktop_uri!

        guard let image_data = try? Data(contentsOf: uri),
            let image = NSImage(data: image_data)
        else {
            return false
        }

        guard let colors = ColorThief.getColor(from: image) else {
            return false
        }
        color = colors.makeNSColor()
        last_calculated_uri = desktop_uri
        return true
    }

    func setAccentColor(color: AccentColorTag) {
        AccentHelper.setUserAccentColorUser(color.rawValue, shouldRet: 1)
    }
    
    func sync() async {
        self.getWallpaper()
        await self.calculateAndSetAccentColor()
        self.setting_accent_color = false
    }

    func startJob() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true,
            block: { [weak self] _ in
                guard let self = self else { return }
                Task {
                    if self.setting_accent_color {
                        return
                    }
                    await MainActor.run {
                        self.collectScreens()
                        if !self.manually_set {
                            self.setActiveScreen()
                        }
                    }
                    
                    await self.sync()
                }
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
    var c_id: CGDirectDisplayID?

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
            c_id = num
        } else {
            selectable = false
        }
    }
}

extension NSColor {
    convenience init<T: BinaryInteger>(_ red: T, _ green: T, _ blue: T, alpha: CGFloat = 1.0)
    {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: alpha
        )
    }
    
    func toRgb() -> (Int,Int,Int) {
        return (self.redComponent.to8Bit(), self.greenComponent.to8Bit(), self.blueComponent.to8Bit())
    }
    
    func readmean(c2: NSColor) -> Double {
        let (r1,g1,b1) = self.toRgb()
        let (r2,g2,b2) = c2.toRgb()
        
        
        let mR = 0.5*Double(r1+r2)
        let deltaR = Double(r1-r2)
        let deltaG = Double(g1-g2)
        let deltaB = Double(b1-b2)
        
        let rVal = (2+mR/256)*pow(deltaR,2)
        let gVal = 4*pow(deltaG,2)
        let bVal = (2+(255-mR)/256)*pow(deltaB,2)
        
        return sqrt(rVal+gVal+bVal)
    }
}

extension CGFloat {
    func to8Bit() -> Int {
        return Int(floor(self*0xff))
    }
}

func getNearestColor(_ color: NSColor) -> AccentColorTag? {
    return AccentColors.min(by: { c1, c2 in
        return c1.colorComponent.readmean(c2: color) < c2.colorComponent.readmean(c2: color)
    })
}
