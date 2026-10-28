import Combine
import Foundation

/// Observes macOS system distributed notifications to determine when the screen is locked or unlocked.
public final class LockScreenDetector: ObservableObject {
    public static let shared = LockScreenDetector()
    
    @Published public private(set) var isScreenLocked: Bool = false
    
    private var observers: [NSObjectProtocol] = []
    
    public init() {
        checkCurrentLockState()
        registerObservers()
    }
    
    deinit {
        for observer in observers {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }
    
    /// Queries the Quartz session dictionary to inspect initial lock state.
    public func checkCurrentLockState() {
        if let sessionInfo = CGSessionCopyCurrentDictionary() as? [String: Any],
           let locked = sessionInfo["CGSSessionScreenIsLocked"] as? Bool {
            self.isScreenLocked = locked
        } else {
            self.isScreenLocked = false
        }
    }
    
    private func registerObservers() {
        let center = DistributedNotificationCenter.default()
        
        // Notification emitted when macOS enters lock screen
        let lockObs = center.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = true
            #if DEBUG
            print("[Valdi] Screen locked event received")
            #endif
        }
        observers.append(lockObs)
        
        // Notification emitted when user unlocks macOS
        let unlockObs = center.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = false
            #if DEBUG
            print("[Valdi] Screen unlocked event received")
            #endif
        }
        observers.append(unlockObs)
        
        // Also capture screensaver start / stop
        let saverStart = center.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstart"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = true
        }
        observers.append(saverStart)
        
        let saverStop = center.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstop"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkCurrentLockState()
        }
        observers.append(saverStop)
    }
}
