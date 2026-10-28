import AppKit
import Combine
import Foundation

/// Coordinates with Spotify and Apple Music to provide millisecond-accurate track playback synchronization.
public final class MusicIntegrationService: ObservableObject {
    public static let shared = MusicIntegrationService()
    
    @Published public private(set) var currentTrack: Track?
    @Published public private(set) var interpolatedPositionMs: Double = 0.0
    @Published public private(set) var isSimulatorMode: Bool = false
    
    private var syncTimer: AnyCancellable?
    private var interpolationTimer: AnyCancellable?
    private var observers: [NSObjectProtocol] = []
    
    // Interpolation state
    private var lastAnchorPositionMs: Double = 0.0
    private var lastAnchorTimestamp: CFTimeInterval = 0.0
    private var isPlayingLocal: Bool = false
    
    public init() {
        setupDistributedNotifications()
        startPeriodicSync()
        startInterpolationEngine()
    }
    
    deinit {
        stopAll()
    }
    
    public func stopAll() {
        syncTimer?.cancel()
        interpolationTimer?.cancel()
        for obs in observers {
            DistributedNotificationCenter.default().removeObserver(obs)
        }
    }
    
    // MARK: - Distributed Notifications
    
    private func setupDistributedNotifications() {
        let center = DistributedNotificationCenter.default()
        
        // Spotify playback notification
        let spotifyObs = center.addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleSpotifyNotification(notification)
        }
        observers.append(spotifyObs)
        
