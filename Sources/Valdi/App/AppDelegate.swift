import AppKit
import Combine
import SwiftUI

/// Application delegate configuring menu bar accessory status and core state observation pipelines.
public final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var currentStyle: DisplayStyle = .visual
    @Published public var displayBehavior: DisplayBehavior = .lockScreenOnly
    @Published public var theme: AppTheme = AppTheme.loadFromUserDefaults()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce accessory policy (Menu Bar only, no Dock icon)
        NSApp.setActivationPolicy(.accessory)

        let lumn = LumnCompanionService.shared
        lumn.isEnabled = theme.lumnEnabled
        lumn.intensity = theme.lumnIntensity
        
        setupSyncObservers()
        
        #if DEBUG
        print("[Valdi] Valdi launched successfully in Menu Bar accessory mode")
        #endif
    }
    
    private func setupSyncObservers() {
        let music = MusicIntegrationService.shared
        let lock = LockScreenDetector.shared
        let lyrics = LyricsEngine.shared
        let lumn = LumnCompanionService.shared

        lumn.$isEnabled
            .sink { [weak self] isEnabled in
                self?.theme.lumnEnabled = isEnabled
            }
            .store(in: &cancellables)

        lumn.$intensity
            .sink { [weak self] intensity in
                self?.theme.lumnIntensity = intensity
            }
            .store(in: &cancellables)
        
        // 1. When track changes, fetch lyrics and update palette
        music.$currentTrack
            .compactMap { $0 }
            .removeDuplicates { $0.id == $1.id }
            .sink { [weak self] track in
                lyrics.fetchLyrics(for: track)
                
                if let self = self, self.theme.isAutoSync {
                    let palette = PaletteEngine.shared.extractPalette(from: track.artwork, trackId: track.id)
                    DispatchQueue.main.async {
                        self.theme.highlightColor = palette.highlight
                        self.theme.secondaryColor = palette.secondary
                        self.theme.backgroundColor = palette.backgroundTint
                    }
                }
            }
            .store(in: &cancellables)
        
        // 2. Coordinate overlay visibility based on state
        Publishers.CombineLatest4(
            $displayBehavior,
            lock.$isScreenLocked,
            music.$currentTrack,
            $currentStyle
        )
        .sink { [weak self] behavior, isLocked, track, style in
            guard let self = self else { return }
            let isPlaying = track?.isPlaying ?? false
            
            OverlayWindowController.shared.updateVisibility(
                behavior: behavior,
                isScreenLocked: isLocked,
                isPlaying: isPlaying,
                currentStyle: style,
                theme: self.theme
            )
        }
        .store(in: &cancellables)
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        SleepPreventionManager.shared.releaseDisplaySleepAssertion()
        OverlayWindowController.shared.hideOverlays()
        MusicIntegrationService.shared.stopAll()
        theme.saveToUserDefaults()
    }
}
