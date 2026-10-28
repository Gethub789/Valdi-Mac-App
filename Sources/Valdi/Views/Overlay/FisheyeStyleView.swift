import SwiftUI

/// Fisheye Style: A convex stack rendered under a real Metal lens shader,
/// where the current active word sits closest to the optical glass.
public struct FisheyeStyleView: View {
    public let lyrics: SyncedSongLyrics
    public let positionMs: Double
    public let theme: AppTheme
    
    @ObservedObject private var beatEngine = BeatSyncEngine.shared
    
    public init(lyrics: SyncedSongLyrics, positionMs: Double, theme: AppTheme) {
        self.lyrics = lyrics
        self.positionMs = positionMs
        self.theme = theme
    }
    
    private var activeLineIndex: Int {
        lyrics.activeLineIndex(at: positionMs) ?? 0
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let focalCenter = CGPoint(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0)
            let baseRadius = min(geometry.size.width, geometry.size.height) * 0.42
            let dynamicRadius = baseRadius * (1.0 + (beatEngine.beatPulse * 0.045))
            
            ZStack {
                // Background radial glass ambient glow
                RadialGradient(
                    gradient: Gradient(colors: [
                        theme.highlightColor.opacity(0.12 + Double(beatEngine.beatPulse * 0.08)),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 20,
                    endRadius: dynamicRadius * 1.2
                )
                
                // Convex Stack of Lyrics
                convexWordStack(center: focalCenter, radius: dynamicRadius)
                    // Real Metal Lens Distortion Shader Integration
                    .distortionEffect(
                        ShaderLibrary.bundle(.module).fisheyeLensDistortion(
                            .float2(Float(focalCenter.x), Float(focalCenter.y)),
                            .float(Float(dynamicRadius)),
                            .float(1.85) // Convex glass curvature strength
                        ),
                        maxSampleOffset: CGSize(width: 80, height: 80)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private func convexWordStack(center: CGPoint, radius: CGFloat) -> some View {
        VStack(spacing: 28) {
            let lines = lyrics.lines
            let startIndex = max(0, activeLineIndex - 2)
            let endIndex = min(lines.count - 1, activeLineIndex + 2)
            
            if startIndex <= endIndex && !lines.isEmpty {
                ForEach(startIndex...endIndex, id: \.self) { idx in
                    let line = lines[idx]
                    let relativeOffset = idx - activeLineIndex
                    
                    fisheyeLineRow(line: line, distanceStep: relativeOffset)
                }
            } else {
                Text("♪ Listening for music ♪")
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .foregroundStyle(theme.secondaryColor)
            }
        }
    }
    
    @ViewBuilder
    private func fisheyeLineRow(line: LineLyric, distanceStep: Int) -> some View {
        let isFocalLine = (distanceStep == 0)
        
        // Convex optical calculation: items further from center recede along spherical curvature
        let absStep = CGFloat(abs(distanceStep))
        let convexScale: CGFloat = isFocalLine ? 1.22 : max(0.55, 1.0 - (absStep * 0.22))
        let convexOpacity: Double = isFocalLine ? 1.0 : max(0.2, 0.7 - (Double(absStep) * 0.25))
        let convexCurveY: CGFloat = CGFloat(distanceStep * 6)
        
        HStack(spacing: 14) {
            ForEach(line.words) { word in
                let isWordActive = word.isActive(at: positionMs)
                let isWordPast = word.isPast(at: positionMs)
                
                Text(word.text)
                    .font(.system(
                        size: isFocalLine ? 42 : 30,
                        weight: isWordActive ? .black : (isFocalLine ? .bold : .medium),
                        design: .rounded
                    ))
                    .foregroundStyle(
                        isWordActive ? theme.highlightColor :
                        (isWordPast ? theme.lyricColor : theme.lyricColor.opacity(0.4))
                    )
                    // Active word sits closest to the glass: intense magnification & glass highlight
                    .scaleEffect(isWordActive ? 1.25 : 1.0)
                    .shadow(
                        color: isWordActive ? theme.highlightColor.opacity(0.9) : .clear,
                        radius: isWordActive ? 24 : 0
                    )
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isWordActive)
            }
        }
        .scaleEffect(convexScale)
        .opacity(convexOpacity)
        .offset(y: convexCurveY)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: activeLineIndex)
    }
}
