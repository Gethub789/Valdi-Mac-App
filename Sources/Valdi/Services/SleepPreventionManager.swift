import Foundation
import IOKit.pwr_mgt

/// Manages macOS IOKit power assertions to prevent the display from sleeping or dimming
/// while lyrics are actively playing on the lock screen.
public final class SleepPreventionManager {
    public static let shared = SleepPreventionManager()
    
    private var assertionID: IOPMAssertionID = 0
    private var isPreventingSleep: Bool = false
    private let lock = NSLock()
    
    public init() {}
    
    deinit {
        releaseDisplaySleepAssertion()
    }
    
    /// Requests an IOKit power assertion to keep the display awake.
    public func ensureDisplayAwake(reason: String = "Valdi Synced Lyrics Playback") {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isPreventingSleep else { return }
        
        let assertionType = kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString
        let reasonForActivity = reason as CFString
        
        let success = IOPMAssertionCreateWithName(
            assertionType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonForActivity,
            &assertionID
        )
        
        if success == kIOReturnSuccess {
            isPreventingSleep = true
            #if DEBUG
            print("[Valdi] Acquired display sleep prevention assertion (ID: \(assertionID))")
            #endif
        } else {
            #if DEBUG
            print("[Valdi] Failed to acquire display sleep assertion: \(success)")
            #endif
        }
    }
    
    /// Releases the display sleep assertion when playback stops or overlay is hidden.
    public func releaseDisplaySleepAssertion() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isPreventingSleep else { return }
        
        let success = IOPMAssertionRelease(assertionID)
        if success == kIOReturnSuccess {
            isPreventingSleep = false
            assertionID = 0
            #if DEBUG
            print("[Valdi] Released display sleep prevention assertion")
            #endif
        }
    }
    
    /// Update sleep assertion state according to playback and lock conditions.
    public func updateAssertion(isPlaying: Bool, shouldDisplay: Bool) {
        if isPlaying && shouldDisplay {
            ensureDisplayAwake()
        } else {
            releaseDisplaySleepAssertion()
        }
    }
}
