import SwiftUI

/// Companion ambient lighting view ("Lumn").
/// Renders an immersive peripheral screen halo that pulses and shifts color dynamically with the music and beat.
public struct CompanionLumnView: View {
    @ObservedObject var lumnService = LumnCompanionService.shared
    @ObservedObject var beatEngine = BeatSyncEngine.shared
    public let theme: AppTheme
    
    public init(theme: AppTheme) {
        self.theme = theme
    }
    
    public var body: some View {
        if lumnService.isEnabled {
            GeometryReader { geometry in
                let glowColor = theme.isAutoSync ? lumnService.activeGlowColor : theme.highlightColor
                
                // Composite pulse: Word onset pulse combined with rhythmic beat pulse
                let rhythmicBounce = 1.0 + (beatEngine.beatPulse * 0.15 * CGFloat(lumnService.intensity))
                let totalPulse = lumnService.currentPulseScale * rhythmicBounce
                let baseOpacity = 0.22 * lumnService.intensity
                
                ZStack {
                    // Top edge glow
                    LinearGradient(
                        colors: [glowColor.opacity(baseOpacity * totalPulse), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 190)
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                    // Bottom edge glow
                    LinearGradient(
                        colors: [glowColor.opacity(baseOpacity * totalPulse), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 190)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    
                    // Left edge glow
                    LinearGradient(
                        colors: [glowColor.opacity(baseOpacity * 0.85 * totalPulse), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 150)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right edge glow
                    LinearGradient(
                        colors: [glowColor.opacity(baseOpacity * 0.85 * totalPulse), .clear],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                    .frame(width: 150)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
            }
        }
    }
}
