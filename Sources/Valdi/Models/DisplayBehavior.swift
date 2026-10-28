import Foundation

/// Controls when the Valdi lyric overlay is presented to the user.
public enum DisplayBehavior: String, CaseIterable, Identifiable, Codable {
    /// Overlay is shown exclusively when the macOS screen is locked.
    case lockScreenOnly = "Lock Screen Only"
    
    /// Overlay stays active on the desktop at all times (ambient wallpaper mode).
    case alwaysOn = "Always On"
    
    /// Overlay is shown only when the user is logged in and screen is unlocked.
    case unlockedOnly = "Unlocked Only"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .lockScreenOnly:
            return "lock.display"
        case .alwaysOn:
            return "display.2"
        case .unlockedOnly:
            return "lock.open.display"
        }
    }
    
    public var description: String {
        switch self {
        case .lockScreenOnly:
            return "Appears seamlessly as soon as macOS is locked"
        case .alwaysOn:
            return "Persists across both desktop and lock screen"
        case .unlockedOnly:
            return "Visible on desktop, dims during lock screen"
        }
    }
}
