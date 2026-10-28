import SwiftUI
import QuartzCore

/// Ship Style: Synced words stack into a dynamic wall that drifts through 3D space.
/// Features spatial depth perspective, z-axis progression, and starfield drift.
public struct ShipStyleView: View {
    public let lyrics: SyncedSongLyrics
    public let positionMs: Double
    public let theme: AppTheme
    
    @ObservedObject private var beatEngine = BeatSyncEngine.shared
    @State private var driftPhase: Double = 0.0
    
    public init(lyrics: SyncedSongLyrics, positionMs: Double, theme: AppTheme) {
        self.lyrics = lyrics
        self.positionMs = positionMs
        self.theme = theme
    }
    
    private var activeLineIndex: Int {
        lyrics.activeLineIndex(at: positionMs) ?? 0
    }
    
    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let driftAngleX = sin(elapsed * 0.4) * 8.0 // gentle pitch
            let driftAngleY = cos(elapsed * 0.3) * 12.0 // gentle yaw
            let driftOffsetY = sin(elapsed * 0.6) * 10.0
            
            ZStack {
                // Background cosmic particle grid
                starfieldDrift(elapsed: elapsed)
                
                // 3D Drifting Wall of Words
                VStack(spacing: 24) {
                    let lines = lyrics.lines
                    let startIndex = max(0, activeLineIndex - 2)
                    let endIndex = min(lines.count - 1, activeLineIndex + 3)
                    
                    if startIndex <= endIndex && !lines.isEmpty {
                        ForEach(startIndex...endIndex, id: \.self) { idx in
                            let line = lines[idx]
                            let relativeStep = idx - activeLineIndex
                            
                            shipLineRow(line: line, relativeStep: relativeStep)
                        }
                    } else {
                        Text("♪ Waiting for track sync ♪")
                            .font(.system(size: 28, weight: .light, design: .rounded))
                            .foregroundStyle(theme.secondaryColor)
                    }
                }
                .offset(y: driftOffsetY)
                .scaleEffect(1.0 + (beatEngine.beatPulse * 0.035)) // Tactile beat bounce
                // 3D Spatial Projection
                .rotation3DEffect(.degrees(driftAngleX), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
                .rotation3DEffect(.degrees(driftAngleY), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            }
        }
    }
    
    @ViewBuilder
    private func shipLineRow(line: LineLyric, relativeStep: Int) -> some View {
        let isActiveLine = (relativeStep == 0)
        let scale: CGFloat = isActiveLine ? 1.08 : max(0.65, 1.0 - CGFloat(abs(relativeStep)) * 0.14)
        let opacity: Double = isActiveLine ? 1.0 : max(0.2, 0.7 - Double(abs(relativeStep)) * 0.22)
        
        HStack(spacing: 12) {
            ForEach(line.words) { word in
                let isWordActive = word.isActive(at: positionMs)
                let isWordPast = word.isPast(at: positionMs)
                
                Text(word.text)
                    .font(.system(
                        size: isActiveLine ? 36 : 28,
                        weight: isWordActive ? .heavy : (isActiveLine ? .bold : .medium),
                        design: .rounded
                    ))
                    .foregroundStyle(
                        isWordActive ? theme.highlightColor :
                        (isWordPast ? theme.lyricColor : theme.lyricColor.opacity(0.45))
                    )
                    .shadow(
                        color: isWordActive ? theme.highlightColor.opacity(0.85) : .clear,
                        radius: isWordActive ? 18 : 0
                    )
                    .scaleEffect(isWordActive ? 1.18 : 1.0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isWordActive)
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: activeLineIndex)
    }
    
    private func starfieldDrift(elapsed: TimeInterval) -> some View {
        GeometryReader { proxy in
            Canvas { context, size in
                for i in 0..<35 {
                    let seed = Double(i)
                    let speed = 15.0 + (seed.truncatingRemainder(dividingBy: 20))
                    let x = (seed * 87.0 + elapsed * speed).truncatingRemainder(dividingBy: size.width)
                    let y = (seed * 143.0 + sin(elapsed * 0.2 + seed) * 30.0).truncatingRemainder(dividingBy: size.height)
                    let radius = 1.0 + (seed.truncatingRemainder(dividingBy: 2.5))
                    let alpha = 0.15 + (sin(elapsed + seed) * 0.1 + 0.1)
                    
                    let rect = CGRect(x: x, y: y, width: radius, height: radius)
                    context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