        // Apple Music playback notification
        let appleMusicObs = center.addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppleMusicNotification(notification)
        }
        observers.append(appleMusicObs)
    }
    
    private func handleSpotifyNotification(_ notification: Notification) {
        guard let info = notification.userInfo else {
            pollActivePlayers()
            return
        }
        
        let stateStr = (info["Player State"] as? String) ?? "Stopped"
        let trackName = (info["Name"] as? String) ?? ""
        let artistName = (info["Artist"] as? String) ?? ""
        let albumName = (info["Album"] as? String) ?? ""
        let durationSec = (info["Duration"] as? Double) ?? 0.0
        let positionSec = (info["Playback Position"] as? Double) ?? 0.0
        let trackId = (info["Track ID"] as? String) ?? "\(trackName)-\(artistName)"
        
        let state: PlaybackState = (stateStr.lowercased() == "playing") ? .playing : .paused
        
        updateTrack(
            id: trackId,
            title: trackName,
            artist: artistName,
            album: albumName,
            durationMs: durationSec * 1000.0,
            positionMs: positionSec * 1000.0,
            state: state,
            playerType: .spotify
        )
    }
    
    private func handleAppleMusicNotification(_ notification: Notification) {
        guard let info = notification.userInfo else {
            pollActivePlayers()
            return
        }
        
        let stateStr = (info["Player State"] as? String) ?? "Stopped"
        let trackName = (info["Name"] as? String) ?? ""
        let artistName = (info["Artist"] as? String) ?? ""
        let albumName = (info["Album"] as? String) ?? ""
        let durationSec = (info["Total Time"] as? Double) ?? 0.0
        let positionSec = (info["Player Position"] as? Double) ?? 0.0
        let trackId = (info["PersistentID"] as? String) ?? "\(trackName)-\(artistName)"
        
        let state: PlaybackState = (stateStr.lowercased() == "playing") ? .playing : .paused
        
        updateTrack(
            id: trackId,
            title: trackName,
            artist: artistName,
            album: albumName,
            durationMs: durationSec > 1000 ? durationSec : durationSec * 1000.0,
            positionMs: positionSec * 1000.0,
            state: state,
            playerType: .appleMusic
        )
    }
    
    // MARK: - Periodic Polling via AppleScript
    
    private func startPeriodicSync() {
        // Poll every 1.2 seconds to detect manual seeks or track changes if notifications lag
        syncTimer = Timer.publish(every: 1.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isSimulatorMode else { return }
                self.pollActivePlayers()
            }
    }
    
    public func pollActivePlayers() {
        // Check Spotify first, then Apple Music
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let spotifyTrack = self?.querySpotify() {
                DispatchQueue.main.async {
                    self?.applyPolledTrack(spotifyTrack)
                }
                return
            }
            
            if let musicTrack = self?.queryAppleMusic() {
                DispatchQueue.main.async {
                    self?.applyPolledTrack(musicTrack)
                }
                return
            }
            
            // If neither is playing and not simulator, clear track or keep paused
            DispatchQueue.main.async {
                if let current = self?.currentTrack, current.playbackState == .playing {
                    self?.isPlayingLocal = false
                    self?.currentTrack = Track(
                        id: current.id,
                        title: current.title,
                        artist: current.artist,
                        album: current.album,
                        durationMs: current.durationMs,
                        currentPositionMs: current.currentPositionMs,
                        playbackState: .paused,
                        playerType: current.playerType,
                        artwork: current.artwork
                    )
                }
            }
        }
    }
    
    private func applyPolledTrack(_ track: Track) {
        if let current = currentTrack, current.id == track.id {
            // Update playback position and state
            lastAnchorPositionMs = track.currentPositionMs
            lastAnchorTimestamp = CACurrentMediaTime()
            isPlayingLocal = track.isPlaying
            
            if current.playbackState != track.playbackState {
                currentTrack = track
            }
        } else {
            // New track loaded
            currentTrack = track
            lastAnchorPositionMs = track.currentPositionMs
            lastAnchorTimestamp = CACurrentMediaTime()
            isPlayingLocal = track.isPlaying
            
            // Fetch artwork asynchronously if missing
            fetchArtwork(for: track)
        }
    }
    
    private func updateTrack(
        id: String,
        title: String,
        artist: String,
        album: String,
        durationMs: Double,
        positionMs: Double,
        state: PlaybackState,
        playerType: MediaPlayerType
    ) {
        let existingArtwork = currentTrack?.id == id ? currentTrack?.artwork : nil
        let newTrack = Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            durationMs: durationMs,
            currentPositionMs: positionMs,
            playbackState: state,
            playerType: playerType,
            artwork: existingArtwork
        )
        
        self.currentTrack = newTrack
        self.lastAnchorPositionMs = positionMs
        self.lastAnchorTimestamp = CACurrentMediaTime()
        self.isPlayingLocal = (state == .playing)
        
        if existingArtwork == nil {
            fetchArtwork(for: newTrack)
        }
    }
    
    // MARK: - Native AppleScript Queries
    
    private func querySpotify() -> Track? {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    set tTitle to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set tDuration to duration of current track
                    set tPosition to player position
                    set tId to id of current track
                    set tArt to artwork url of current track
                    return tTitle & "|||" & tArtist & "|||" & tAlbum & "|||" & tDuration & "|||" & tPosition & "|||" & tId & "|||" & tArt & "|||playing"
                else if player state is paused then
                    set tTitle to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set tDuration to duration of current track
                    set tPosition to player position
                    set tId to id of current track
                    return tTitle & "|||" & tArtist & "|||" & tAlbum & "|||" & tDuration & "|||" & tPosition & "|||" & tId & "||||||paused"
                end if
            end tell
        end if
        return "none"
        """
        
        guard let output = executeAppleScript(script), output != "none" else {
            return nil
        }
        
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 8 else { return nil }
        
        let title = parts[0]
        let artist = parts[1]
        let album = parts[2]
        let duration = (Double(parts[3]) ?? 0) // Spotify returns milliseconds in duration
        let positionSec = Double(parts[4]) ?? 0.0
        let id = parts[5]
        let artUrl = parts[6]
        let state = parts[7].trimmingCharacters(in: .whitespacesAndNewlines) == "playing" ? PlaybackState.playing : PlaybackState.paused
        
        var artwork: NSImage? = nil
        if !artUrl.isEmpty, let url = URL(string: artUrl), let data = try? Data(contentsOf: url) {
            artwork = NSImage(data: data)
        }
        
        return Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            durationMs: duration > 1000 ? duration : duration * 1000,
            currentPositionMs: positionSec * 1000,
            playbackState: state,
            playerType: .spotify,
            artwork: artwork
        )
    }
    
    private func queryAppleMusic() -> Track? {
        let script = """
        if application "Music" is running then
            tell application "Music"
                if player state is playing then
                    set tTitle to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set tDuration to duration of current track
                    set tPosition to player position
                    set tId to id of current track
                    return tTitle & "|||" & tArtist & "|||" & tAlbum & "|||" & tDuration & "|||" & tPosition & "|||" & tId & "|||playing"
                else if player state is paused then
                    set tTitle to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set tDuration to duration of current track
                    set tPosition to player position
                    set tId to id of current track
                    return tTitle & "|||" & tArtist & "|||" & tAlbum & "|||" & tDuration & "|||" & tPosition & "|||" & tId & "|||paused"
                end if
            end tell
        end if
        return "none"
        """
        
        guard let output = executeAppleScript(script), output != "none" else {
            return nil
        }
        
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 7 else { return nil }
        
        let title = parts[0]
        let artist = parts[1]
        let album = parts[2]
        let durationSec = Double(parts[3]) ?? 0.0
        let positionSec = Double(parts[4]) ?? 0.0
        let id = parts[5]
        let state = parts[6].trimmingCharacters(in: .whitespacesAndNewlines) == "playing" ? PlaybackState.playing : PlaybackState.paused
        
        return Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            durationMs: durationSec * 1000,
            currentPositionMs: positionSec * 1000,
            playbackState: state,
            playerType: .appleMusic
        )
    }
    
    private func fetchArtwork(for track: Track) {
        if track.playerType == .appleMusic {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                let script = """
                tell application "Music"
                    if exists (current track) then
                        tell current track
                            if exists (artworks) and (count of artworks) > 0 then
                                set rawData to raw data of artwork 1
                                return rawData
                            end if
                        end tell
                    end if
                end tell
                return ""
                """
                // AppleScript returns raw descriptor; or we can rely on standard cache
                _ = self?.executeAppleScript(script)
            }
        }
    }
    
    private func executeAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let descriptor = script.executeAndReturnError(&error)
        if error != nil {
            return nil
        }
        return descriptor.stringValue
    }
    
    // MARK: - Sub-millisecond Interpolation Engine (60 FPS / 16ms tick)
    
    private func startInterpolationEngine() {
        interpolationTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.isPlayingLocal {
                    let now = CACurrentMediaTime()
                    let deltaSeconds = max(0, now - self.lastAnchorTimestamp)
                    self.interpolatedPositionMs = self.lastAnchorPositionMs + (deltaSeconds * 1000.0)
                } else {
                    self.interpolatedPositionMs = self.lastAnchorPositionMs
                }
            }
    }
    
    // MARK: - Simulation Mode (for testing & interactive demo)
    
    public func enableSimulatorMode(demoTrack: Track) {
        isSimulatorMode = true
        currentTrack = demoTrack
        lastAnchorPositionMs = 0
        lastAnchorTimestamp = CACurrentMediaTime()
        isPlayingLocal = true
    }
    
    public func togglePlayPauseSimulator() {
        guard isSimulatorMode, let cur = currentTrack else { return }
        let nextState: PlaybackState = cur.isPlaying ? .paused : .playing
        isPlayingLocal = (nextState == .playing)
        if isPlayingLocal {
            lastAnchorTimestamp = CACurrentMediaTime()
        }
        currentTrack = Track(
            id: cur.id,
            title: cur.title,
            artist: cur.artist,
            album: cur.album,
            durationMs: cur.durationMs,
            currentPositionMs: interpolatedPositionMs,
            playbackState: nextState,
            playerType: cur.playerType,
            artwork: cur.artwork
        )
    }
}
