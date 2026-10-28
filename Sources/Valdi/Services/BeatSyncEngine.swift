import Combine
import Foundation
import SwiftUI

/// High-performance beat and rhythm tracking engine.
/// Computes musical tempo, beat phases, downbeats, and rhythmic pulses
/// to synchronize visual shaders, lighting halos, and kinetic typography.
public final class BeatSyncEngine: ObservableObject {
    public static let shared = BeatSyncEngine()
    
    @Published public private(set) var bpm: Double = 120.0
    @Published public private(set) var beatPulse: CGFloat = 0.0        // 0.0 to 1.0 impulse on every beat
    @Published public private(set) var downbeatPulse: CGFloat = 0.0    // 0.0 to 1.0 heavier impulse on measure start (1 of 4)
    @Published public private(set) var continuousPhase: Double = 0.0   // 0.0 to 1.0 ramp
    @Published public private(set) var currentBeatIndex: Int = 0
    
    private var beatTimer: AnyCancellable?
    private var lastBeatTimestamp: Double = 0.0
    private var detectedIntervals: [Double] = []
    
    public init() {
        startRhythmLoop()
    }
    
    deinit {
        beatTimer?.cancel()
    }
    
    /// Dynamic tempo estimation from lyric word onset timestamps.
    /// When words hit musical subdivisions, calculates inter-onset intervals (IOI) to lock to song tempo.
    public func recordWordOnset(timeMs: Double) {
        if lastBeatTimestamp > 0 {
            let delta = timeMs - lastBeatTimestamp
            // Filter realistic musical intervals (between 250ms [240 BPM] and 1200ms [50 BPM])
            if delta >= 250 && delta <= 1200 {
                detectedIntervals.append(delta)
                if detectedIntervals.count > 16 {
                    detectedIntervals.removeFirst()
                }
                
                // Calculate median interval to eliminate syncopated outliers
                let sorted = detectedIntervals.sorted()
                let medianInterval = sorted[sorted.count / 2]
                let estimatedBpm = 60000.0 / medianInterval
                
                // Smooth BPM convergence
                self.bpm = (self.bpm * 0.7) + (estimatedBpm * 0.3)
            }
        }
        lastBeatTimestamp = timeMs
    }
    
    public func setExplicitBpm(_ newBpm: Double) {
        guard newBpm >= 40 && newBpm <= 220 else { return }
        self.bpm = newBpm
    }
    
    /// Synchronizes current phase against audio playback position
    public func syncPlayback(positionMs: Double) {
        let beatDurationMs = 60000.0 / max(40.0, bpm)
        let totalBeats = positionMs / beatDurationMs
        let beatFraction = totalBeats.truncatingRemainder(dividingBy: 1.0)
        let beatInt = Int(totalBeats)
        
        self.continuousPhase = beatFraction
        self.currentBeatIndex = beatInt
        
        // Compute elastic decay pulse: sharp attack, smooth exponential decay
        let decay = exp(-beatFraction * 4.5)
        self.beatPulse = CGFloat(decay)
        
        let isDownbeat = (beatInt % 4 == 0)
        self.downbeatPulse = isDownbeat ? CGFloat(decay * 1.35) : CGFloat(decay * 0.4)
    }
    
    private func startRhythmLoop() {
        // High-precision 60fps animation driver
        beatTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let currentPos = MusicIntegrationService.shared.interpolatedPositionMs
                self.syncPlayback(positionMs: currentPos)
            }
    }
}
