import SwiftUI

@main
struct ValdiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarDropdownView(
                currentStyle: $appDelegate.currentStyle,
                displayBehavior: $appDelegate.displayBehavior,
                theme: $appDelegate.theme,
                onToggleOverlay: {
                    OverlayWindowController.shared.toggleManualPreview(
                        style: appDelegate.currentStyle,
                        theme: appDelegate.theme
                    )
                },
                onQuit: {
                    NSApp.terminate(nil)
                }
            )
        } label: {
            Image(systemName: "waveform.and.mic")
        }
        .menuBarExtraStyle(.window)
    }
}
