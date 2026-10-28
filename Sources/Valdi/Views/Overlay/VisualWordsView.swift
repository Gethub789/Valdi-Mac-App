import SwiftUI

/// Visual Style: Matched SF Symbols and emojis pop in dynamically beside words as they are sung.
/// Powered by the rich ~770 token dictionary with progressive syllable highlight fills.
public struct VisualWordsView: View {
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
        VStack(spacing: 32) {
            let lines = lyrics.lines
            let startIndex = max(0, activeLineIndex - 1)
            let endIndex = min(lines.count - 1, activeLineIndex + 2)
            
            if startIndex <= endIndex && !lines.isEmpty {
                ForEach(startIndex...endIndex, id: \.self) { idx in
                    let line = lines[idx]
                    let isCurrentLine = (idx == activeLineIndex)
                    
                    visualLineRow(line: line, isCurrentLine: isCurrentLine)
                }
            } else {
                Text("♪ Listening for music ♪")
                    .font(.system(size: 36, weight: .light, design: .rounded))
                    .foregroundStyle(theme.secondaryColor)
            }
        }
        .padding(.horizontal, 40)
        .scaleEffect(1.0 + (beatEngine.beatPulse * 0.025)) // Subtle energetic beat bounce
    }
    
    @ViewBuilder
    private func visualLineRow(line: LineLyric, isCurrentLine: Bool) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ForEach(line.words) { word in
                let isWordActive = word.isActive(at: positionMs)
                let isWordPast = word.isPast(at: positionMs)
                
                HStack(spacing: 6) {
                    // Matched SF Symbol / Emoji badge popping in beside the word
                    if let symbol = word.matchedSymbolName {
                        HStack(spacing: 3) {
                            Image(systemName: symbol)
                                .font(.system(size: isCurrentLine ? 20 : 14, weight: .bold))
                            if isWordActive, let emoji = word.matchedEmoji {
                                Text(emoji)
                                    .font(.system(size: 16))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .foregroundStyle(isWordActive ? theme.highlightColor : theme.secondaryColor.opacity(0.7))
                        .scaleEffect(isWordActive ? 1.3 : 1.0)
                        .shadow(color: isWordActive ? theme.highlightColor.opacity(0.8) : .clear, radius: 10)
                        .animation(.spring(response: 0.22, dampingFraction: 0.6), value: isWordActive)
                    }
                    
                    // Word text with progressive syllable fill
                    Text(word.text)
                        .font(.system(
                            size: isCurrentLine ? 44 : 32,
                            weight: isWordActive ? .heavy : (isCurrentLine ? .bold : .medium),
                            design: .rounded
                        ))
                        .foregroundStyle(
                            isWordActive ? theme.highlightColor :
                            (isWordPast ? theme.lyricColor : theme.lyricColor.opacity(0.35))
                        )
                        .scaleEffect(isWordActive ? 1.15 : 1.0)
                        .shadow(
                            color: isWordActive ? theme.highlightColor.opacity(0.8) : .clear,
                            radius: isWordActive ? 20 : 0
                        )
                        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isWordActive)
                }
            }
        }
        .scaleEffect(isCurrentLine ? 1.05 : 0.92)
        .opacity(isCurrentLine ? 1.0 : 0.45)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: activeLineIndex)
    }
}
