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
