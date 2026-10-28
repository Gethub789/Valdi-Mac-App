import SwiftUI

/// Elegant menu bar dropdown menu offering instant control over styles, colors, sync, and behavior.
public struct MenuBarDropdownView: View {
    @ObservedObject var musicService = MusicIntegrationService.shared
    @ObservedObject var lyricsEngine = LyricsEngine.shared
    @ObservedObject var lockDetector = LockScreenDetector.shared
    @ObservedObject var lumnService = LumnCompanionService.shared
    
    @Binding var currentStyle: DisplayStyle
    @Binding var displayBehavior: DisplayBehavior
    @Binding var theme: AppTheme
    
    var onToggleOverlay: () -> Void
    var onQuit: () -> Void
    
    public init(
        currentStyle: Binding<DisplayStyle>,
        displayBehavior: Binding<DisplayBehavior>,
        theme: Binding<AppTheme>,
        onToggleOverlay: @escaping () -> Void = {},
        onQuit: @escaping () -> Void = {}
    ) {
        self._currentStyle = currentStyle
        self._displayBehavior = displayBehavior
        self._theme = theme
        self.onToggleOverlay = onToggleOverlay
        self.onQuit = onQuit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header / App Branding
            headerSection
            
            Divider().opacity(0.3)
            
            // Current Track Status Bar
            currentTrackSection
            
            Divider().opacity(0.3)
            
            // 1. Display Style Picker
            stylePickerSection
            
            Divider().opacity(0.3)
            
            // 2. Customization & Palette Engine (Auto Sync + Color Wells)
            colorPaletteSection
            
            Divider().opacity(0.3)
            
            // 3. Display Behavior
            behaviorSection
            
            Divider().opacity(0.3)
            
            // 4. Companion Lighting Concept: Lumn
            lumnSection
            
            Divider().opacity(0.3)
            
            // Footer Controls (Interactive simulator, Quit)
            footerSection
        }
        .padding(16)
        .frame(width: 330)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.highlightColor)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Valdi")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text("Synced Lock Screen Lyrics")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Live Status Indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(musicService.currentTrack?.isPlaying == true ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(lockDetector.isScreenLocked ? "Locked" : "Desktop")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
    }
    
    private var currentTrackSection: some View {
        Group {
            if let track = musicService.currentTrack {
                HStack(spacing: 10) {
                    if let artwork = track.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 38, height: 38)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(radius: 2)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.highlightColor.opacity(0.2))
                                .frame(width: 38, height: 38)
                            Image(systemName: "music.note")
                                .foregroundStyle(theme.highlightColor)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Player badge
                    Text(track.playerType.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(track.playerType == .spotify ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .foregroundStyle(track.playerType == .spotify ? Color.green : Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            } else {
                HStack {
                    Image(systemName: "music.quarternote.3")
                        .foregroundStyle(.secondary)
                    Text("No music playing in Spotify or Music")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var stylePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DISPLAY STYLE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(DisplayStyle.allCases) { style in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            currentStyle = style
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: style.iconName)
                                .font(.system(size: 12))
                            Text(style.rawValue)
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .background(currentStyle == style ? theme.highlightColor.opacity(0.25) : Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(currentStyle == style ? theme.highlightColor : Color.clear, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var colorPaletteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("COLOR PALETTE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                
                Toggle("Auto Sync", isOn: $theme.isAutoSync)
                    .toggleStyle(.switch)
                    .labelsHidden()
                Text("Auto Sync")
                    .font(.system(size: 11, weight: .medium))
            }
            
            // 3 Color Wells
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    ColorPicker("", selection: $theme.lyricColor)
                        .labelsHidden()
                        .disabled(theme.isAutoSync)
                    Text("Lyric")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 4) {
                    ColorPicker("", selection: $theme.highlightColor)
                        .labelsHidden()
                        .disabled(theme.isAutoSync)
                    Text("Highlight")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 4) {
                    ColorPicker("", selection: $theme.secondaryColor)
                        .labelsHidden()
                        .disabled(theme.isAutoSync)
                    Text("Secondary")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if theme.isAutoSync {
                    Text("Extracted from album artwork")
                        .font(.system(size: 10))
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
    
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DISPLAY BEHAVIOR")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            
            Picker("", selection: $displayBehavior) {
                ForEach(DisplayBehavior.allCases) { behavior in
                    Label(behavior.rawValue, systemImage: behavior.iconName).tag(behavior)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var lumnSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "lightbulb.led.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(lumnService.isEnabled ? theme.highlightColor : .secondary)
                Text("LUMN COMPANION LIGHTING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Toggle("", isOn: $lumnService.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            if lumnService.isEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "sun.min")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Slider(value: $lumnService.intensity, in: 0.1...1.0)
                    Image(systemName: "sun.max")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var footerSection: some View {
        HStack {
            // Simulator Mode Quick Toggle
            Button {
                triggerSimulatorDemo()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle")
                    Text("Demo Track")
                }
                .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            
            Spacer()
            
            Button("Quit Valdi", role: .destructive) {
                onQuit()
            }
            .font(.system(size: 11))
            .buttonStyle(.borderless)
        }
    }
    
    private func triggerSimulatorDemo() {
        let demo = Track(
            id: "demo-blinding-lights",
            title: "Blinding Lights",
            artist: "The Weeknd",
            album: "After Hours",
            durationMs: 200000,
            currentPositionMs: 50000,
            playbackState: .playing,
            playerType: .spotify
        )
        musicService.enableSimulatorMode(demoTrack: demo)
        lyricsEngine.fetchLyrics(for: demo)
    }
}
