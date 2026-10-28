import SwiftUI

/// Main container view hosted in the lock-screen overlay window.
/// Switches dynamically between the 4 display styles and coordinates color palettes.
public struct LyricsDisplayContainerView: View {
    @ObservedObject var musicService = MusicIntegrationService.shared
    @ObservedObject var lyricsEngine = LyricsEngine.shared
    @ObservedObject var lumnService = LumnCompanionService.shared
    
    public let style: DisplayStyle
    public let theme: AppTheme
    
    public init(style: DisplayStyle, theme: AppTheme) {
        self.style = style
        self.theme = theme
    }
    
    private var effectiveTheme: AppTheme {
        if theme.isAutoSync, let track = musicService.currentTrack {
            let palette = PaletteEngine.shared.extractPalette(from: track.artwork, trackId: track.id)
            var dynTheme = theme
            dynTheme.highlightColor = palette.highlight
            dynTheme.secondaryColor = palette.secondary
            dynTheme.backgroundColor = palette.backgroundTint
            return dynTheme
        }
        return theme
    }
    
    public var body: some View {
        ZStack {
            // Background Artwork Ambience
            backgroundArtworkLayer
            
            // Lumn Ambient Peripheral Glow
            CompanionLumnView(theme: effectiveTheme)
            
            VStack(spacing: 0) {
                // Top Track Info Header
                trackHeaderView
                    .padding(.top, 48)
                    .padding(.horizontal, 48)
                
                Spacer()
                
                // Centered Lyrics Render Area (Switched by Display Style)
                lyricsContentArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
                
                // Bottom Subtle Progress Bar
                bottomProgressView
                    .padding(.bottom, 48)
                    .padding(.horizontal, 80)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(effectiveTheme.backgroundColor)
        .ignoresSafeArea()
        .onChange(of: musicService.interpolatedPositionMs) { newPos in
            // Inform Lumn companion service on word transitions
            if let activeWord = lyricsEngine.currentLyrics.activeLine(at: newPos)?.activeWord(at: newPos) {
                let palette = PaletteEngine.shared.extractPalette(
                    from: musicService.currentTrack?.artwork,
                    trackId: musicService.currentTrack?.id ?? ""
                )
                lumnService.onWordChanged(word: activeWord, palette: palette)
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var backgroundArtworkLayer: some View {
        if let artwork = musicService.currentTrack?.artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 80)
                .opacity(0.28)
                .clipped()
        }
    }
    
    private var trackHeaderView: some View {
        HStack(spacing: 16) {
            if let artwork = musicService.currentTrack?.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.4), radius: 8, y: 4)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(musicService.currentTrack?.title ?? "No Playing Track")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(musicService.currentTrack?.artist ?? "Valdi Synced Lyrics")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(effectiveTheme.secondaryColor)
                        .lineLimit(1)
                    
                    if let album = musicService.currentTrack?.album, !album.isEmpty {
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundStyle(effectiveTheme.secondaryColor.opacity(0.6))
                        Text(album)
                            .font(.system(size: 13))
                            .foregroundStyle(effectiveTheme.secondaryColor.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Playing indicator
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .symbolEffect(.variableColor.iterative.reversing, isActive: musicService.currentTrack?.isPlaying == true)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(effectiveTheme.highlightColor)
                
                Text(style.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(effectiveTheme.highlightColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(effectiveTheme.highlightColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
    
    @ViewBuilder
    private var lyricsContentArea: some View {
        let lyrics = lyricsEngine.currentLyrics
        let pos = musicService.interpolatedPositionMs
        
        switch style {
        case .ship:
            ShipStyleView(lyrics: lyrics, positionMs: pos, theme: effectiveTheme)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        case .fisheye:
            FisheyeStyleView(lyrics: lyrics, positionMs: pos, theme: effectiveTheme)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        case .fisheyeVisual:
            FisheyeVisualView(lyrics: lyrics, positionMs: pos, theme: effectiveTheme)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        case .visual:
            VisualWordsView(lyrics: lyrics, positionMs: pos, theme: effectiveTheme)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
    
    private var bottomProgressView: some View {
        let total = max(1.0, musicService.currentTrack?.durationMs ?? 1.0)
        let current = min(total, max(0.0, musicService.interpolatedPositionMs))
        let progress = current / total
        
        return VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 3)
                    
                    Capsule()
                        .fill(effectiveTheme.highlightColor)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 3)
                        .shadow(color: effectiveTheme.highlightColor.opacity(0.8), radius: 6)
                }
            }
            .frame(height: 3)
            
            HStack {
                Text(musicService.currentTrack?.currentPositionFormatted ?? "0:00")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(effectiveTheme.secondaryColor)
                Spacer()
                Text(musicService.currentTrack?.durationFormatted ?? "0:00")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(effectiveTheme.secondaryColor)
            }
        }
    }
}
