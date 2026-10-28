import SwiftUI

/// The four distinct display styles for Valdi synced lyrics.
public enum DisplayStyle: String, CaseIterable, Identifiable, Codable {
    /// Words stack into a wall that drifts in three dimensions.
    case ship = "Ship"
    
    /// A convex stack rendered under a real Metal lens shader, where current word sits closest to the glass.
    case fisheye = "Fisheye"
    
    /// Combines the Metal lens shader with matched icons and symbols switched on.
    case fisheyeVisual = "Fisheye Visual"
    
    /// Matched SF Symbols and emojis pop in dynamically beside words.
    case visual = "Visual"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .ship:
            return "cube.transparent"
        case .fisheye:
            return "circle.circle"
        case .fisheyeVisual:
            return "sparkles.rectangle.stack"
        case .visual:
            return "sparkles"
        }
    }
    
    public var description: String {
        switch self {
        case .ship:
            return "3D drifting word wall with spatial depth and tilt"
        case .fisheye:
            return "Metal optical lens distortion magnifying active words"
        case .fisheyeVisual:
            return "Optical Metal lens paired with contextual icon tokens"
        case .visual:
            return "Dynamic SF Symbols and emojis mapped to lyrics"
        }
    }
    
    public var usesMetalShader: Bool {
        self == .fisheye || self == .fisheyeVisual
    }
    
    public var showsVisualTokens: Bool {
        self == .visual || self == .fisheyeVisual
    }
}
