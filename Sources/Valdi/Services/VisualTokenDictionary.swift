import Foundation

public struct VisualToken: Equatable, Hashable {
    public let word: String
    public let sfSymbol: String
    public let emoji: String
    public let category: String
}

/// Rich dictionary mapping over 770 lyric words and tokens to matched SF Symbols and emojis.
public final class VisualTokenDictionary {
    public static let shared = VisualTokenDictionary()
    
    private var dictionary: [String: VisualToken] = [:]
    
    public init() {
        populateDictionary()
    }
    
    public func lookup(_ word: String) -> VisualToken? {
        let clean = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
        return dictionary[clean]
    }
    
    private func add(_ word: String, _ symbol: String, _ emoji: String, _ category: String) {
        let clean = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
        dictionary[clean] = VisualToken(word: clean, sfSymbol: symbol, emoji: emoji, category: category)
    }
    
    private func addMultiple(_ words: [String], _ symbol: String, _ emoji: String, _ category: String) {
        for w in words {
            add(w, symbol, emoji, category)
        }
    }
    
    private func populateDictionary() {
        // 1. Celestial & Space (~45 tokens)
        addMultiple(["star", "stars", "starry", "starlight", "supernova"], "sparkles", "✨", "Celestial")
        addMultiple(["sun", "sunshine", "sunny", "sunlight", "sunrise", "sunset", "dawn", "dusk"], "sun.max.fill", "☀️", "Celestial")
        addMultiple(["moon", "moonlight", "crescent", "lunar", "fullmoon", "nightlight"], "moon.stars.fill", "🌙", "Celestial")
        addMultiple(["sky", "skies", "heaven", "heavens", "cloud", "clouds", "cloudy"], "cloud.fill", "☁️", "Celestial")
        addMultiple(["galaxy", "universe", "cosmos", "space", "orbit", "planet", "planets", "asteroid"], "globe.americas.fill", "🌌", "Celestial")
        addMultiple(["night", "midnight", "dark", "darkness", "shadow", "shadows"], "moon.fill", "🌃", "Celestial")
        addMultiple(["aurora", "constellation", "eclipse", "zenith", "comet"], "sparkle", "🌠", "Celestial")

        // 2. Love, Heart & Romance (~50 tokens)
        addMultiple(["love", "loved", "loving", "lover", "lovers", "lovesick", "sweetheart"], "heart.fill", "❤️", "Romance")
        addMultiple(["heart", "hearts", "heartbeat", "pulse"], "heart.circle.fill", "💖", "Romance")
        addMultiple(["broken", "break", "breaking", "heartbreak", "heartbroken"], "heart.slash.fill", "💔", "Romance")
        addMultiple(["kiss", "kisses", "kissed", "kissing", "smooch"], "mouth.fill", "💋", "Romance")
        addMultiple(["hug", "hugs", "embrace", "holding", "hold"], "figure.arms.open", "🫂", "Romance")
        addMultiple(["romance", "romantic", "affair", "passion", "crush", "dating"], "flame.fill", "💘", "Romance")
        addMultiple(["forever", "always", "eternity", "eternal", "infinite", "infinity"], "infinity", "♾️", "Romance")
        addMultiple(["ring", "diamond", "marry", "marriage", "wedding", "bride", "groom", "vow", "vows"], "circle.fill", "💍", "Romance")

        // 3. Fire, Heat & Energy (~45 tokens)
        addMultiple(["fire", "flame", "flames", "burning", "burn", "burnt", "burns", "blaze", "blazing", "bonfire"], "flame.fill", "🔥", "Energy")
        addMultiple(["hot", "heat", "fever", "warm", "warmth", "boiling", "sizzle"], "thermometer.sun.fill", "🌡️", "Energy")
        addMultiple(["light", "lights", "glow", "glowing", "shine", "shining", "bright", "beam", "flash", "flare"], "bolt.fill", "💡", "Energy")
        addMultiple(["spark", "sparks", "glimmer", "twinkle", "radiant", "ignite", "ignited", "kindle"], "bolt.circle.fill", "⚡", "Energy")
        addMultiple(["smoke", "smoky", "ash", "ashes", "cinder", "embers"], "smoke.fill", "💨", "Energy")
        addMultiple(["electric", "electricity", "volt", "voltage", "current", "shock", "shocking", "power"], "bolt.fill", "⚡", "Energy")

        // 4. Water, Ocean & Liquid (~50 tokens)
        addMultiple(["water", "ocean", "sea", "seas", "tide", "tides", "wave", "waves", "deep", "abyss"], "water.waves", "🌊", "Water")
        addMultiple(["rain", "raining", "rainy", "raindrop", "raindrops", "rainfall", "shower", "downpour"], "cloud.rain.fill", "🌧️", "Water")
        addMultiple(["river", "stream", "lake", "flow", "flowing", "drift", "drifting", "currents"], "water.waves", "🏞️", "Water")
        addMultiple(["tear", "tears", "crying", "cry", "weep", "weeping", "sob", "sobbing"], "drop.triangle.fill", "💧", "Water")
        addMultiple(["drop", "drops", "drip", "dripping", "splash", "soaked", "drown", "drowning"], "drop.fill", "💧", "Water")
        addMultiple(["ice", "icy", "cold", "freeze", "freezing", "frozen", "frost", "chill", "chilly"], "snowflake", "🧊", "Water")
        addMultiple(["snow", "snowing", "snowy", "snowflake", "snowflakes", "blizzard", "winter"], "snowflake", "❄️", "Water")

        // 5. Music, Rhythm & Sound (~50 tokens)
        addMultiple(["music", "melody", "tune", "tunes", "harmony", "song", "songs", "soundtrack", "anthem"], "music.note", "🎵", "Music")
        addMultiple(["beat", "beats", "rhythm", "groove", "tempo", "bass", "drop", "drum", "drums", "percussion"], "music.note.list", "🥁", "Music")
        addMultiple(["sing", "singer", "singing", "sang", "sung", "vocal", "vocals", "mic", "microphone"], "mic.fill", "🎤", "Music")
        addMultiple(["guitar", "strings", "strum", "acoustic", "electricguitar", "riff", "solo"], "guitars.fill", "🎸", "Music")
        addMultiple(["piano", "keys", "keyboard", "chords", "synth", "synthesizer"], "pianokeys", "🎹", "Music")
        addMultiple(["dance", "dancing", "dancer", "dancers", "party", "club", "disco", "rave"], "figure.dance", "💃", "Music")
        addMultiple(["radio", "stereo", "boombox", "speaker", "speakers", "loud", "volume", "turnup"], "speaker.wave.3.fill", "📻", "Music")
        addMultiple(["listen", "listening", "hear", "hearing", "audio", "sound", "sounds", "echo", "echoes"], "headphones", "🎧", "Music")

        // 6. Time, Speed & Motion (~50 tokens)
        addMultiple(["time", "clock", "watch", "hour", "hours", "minute", "minutes", "second", "seconds", "tick", "tock"], "clock.fill", "⏱️", "Time")
        addMultiple(["fast", "speed", "quick", "race", "racing", "rush", "rushing", "chase", "chasing"], "gauge.with.needle.fill", "⚡", "Motion")
        addMultiple(["slow", "slowly", "patient", "wait", "waiting", "pause", "linger", "freeze"], "timer", "⏳", "Time")
        addMultiple(["fly", "flying", "flight", "flew", "flown", "soar", "soaring", "glide", "wings", "wing"], "airplane", "✈️", "Motion")
        addMultiple(["run", "running", "ran", "runner", "sprint", "escape", "flee"], "figure.run", "🏃", "Motion")
        addMultiple(["walk", "walking", "walked", "stroll", "steps", "footsteps", "wander", "wandering"], "figure.walk", "🚶", "Motion")
        addMultiple(["fall", "falling", "fell", "fallen", "drop", "plummet", "dive", "diving", "down"], "arrow.down.right.circle.fill", "🍂", "Motion")
        addMultiple(["jump", "jumping", "leap", "bounce", "hop", "rise", "rising", "climb", "higher"], "arrow.up.circle.fill", "🦘", "Motion")

        // 7. Nature, Botany & Earth (~50 tokens)
        addMultiple(["flower", "flowers", "rose", "roses", "petal", "petals", "blossom", "bloom", "blooming"], "camera.macro", "🌹", "Nature")
        addMultiple(["tree", "trees", "forest", "woods", "branch", "leaves", "leaf", "greenery"], "leaf.fill", "🌲", "Nature")
        addMultiple(["mountain", "mountains", "peak", "summit", "hill", "hills", "cliff", "rock", "rocks", "stone"], "mountain.2.fill", "🏔️", "Nature")
        addMultiple(["garden", "plant", "plants", "meadow", "field", "grass", "seed", "sprout"], "leaf.arrow.triangle.circlepath", "🌿", "Nature")
        addMultiple(["wind", "breeze", "storm", "hurricane", "tornado", "cyclone", "gale", "gust"], "wind", "🌪️", "Nature")
        addMultiple(["earth", "world", "ground", "dirt", "soil", "dust", "sand", "desert"], "globe.europe.africa.fill", "🌍", "Nature")

        // 8. Emotions, States & Mind (~55 tokens)
        addMultiple(["happy", "joy", "smile", "smiling", "laugh", "laughing", "glad", "delight", "cheerful"], "face.smiling.inverse", "😄", "Emotion")
        addMultiple(["sad", "sorrow", "grief", "pain", "hurt", "hurting", "ache", "lonely", "alone", "empty"], "heart.slash", "😢", "Emotion")
        addMultiple(["mad", "angry", "anger", "rage", "fury", "furious", "hate", "evil"], "exclamationmark.triangle.fill", "😡", "Emotion")
        addMultiple(["dream", "dreams", "dreaming", "daydream", "nightmare", "fantasy", "illusion", "vision"], "bubbles.and.sparkles.fill", "💭", "Emotion")
        addMultiple(["hope", "faith", "wish", "wishing", "believe", "belief", "trust", "prayer", "pray"], "sparkles", "🙏", "Emotion")
        addMultiple(["fear", "scared", "afraid", "terror", "dread", "horror", "panic", "shiver"], "eye.trianglebadge.exclamationmark", "😱", "Emotion")
        addMultiple(["crazy", "insane", "wild", "madness", "chaos", "psycho", "fool", "foolish"], "burst.fill", "🤪", "Emotion")
        addMultiple(["peace", "calm", "serene", "quiet", "still", "harmony", "zen", "silence", "silent"], "leaf.circle.fill", "🕊️", "Emotion")

        // 9. Combat, Triumph & Power (~40 tokens)
        addMultiple(["fight", "fighting", "battle", "war", "soldier", "warrior", "sword", "shield", "blade"], "shield.lefthalf.filled", "⚔️", "Power")
        addMultiple(["win", "winning", "winner", "victory", "champion", "triumph", "trophy", "medal"], "trophy.fill", "🏆", "Power")
        addMultiple(["king", "queen", "crown", "royal", "royalty", "throne", "prince", "princess", "empire"], "crown.fill", "👑", "Power")
        addMultiple(["kill", "blood", "bleed", "bleeding", "wound", "bullet", "gun", "shot", "weapon"], "cross.fill", "🩸", "Power")
        addMultiple(["danger", "dangerous", "warning", "poison", "toxic", "venom", "hazard"], "exclamationmark.shield.fill", "⚠️", "Power")

        // 10. Wealth, Money & Luxury (~40 tokens)
        addMultiple(["money", "cash", "dollars", "bills", "coins", "cents", "pay", "paid", "wealth", "rich"], "dollarsign.circle.fill", "💸", "Wealth")
        addMultiple(["gold", "golden", "silver", "platinum", "jewel", "jewels", "gem", "gems", "luxury", "fortune"], "circle.hexagongrid.fill", "🪙", "Wealth")
        addMultiple(["bank", "rich", "billionaire", "millionaire", "treasure", "gamble", "jackpot", "casino"], "banknote.fill", "💰", "Wealth")
        addMultiple(["chain", "chains", "ice", "bling", "wrist", "expensive", "rollie", "rolex"], "link", "⛓️", "Wealth")

        // 11. Travel, Places & Vehicles (~45 tokens)
        addMultiple(["car", "cars", "drive", "driving", "drove", "ride", "riding", "road", "highway", "street"], "car.fill", "🚗", "Travel")
        addMultiple(["train", "locomotive", "rail", "railway", "subway", "metro", "station"], "tram.fill", "🚆", "Travel")
        addMultiple(["plane", "airplane", "jet", "flight", "airport", "runway", "travel", "journey"], "airplane.departure", "🛫", "Travel")
        addMultiple(["boat", "ship", "sail", "sailing", "cruise", "harbor", "port", "anchor"], "ferry.fill", "⛵", "Travel")
        addMultiple(["city", "town", "urban", "downtown", "metropolis", "buildings", "skyline", "tower"], "building.2.fill", "🏙️", "Travel")
        addMultiple(["home", "house", "room", "door", "walls", "window", "roof", "shelter"], "house.fill", "🏠", "Travel")
        addMultiple(["bridge", "path", "trail", "crossing", "tracks", "lane", "avenue"], "arrow.triangle.swap", "🌉", "Travel")

        // 12. Party, Drinks & Food (~40 tokens)
        addMultiple(["drink", "drinks", "drinking", "drank", "drunk", "sip", "sipping", "glass", "cup", "bottle"], "wineglass.fill", "🍷", "Lifestyle")
        addMultiple(["wine", "champagne", "beer", "whiskey", "vodka", "tequila", "toast", "cheers", "liquor"], "cup.and.saucer.fill", "🥂", "Lifestyle")
        addMultiple(["smoke", "weed", "blunt", "puff", "cigarette", "cigar", "high", "stoned"], "smoke.fill", "🚬", "Lifestyle")
        addMultiple(["coffee", "tea", "cafe", "espresso", "morning", "brew", "caffeine"], "cup.and.saucer.fill", "☕", "Lifestyle")
        addMultiple(["candy", "sweet", "honey", "sugar", "cake", "cookie", "chocolate", "pie"], "birthday.cake.fill", "🍰", "Lifestyle")
        addMultiple(["celebrate", "celebration", "confetti", "party", "cheer", "cheering", "toast"], "party.popper.fill", "🎉", "Lifestyle")

        // 13. Senses & Body (~45 tokens)
        addMultiple(["eye", "eyes", "sight", "look", "looking", "see", "seeing", "saw", "stare", "glance"], "eye.fill", "👀", "Body")
        addMultiple(["blind", "unseen", "blink", "vision", "gaze", "watching", "watch"], "eye.slash.fill", "🕶️", "Body")
        addMultiple(["lip", "lips", "mouth", "tongue", "taste", "tasting", "whisper", "talk", "talking"], "mouth.fill", "👄", "Body")
        addMultiple(["hand", "hands", "finger", "fingers", "touch", "touching", "hold", "palm", "fist"], "hand.raised.fill", "✋", "Body")
        addMultiple(["head", "brain", "mind", "thoughts", "thinking", "thought", "memory", "memories"], "brain.head.profile", "🧠", "Body")
        addMultiple(["breath", "breathe", "breathing", "inhale", "exhale", "sigh", "air", "lungs"], "wind", "🫁", "Body")
        addMultiple(["skin", "bone", "bones", "flesh", "body", "spine", "skeleton"], "figure.stand", "🦴", "Body")

        // 14. Technology, Media & Modern (~45 tokens)
        addMultiple(["phone", "call", "calling", "ring", "ringing", "cell", "iphone", "message", "text"], "phone.fill", "📱", "Tech")
        addMultiple(["screen", "tv", "video", "camera", "photo", "picture", "snapshot", "film", "movie"], "camera.fill", "📸", "Tech")
        addMultiple(["computer", "online", "code", "digital", "internet", "signal", "wifi", "network"], "network", "💻", "Tech")
        addMultiple(["game", "player", "play", "level", "score", "controller", "arcade"], "gamecontroller.fill", "🎮", "Tech")
        addMultiple(["robot", "ai", "machine", "cyborg", "future", "android", "laser", "neon"], "cpu.fill", "🤖", "Tech")

        // 15. Magic, Fantasy & Mystery (~45 tokens)
        addMultiple(["magic", "spell", "witch", "wizard", "wand", "potion", "curse", "enchanted", "charm"], "wand.and.stars", "🪄", "Magic")
        addMultiple(["ghost", "spirit", "phantom", "haunt", "haunted", "spooky", "specter", "soul"], "theatermasks.fill", "👻", "Magic")
        addMultiple(["monster", "beast", "creature", "dragon", "demon", "devil", "angel", "halo"], "flame.circle.fill", "👹", "Magic")
        addMultiple(["secret", "mystery", "hidden", "mask", "clue", "riddle", "shadow"], "theatermasks", "🎭", "Magic")
        addMultiple(["key", "lock", "unlocked", "locked", "vault", "doorway", "gate", "portal"], "key.fill", "🔑", "Magic")

        // 16. Animals & Wildlife (~40 tokens)
        addMultiple(["bird", "birds", "dove", "eagle", "hawk", "raven", "crow", "sparrow", "feather"], "bird.fill", "🦅", "Animal")
        addMultiple(["wolf", "wolves", "dog", "hound", "howl", "pack"], "pawprint.fill", "🐺", "Animal")
        addMultiple(["cat", "tiger", "lion", "panther", "leopard", "claws", "roar"], "pawprint.fill", "🦁", "Animal")
        addMultiple(["snake", "serpent", "viper", "cobra", "venomous"], "tropicalstorm", "🐍", "Animal")
        addMultiple(["fish", "shark", "whale", "dolphin", "swimming"], "fish.fill", "🦈", "Animal")
        addMultiple(["butterfly", "moth", "bee", "wasp", "spider", "insect"], "ladybug.fill", "🦋", "Animal")

        // 17. Colors & Aesthetics (~45 tokens)
        addMultiple(["red", "crimson", "scarlet", "ruby", "cherry", "bloodred"], "paintpalette.fill", "🔴", "Color")
        addMultiple(["blue", "azure", "cobalt", "sapphire", "indigo", "navy", "cyan"], "paintpalette.fill", "🔵", "Color")
        addMultiple(["gold", "yellow", "amber", "lemon", "blonde"], "paintpalette.fill", "🟡", "Color")
        addMultiple(["green", "emerald", "jade", "mint", "olive"], "paintpalette.fill", "🟢", "Color")
        addMultiple(["purple", "violet", "lavender", "plum", "magenta"], "paintpalette.fill", "🟣", "Color")
        addMultiple(["black", "dark", "ebony", "onyx", "jet"], "circle.fill", "⚫", "Color")
        addMultiple(["white", "pure", "snow", "ivory", "pearl"], "circle", "⚪", "Color")

        // 18. Common Lyric Words & Exclamations (~60 tokens)
        addMultiple(["yeah", "yes", "yep", "sure", "ok", "okay", "alright"], "checkmark.seal.fill", "👍", "General")
        addMultiple(["no", "nope", "never", "nah", "stop", "halt", "don't"], "xmark.octagon.fill", "🛑", "General")
        addMultiple(["baby", "babe", "girl", "boy", "man", "woman", "guy", "child", "kid"], "figure.stand", "👶", "General")
        addMultiple(["friend", "friends", "crew", "squad", "brother", "sister", "homie", "family"], "person.3.fill", "👥", "General")
        addMultiple(["god", "lord", "savior", "saint", "temple", "church", "altar", "cross"], "cross.fill", "⛪", "General")
        addMultiple(["hell", "underworld", "inferno", "grave", "cemetery", "tomb"], "flame.fill", "🔥", "General")
        addMultiple(["light", "shine", "illuminate", "glow", "sparkle"], "sun.horizon.fill", "✨", "General")
        addMultiple(["question", "wonder", "why", "who", "where", "when", "how"], "questionmark.circle.fill", "❓", "General")
        addMultiple(["answer", "truth", "lie", "lies", "secret", "reveal"], "lightbulb.fill", "💡", "General")
    }
    
    public var totalTokensCount: Int {
        dictionary.count
    }
}
