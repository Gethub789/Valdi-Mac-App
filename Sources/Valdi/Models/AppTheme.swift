import SwiftUI

/// Central state representation of theme, colors, and visual styles.
public struct AppTheme: Equatable {
    public var lyricColor: Color
    public var highlightColor: Color
    public var secondaryColor: Color
    public var backgroundColor: Color
    public var isAutoSync: Bool
    public var lumnEnabled: Bool
    public var lumnIntensity: Double // 0.0 to 1.0
    
    public init(
        lyricColor: Color = Color(white: 0.85).opacity(0.8),
        highlightColor: Color = Color(red: 0.20, green: 0.90, blue: 0.85), // Vibrant electric cyan
        secondaryColor: Color = Color(white: 0.55),
        backgroundColor: Color = Color.black.opacity(0.85),
        isAutoSync: Bool = true,
        lumnEnabled: Bool = true,
        lumnIntensity: Double = 0.65
    ) {
        self.lyricColor = lyricColor
        self.highlightColor = highlightColor
        self.secondaryColor = secondaryColor
        self.backgroundColor = backgroundColor
        self.isAutoSync = isAutoSync
        self.lumnEnabled = lumnEnabled
        self.lumnIntensity = lumnIntensity
    }
    
    public static let `default` = AppTheme()
    
    // Convert to hex for persistence
    public func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(isAutoSync, forKey: "valdi_auto_sync")
        defaults.set(lumnEnabled, forKey: "valdi_lumn_enabled")
        defaults.set(lumnIntensity, forKey: "valdi_lumn_intensity")
        
        if let hex = lyricColor.toHex() { defaults.set(hex, forKey: "valdi_color_lyric") }
        if let hex = highlightColor.toHex() { defaults.set(hex, forKey: "valdi_color_highlight") }
        if let hex = secondaryColor.toHex() { defaults.set(hex, forKey: "valdi_color_secondary") }
    }
    
    public static func loadFromUserDefaults() -> AppTheme {
        let defaults = UserDefaults.standard
        var theme = AppTheme.default
        
        if defaults.object(forKey: "valdi_auto_sync") != nil {
            theme.isAutoSync = defaults.bool(forKey: "valdi_auto_sync")
        }
        if defaults.object(forKey: "valdi_lumn_enabled") != nil {
            theme.lumnEnabled = defaults.bool(forKey: "valdi_lumn_enabled")
        }
        if defaults.object(forKey: "valdi_lumn_intensity") != nil {
            theme.lumnIntensity = defaults.double(forKey: "valdi_lumn_intensity")
        }
        if let hex = defaults.string(forKey: "valdi_color_lyric"), let c = Color(hex: hex) {
            theme.lyricColor = c
        }
        if let hex = defaults.string(forKey: "valdi_color_highlight"), let c = Color(hex: hex) {
            theme.highlightColor = c
        }
        if let hex = defaults.string(forKey: "valdi_color_secondary"), let c = Color(hex: hex) {
            theme.secondaryColor = c
        }
        
        return theme
    }
}

// Color Hex Serialization extensions
extension Color {
    public init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.remove(at: cleanHex.startIndex)
        }
        
        guard cleanHex.count == 6 || cleanHex.count == 8 else { return nil }
        
        var rgbValue: UInt64 = 0
        guard Scanner(string: cleanHex).scanHexInt64(&rgbValue) else { return nil }
        
        let r, g, b, a: Double
        if cleanHex.count == 8 {
            r = Double((rgbValue & 0xFF000000) >> 24) / 255.0
            g = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = Double(rgbValue & 0x000000FF) / 255.0
        } else {
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
            a = 1.0
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    public func toHex() -> String? {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
