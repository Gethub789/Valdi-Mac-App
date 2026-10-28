import SwiftUI

/// Fisheye Visual Style: Combines the Metal convex glass lens shader with contextual
/// SF Symbols and emojis popping in dynamically beside matched lyric words.
public struct FisheyeVisualView: View {
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
            let baseRadius = min(geometry.size.width, geometry.size.height) * 0.44
            let dynamicRadius = baseRadius * (1.0 + (beatEngine.beatPulse * 0.05))
            
            ZStack {
                // Background radial glass tint
                RadialGradient(
                    gradient: Gradient(colors: [
                        theme.highlightColor.opacity(0.15 + Double(beatEngine.beatPulse * 0.08)),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 30,
                    endRadius: dynamicRadius * 1.3
                )
                
                // Convex Stack with Visual Badges
                convexVisualStack(center: focalCenter, radius: dynamicRadius)
                    // Real Metal Lens Distortion Shader
                    .distortionEffect(
                        ShaderLibrary.bundle(.module).fisheyeLensDistortion(
                            .float2(Float(focalCenter.x), Float(focalCenter.y)),
                            .float(Float(dynamicRadius)),
                            .float(1.9)
                        ),
                        maxSampleOffset: CGSize(width: 90, height: 90)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private func convexVisualStack(center: CGPoint, radius: CGFloat) -> some View {
        VStack(spacing: 32) {
            let lines = lyrics.lines
            let startIndex = max(0, activeLineIndex - 2)
            let endIndex = min(lines.count - 1, activeLineIndex + 2)
            
            if startIndex <= endIndex && !lines.isEmpty {
                ForEach(startIndex...endIndex, id: \.self) { idx in
                    let line = lines[idx]
                    let relativeOffset = idx - activeLineIndex
                    
                    fisheyeVisualLineRow(line: line, distanceStep: relativeOffset)
                }
            } else {
                Text("♪ Listening for music ♪")
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .foregroundStyle(theme.secondaryColor)
            }
        }
    }
    
    @ViewBuilder
    private func fisheyeVisualLineRow(line: LineLyric, distanceStep: Int) -> some View {
        let isFocalLine = (distanceStep == 0)
        let absStep = CGFloat(abs(distanceStep))
        let convexScale: CGFloat = isFocalLine ? 1.25 : max(0.55, 1.0 - (absStep * 0.22))
        let convexOpacity: Double = isFocalLine ? 1.0 : max(0.2, 0.7 - (Double(absStep) * 0.25))
        
        HStack(spacing: 16) {
            ForEach(line.words) { word in
                let isWordActive = word.isActive(at: positionMs)
                let isWordPast = word.isPast(at: positionMs)
                
                VStack(spacing: 4) {
                    // Floating SF Symbol / Emoji Badge (popping in when active or focal)
                    if let symbol = word.matchedSymbolName {
                        Image(systemName: symbol)
                            .font(.system(size: isFocalLine ? 22 : 16, weight: .bold))
                            .foregroundStyle(isWordActive ? theme.highlightColor : theme.secondaryColor.opacity(0.6))
                            .scaleEffect(isWordActive ? 1.35 : 0.85)
                            .shadow(color: isWordActive ? theme.highlightColor : .clear, radius: 10)
                            .opacity(isFocalLine ? 1.0 : 0.4)
                            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isWordActive)
                    } else {
                        // Invisible spacer for vertical optical balance
                        Color.clear.frame(height: isFocalLine ? 22 : 16)
                    }
                    
                    Text(word.text)
                        .font(.system(
                            size: isFocalLine ? 42 : 28,
                            weight: isWordActive ? .black : (isFocalLine ? .bold : .medium),
                            design: .rounded
                        ))
                        .foregroundStyle(
                            isWordActive ? theme.highlightColor :
                            (isWordPast ? theme.lyricColor : theme.lyricColor.opacity(0.4))
                        )
                        .scaleEffect(isWordActive ? 1.25 : 1.0)
                        .shadow(
                            color: isWordActive ? theme.highlightColor.opacity(0.9) : .clear,
                            radius: isWordActive ? 25 : 0
                        )
                }
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isWordActive)
            }
        }
        .scaleEffect(convexScale)
        .opacity(convexOpacity)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: activeLineIndex)
    }
}
