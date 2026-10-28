import SwiftUI

@main
struct ValdiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarDropdownView(
                currentStyle: Binding(
                    get: { appDelegate.currentStyle },
                    set: { appDelegate.currentStyle = $0 }
                ),
                displayBehavior: Binding(
                    get: { appDelegate.displayBehavior },
                    set: { appDelegate.displayBehavior = $0 }
                ),
                theme: Binding(
                    get: { appDelegate.theme },
                    set: { appDelegate.theme = $0 }
                ),
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
