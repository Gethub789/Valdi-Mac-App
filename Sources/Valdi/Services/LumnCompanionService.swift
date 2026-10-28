import Foundation
import SwiftUI

/// Companion ambient lighting engine ("Lumn").
/// Synchronizes peripheral lighting and screen edge halos to lyric cadence,
/// beat pulses, and dynamic album art palettes.
public final class LumnCompanionService: ObservableObject {
    public static let shared = LumnCompanionService()
    
    @Published public var isEnabled: Bool = true
    @Published public var intensity: Double = 0.65 // 0.0 to 1.0
    @Published public private(set) var currentPulseScale: CGFloat = 1.0
    @Published public private(set) var activeGlowColor: Color = Color(red: 0.20, green: 0.90, blue: 0.85)
    
    private var lastWordId: UUID?
    
    public init() {}
    
    /// Triggered on every active word change to pulse ambient lighting.
    public func onWordChanged(word: WordLyric?, palette: ExtractedPalette) {
        guard isEnabled, let word = word else { return }
        
        if lastWordId != word.id {
            lastWordId = word.id
            activeGlowColor = palette.highlight
            
            // Inform BeatSyncEngine of vocal onset for tempo tracking
            BeatSyncEngine.shared.recordWordOnset(timeMs: word.startTimeMs)
            
            // Trigger a tactile light burst / pulse
            withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                self.currentPulseScale = 1.0 + CGFloat(0.32 * intensity)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.35)) {
                    self.currentPulseScale = 1.0
                }
            }
        }
    }
}
