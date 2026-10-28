import Foundation

/// Individual word with exact millisecond start and end boundaries.
public struct WordLyric: Identifiable, Equatable, Hashable {
    public let id: UUID
    public let text: String
    public let cleanWord: String
    public let startTimeMs: Double
    public let endTimeMs: Double
    public var matchedSymbolName: String?
    public var matchedEmoji: String?
    
    public init(
        id: UUID = UUID(),
        text: String,
        startTimeMs: Double,
        endTimeMs: Double,
        matchedSymbolName: String? = nil,
        matchedEmoji: String? = nil
    ) {
        self.id = id
        self.text = text
        self.cleanWord = text.trimmingCharacters(in: .punctuationCharacters).lowercased()
        self.startTimeMs = startTimeMs
        self.endTimeMs = endTimeMs
        self.matchedSymbolName = matchedSymbolName
        self.matchedEmoji = matchedEmoji
    }
    
    public var durationMs: Double {
        max(1.0, endTimeMs - startTimeMs)
    }
    
    public func isActive(at positionMs: Double) -> Bool {
        return positionMs >= startTimeMs && positionMs < endTimeMs
    }
    
    public func isPast(at positionMs: Double) -> Bool {
        return positionMs >= endTimeMs
    }
    
    public func progress(at positionMs: Double) -> Double {
        if positionMs < startTimeMs { return 0.0 }
        if positionMs >= endTimeMs { return 1.0 }
        return (positionMs - startTimeMs) / durationMs
    }
}

/// A complete lyric line consisting of word tokens.
public struct LineLyric: Identifiable, Equatable {
    public let id: Int
    public let startTimeMs: Double
    public let endTimeMs: Double
    public let rawText: String
    public var words: [WordLyric]
    
    public init(
        id: Int,
        startTimeMs: Double,
        endTimeMs: Double,
        rawText: String,
        words: [WordLyric] = []
    ) {
        self.id = id
        self.startTimeMs = startTimeMs
        self.endTimeMs = endTimeMs
        self.rawText = rawText
        self.words = words
    }
    
    public var durationMs: Double {
        max(1.0, endTimeMs - startTimeMs)
    }
    
    public func isActive(at positionMs: Double) -> Bool {
        return positionMs >= startTimeMs && positionMs <= endTimeMs
    }
    
    public func activeWordIndex(at positionMs: Double) -> Int? {
        return words.firstIndex { $0.isActive(at: positionMs) }
    }
    
    public func activeWord(at positionMs: Double) -> WordLyric? {
        return words.first { $0.isActive(at: positionMs) }
    }
}

/// The entire song synced lyrics collection.
public struct SyncedSongLyrics: Equatable {
    public let title: String
    public let artist: String
    public let durationMs: Double
    public var lines: [LineLyric]
    public let isWordLevelSynced: Bool
    
    public init(
        title: String,
        artist: String,
        durationMs: Double,
        lines: [LineLyric],
        isWordLevelSynced: Bool = true
    ) {
        self.title = title
        self.artist = artist
        self.durationMs = durationMs
        self.lines = lines
        self.isWordLevelSynced = isWordLevelSynced
    }
    
    public func activeLineIndex(at positionMs: Double) -> Int? {
        // Return matching line or closest preceding line
        if let exact = lines.firstIndex(where: { $0.isActive(at: positionMs) }) {
            return exact
        }
        // Fallback: finding the last line whose start time is <= position
        return lines.lastIndex(where: { $0.startTimeMs <= positionMs })
    }
    
    public func activeLine(at positionMs: Double) -> LineLyric? {
        guard let index = activeLineIndex(at: positionMs), lines.indices.contains(index) else {
            return nil
        }
        return lines[index]
    }
    
    public static let empty = SyncedSongLyrics(
        title: "",
        artist: "",
        durationMs: 0,
        lines: [],
        isWordLevelSynced: false
    )
}
