import AppKit
import Foundation

public enum MediaPlayerType: String, Codable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case none = "None"
}

public enum PlaybackState: String, Codable {
    case playing = "Playing"
    case paused = "Paused"
    case stopped = "Stopped"
}

/// Represents real-time metadata of currently playing track.
public struct Track: Equatable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String
    public let durationMs: Double
    public var currentPositionMs: Double
    public let playbackState: PlaybackState
    public let playerType: MediaPlayerType
    public let artwork: NSImage?
    public let artworkData: Data?
    
    public init(
        id: String,
        title: String,
        artist: String,
        album: String,
        durationMs: Double,
        currentPositionMs: Double,
        playbackState: PlaybackState,
        playerType: MediaPlayerType,
        artwork: NSImage? = nil,
        artworkData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.durationMs = durationMs
        self.currentPositionMs = currentPositionMs
        self.playbackState = playbackState
        self.playerType = playerType
        self.artwork = artwork
        self.artworkData = artworkData
    }
    
    public var isPlaying: Bool {
        playbackState == .playing
    }
    
    public var durationFormatted: String {
        let totalSeconds = Int(durationMs / 1000)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    public var currentPositionFormatted: String {
        let totalSeconds = Int(currentPositionMs / 1000)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    public static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.artist == rhs.artist &&
               lhs.playbackState == rhs.playbackState &&
               lhs.playerType == rhs.playerType &&
               abs(lhs.currentPositionMs - rhs.currentPositionMs) < 200
    }
}
