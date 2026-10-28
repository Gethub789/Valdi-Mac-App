import AppKit
import SwiftUI

/// High-level transparent macOS overlay window tailored for display over the lock screen.
public final class LockScreenOverlayWindow: NSPanel {
    
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupWindowProperties()
    }
    
    private func setupWindowProperties() {
        // High floating window level to sit over lock screen UI
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        
        // Pass all clicks and keyboard events through to macOS lock screen (so user can type password)
        self.ignoresMouseEvents = true
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        
        // Display across all virtual spaces and full-screen apps
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        
        // Exclude from window list previews
        self.isExcludedFromWindowsMenu = true
    }
}

/// Controller managing the lifecycle and visibility of lock-screen overlay windows across all screens.
public final class OverlayWindowController: ObservableObject {
    public static let shared = OverlayWindowController()
    
    private var overlayWindows: [LockScreenOverlayWindow] = []
    private var isCurrentlyPresented: Bool = false
    
    public init() {}
    
    /// Updates overlay visibility according to playback state, lock status, and user behavior setting.
    public func updateVisibility(
        behavior: DisplayBehavior,
        isScreenLocked: Bool,
        isPlaying: Bool,
        currentStyle: DisplayStyle,
        theme: AppTheme
    ) {
        let shouldShow: Bool
        
        switch behavior {
        case .lockScreenOnly:
            shouldShow = isScreenLocked && isPlaying
        case .alwaysOn:
            shouldShow = isPlaying
        case .unlockedOnly:
            shouldShow = !isScreenLocked && isPlaying
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if shouldShow {
                self.showOverlays(style: currentStyle, theme: theme)
                SleepPreventionManager.shared.ensureDisplayAwake()
            } else {
                self.hideOverlays()
                SleepPreventionManager.shared.releaseDisplaySleepAssertion()
            }
        }
    }
    
    public func showOverlays(style: DisplayStyle, theme: AppTheme) {
        guard !isCurrentlyPresented else {
            // Update root view style & theme
            updateContent(style: style, theme: theme)
            return
        }
        
        hideOverlays()
        
        let screens = NSScreen.screens
        for screen in screens {
            let window = LockScreenOverlayWindow(contentRect: screen.frame)
            window.setFrame(screen.frame, display: true)
            
            let hosting = NSHostingView(
                rootView: LyricsDisplayContainerView(style: style, theme: theme)
            )
            hosting.frame = screen.frame
            window.contentView = hosting
            
            window.orderFrontRegardless()
            overlayWindows.append(window)
        }
        
        isCurrentlyPresented = true
    }
    
    public func hideOverlays() {
        guard isCurrentlyPresented else { return }
        
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        isCurrentlyPresented = false
    }
    
    public func updateContent(style: DisplayStyle, theme: AppTheme) {
        for window in overlayWindows {
            window.contentView = NSHostingView(
                rootView: LyricsDisplayContainerView(style: style, theme: theme)
            )
        }
    }
    
    public func toggleManualPreview(style: DisplayStyle, theme: AppTheme) {
        if isCurrentlyPresented {
            hideOverlays()
        } else {
            showOverlays(style: style, theme: theme)
        }
    }
}
