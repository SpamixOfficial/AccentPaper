import AppKit

enum AccentColorTag : Int64 {
    case Red = 0
    case Orange = 1
    case Yellow = 2
    case Green = 3
    case Blue = 4
    case Purple = 5
    case Pink = 6
    case Multicolor = 7
    
    var colorComponent: NSColor {
        switch self {
        case .Red:
            return colorFromRgb(254, 82, 87)
        case .Orange:
            return colorFromRgb(247, 130, 27)
        case .Yellow:
            return colorFromRgb(255, 199, 0)
        case .Green:
            return colorFromRgb(97, 186, 70)
        case .Blue:
            return colorFromRgb(0, 122, 255)
        case .Purple:
            return colorFromRgb(165, 79, 167)
        case .Pink:
            return colorFromRgb(247, 79, 158)
        case .Multicolor:
            return colorFromRgb(0, 122, 255)
        }
    }
}

struct WallpaperProperties: Codable {
    var AllSpacesAndDisplays: WallpaperDeclaration
    var Displays: [String : WallpaperDeclaration]
}

struct WallpaperDeclaration : Codable {
    var Desktop: Wallpaper?
    var Idle: Wallpaper?
}

struct Wallpaper : Codable {
    struct WallpaperContent : Codable {
        var Choices: [WallpaperConfig]
    }
    
    struct WallpaperConfig : Codable {
        var Files: [WallpaperFile]
        var Provider: String
    }
    
    struct WallpaperFile : Codable {
        var relative: String
    }
    
    var Content: WallpaperContent
}
