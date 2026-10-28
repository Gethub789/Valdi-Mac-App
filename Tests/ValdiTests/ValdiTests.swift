import XCTest
@testable import Valdi

final class ValdiTests: XCTestCase {
    
    // MARK: - Visual Token Dictionary Tests
    
    func testVisualTokenDictionaryCoverage() {
        let dict = VisualTokenDictionary.shared
        XCTAssertGreaterThan(dict.totalTokensCount, 700, "Dictionary should contain >700 curated tokens")
        
        // Test essential lyric vocabulary
        let testWords = ["star", "love", "heart", "fire", "night", "ocean", "music", "car", "dance", "baby"]
        for word in testWords {
            let token = dict.lookup(word)
            XCTAssertNotNil(token, "Word '\(word)' should be indexed in VisualTokenDictionary")
            XCTAssertFalse(token?.sfSymbol.isEmpty ?? true)
            XCTAssertFalse(token?.emoji.isEmpty ?? true)
        }
    }
    
    func testVisualTokenPunctuationStripping() {
        let dict = VisualTokenDictionary.shared
        let token = dict.lookup("fire!!,")
        XCTAssertNotNil(token)
        XCTAssertEqual(token?.word, "fire")
        XCTAssertEqual(token?.sfSymbol, "flame.fill")
    }
    
    // MARK: - Lyrics Engine & Syllable Synthesis Tests
    
    func testLrcParsing() {
        let engine = LyricsEngine.shared
        let rawLrc = """
        [00:04.50] Look what you've done
        [00:08.20] I'm a motherfuckin' starboy
        """
        
        let song = engine.parseSyncedLrc(rawLrc: rawLrc, title: "Starboy", artist: "The Weeknd", durationMs: 20000)
        XCTAssertEqual(song.lines.count, 2)
        XCTAssertEqual(song.lines[0].startTimeMs, 4500)
        XCTAssertEqual(song.lines[1].startTimeMs, 8200)
        
        // Verify word synthesis ensures every word has non-zero duration
        for line in song.lines {
            XCTAssertFalse(line.words.isEmpty)
            for word in line.words {
                XCTAssertGreaterThan(word.durationMs, 0)
                XCTAssertLessThanOrEqual(word.startTimeMs, word.endTimeMs)
            }
        }
    }
    
    func testWordTimingContinuity() {
        let engine = LyricsEngine.shared
        let line = "I said ooh I'm blinded by the lights"
        let words = engine.synthesizeWordTimings(for: line, startMs: 1000, endMs: 5000)
        
        XCTAssertEqual(words.count, 8)
        XCTAssertEqual(words.first?.startTimeMs, 1000)
        XCTAssertEqual(words.last?.endTimeMs, 5000)
        
        // Verify continuous time flow without negative gaps
        for i in 0..<(words.count - 1) {
            XCTAssertEqual(words[i].endTimeMs, words[i + 1].startTimeMs, accuracy: 0.001)
        }
    }
    
    func testWordActiveEvaluation() {
        let word = WordLyric(text: "Hello", startTimeMs: 2000, endTimeMs: 3000)
        XCTAssertFalse(word.isActive(at: 1999))
        XCTAssertTrue(word.isActive(at: 2000))
        XCTAssertTrue(word.isActive(at: 2500))
        XCTAssertFalse(word.isActive(at: 3000))
        XCTAssertTrue(word.isPast(at: 3000))
        XCTAssertEqual(word.progress(at: 2500), 0.5, accuracy: 0.01)
    }
    
    // MARK: - Display Style Tests
    
    func testDisplayStyles() {
        let allStyles = DisplayStyle.allCases
        XCTAssertEqual(allStyles.count, 4)
        XCTAssertTrue(DisplayStyle.fisheye.usesMetalShader)
        XCTAssertTrue(DisplayStyle.fisheyeVisual.usesMetalShader)
        XCTAssertFalse(DisplayStyle.ship.usesMetalShader)
        XCTAssertTrue(DisplayStyle.visual.showsVisualTokens)
    }
}
