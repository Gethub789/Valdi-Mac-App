import AppKit
import CoreImage
import SwiftUI

public struct ExtractedPalette: Equatable {
    public let dominant: Color
    public let highlight: Color
    public let secondary: Color
    public let backgroundTint: Color
    
    public static let fallback = ExtractedPalette(
        dominant: Color(red: 0.1, green: 0.2, blue: 0.3),
        highlight: Color(red: 0.20, green: 0.90, blue: 0.85),
        secondary: Color(white: 0.6),
        backgroundTint: Color.black.opacity(0.85)
    )
}

/// Dynamic color extraction engine for sampling vibrant palettes from album artwork.
public final class PaletteEngine {
    public static let shared = PaletteEngine()
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    
    // Cache extracted palettes by image hash or track id
    private var cache = [String: ExtractedPalette]()
    
    public init() {}
    
    /// Extracts a high-contrast 3-color palette from the provided album art NSImage.
    public func extractPalette(from image: NSImage?, trackId: String = "") -> ExtractedPalette {
        guard let image = image else {
            return .fallback
        }
        
        if !trackId.isEmpty, let cached = cache[trackId] {
            return cached
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .fallback
        }
        
        // Downsample image to 64x64 for rapid, low-CPU sampling
        let width = 64
        let height = 64
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return .fallback
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Analyze pixel colors: find most saturated (highlight) and most dominant
        var colorBuckets: [(r: Double, g: Double, b: Double, sat: Double, lum: Double)] = []
        colorBuckets.reserveCapacity(width * height)
        
        var sumR: Double = 0
        var sumG: Double = 0
        var sumB: Double = 0
        
        for i in stride(from: 0, to: rawData.count, by: bytesPerPixel * 4) { // step by 4 pixels
            let r = Double(rawData[i]) / 255.0
            let g = Double(rawData[i + 1]) / 255.0
            let b = Double(rawData[i + 2]) / 255.0
            
            sumR += r
            sumG += g
            sumB += b
            
            let maxC = max(r, max(g, b))
            let minC = min(r, min(g, b))
            let delta = maxC - minC
            let lum = (maxC + minC) / 2.0
            let sat = lum == 0 ? 0 : delta / (1.0 - abs(2.0 * lum - 1.0) + 0.0001)
            
            colorBuckets.append((r: r, g: g, b: b, sat: sat, lum: lum))
        }
        
        guard !colorBuckets.isEmpty else { return .fallback }
        
        let count = Double(colorBuckets.count)
        let avgR = sumR / count
        let avgG = sumG / count
        let avgB = sumB / count
        
        // Find most vibrant/saturated color with pleasant luminance for highlight (0.45 - 0.85 lum)
        let vibrantCandidates = colorBuckets
            .filter { $0.lum >= 0.35 && $0.lum <= 0.88 }
            .sorted { $0.sat > $1.sat }
        
        let highlightPixel = vibrantCandidates.first ?? (r: 0.20, g: 0.90, b: 0.85, sat: 0.8, lum: 0.6)
        
        // Enhance highlight color if it's too muted
        let boostFactor: Double = highlightPixel.sat < 0.3 ? 1.3 : 1.0
        let hR = min(1.0, highlightPixel.r * boostFactor)
        let hG = min(1.0, highlightPixel.g * boostFactor)
        let hB = min(1.0, highlightPixel.b * boostFactor)
        
        // Construct palette
        let dominantColor = Color(.sRGB, red: avgR, green: avgG, blue: avgB, opacity: 1.0)
        let highlightColor = Color(.sRGB, red: hR, green: hG, blue: hB, opacity: 1.0)
        
        // Secondary color: harmonic pastel or muted complementary
        let secR = (avgR + hR) * 0.5 * 0.9 + 0.1
        let secG = (avgG + hG) * 0.5 * 0.9 + 0.1
        let secB = (avgB + hB) * 0.5 * 0.9 + 0.1
        let secondaryColor = Color(.sRGB, red: secR, green: secG, blue: secB, opacity: 0.8)
        
        // Deep background tint
        let bgR = avgR * 0.15
        let bgG = avgG * 0.15
        let bgB = avgB * 0.15
        let backgroundTint = Color(.sRGB, red: bgR, green: bgG, blue: bgB, opacity: 0.88)
        
        let palette = ExtractedPalette(
            dominant: dominantColor,
            highlight: highlightColor,
            secondary: secondaryColor,
            backgroundTint: backgroundTint
        )
        
        if !trackId.isEmpty {
            cache[trackId] = palette
        }
        
        return palette
    }
}
