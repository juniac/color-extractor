import Foundation

/// Main color extractor that finds and deduplicates colors from text
@available(macOS 13.0, iOS 16.0, *)
public struct ColorExtractorEngine {
    public init() {}

    /// Extract colors from a string
    /// - Parameter text: The text to extract colors from
    /// - Returns: Array of unique extracted colors
    public func extract(from text: String) -> [ExtractedColor] {
        var colors: [ExtractedColor] = []

        // Extract hex colors
        colors.append(contentsOf: extractHexColors(from: text))

        // Extract RGB/RGBA colors
        colors.append(contentsOf: extractRGBColors(from: text))

        // Extract HSL/HSLA colors
        colors.append(contentsOf: extractHSLColors(from: text))

        // Extract OKLCH colors
        colors.append(contentsOf: extractOKLCHColors(from: text))

        // Deduplicate based on normalized values
        return deduplicate(colors)
    }

    /// Extract colors from multiple lines of text
    /// - Parameter lines: Array of text lines
    /// - Returns: Array of unique extracted colors
    public func extract(from lines: [String]) -> [ExtractedColor] {
        let allColors = lines.flatMap { extract(from: $0) }
        return deduplicate(allColors)
    }

    // MARK: - Private extraction methods

    private func extractHexColors(from text: String) -> [ExtractedColor] {
        var colors: [ExtractedColor] = []

        for match in text.matches(of: ColorPattern.hex) {
            let matchString = String(text[match.range])

            if let hexColor = ColorParser.parseHex(matchString) {
                let extracted = ExtractedColor(
                    original: matchString,
                    format: .hex,
                    normalized: hexColor.normalized,
                    range: match.range
                )
                colors.append(extracted)
            }
        }

        return colors
    }

    private func extractRGBColors(from text: String) -> [ExtractedColor] {
        var colors: [ExtractedColor] = []

        for match in text.matches(of: ColorPattern.rgb) {
            let matchString = String(text[match.range])

            // Extract components from match
            let red = match.output.1
            let green = match.output.2
            let blue = match.output.3
            let alpha = match.output.4

            if let rgbColor = ColorParser.parseRGB(
                red: String(red),
                green: String(green),
                blue: String(blue),
                alpha: alpha.map { String($0) }
            ) {
                let extracted = ExtractedColor(
                    original: matchString,
                    format: rgbColor.format,
                    normalized: rgbColor.normalized,
                    range: match.range
                )
                colors.append(extracted)
            }
        }

        return colors
    }

    private func extractHSLColors(from text: String) -> [ExtractedColor] {
        var colors: [ExtractedColor] = []

        for match in text.matches(of: ColorPattern.hsl) {
            let matchString = String(text[match.range])

            // Extract components from match
            let hue = match.output.1
            let saturation = match.output.2
            let lightness = match.output.3
            let alpha = match.output.4

            if let hslColor = ColorParser.parseHSL(
                hue: String(hue),
                saturation: String(saturation),
                lightness: String(lightness),
                alpha: alpha.map { String($0) }
            ) {
                let extracted = ExtractedColor(
                    original: matchString,
                    format: hslColor.format,
                    normalized: hslColor.normalized,
                    range: match.range
                )
                colors.append(extracted)
            }
        }

        return colors
    }

    private func extractOKLCHColors(from text: String) -> [ExtractedColor] {
        var colors: [ExtractedColor] = []

        for match in text.matches(of: ColorPattern.oklch) {
            let matchString = String(text[match.range])

            // Extract components from match
            let lightness = match.output.1
            let chroma = match.output.2
            let hue = match.output.3
            let alpha = match.output.4

            if let oklchColor = ColorParser.parseOKLCH(
                lightness: String(lightness),
                chroma: String(chroma),
                hue: String(hue),
                alpha: alpha.map { String($0) }
            ) {
                let extracted = ExtractedColor(
                    original: matchString,
                    format: oklchColor.format,
                    normalized: oklchColor.normalized,
                    range: match.range
                )
                colors.append(extracted)
            }
        }

        return colors
    }

    // MARK: - Deduplication

    private func deduplicate(_ colors: [ExtractedColor]) -> [ExtractedColor] {
        var seen = Set<String>()
        var unique: [ExtractedColor] = []

        for color in colors {
            let normalizedLower = color.normalized.lowercased()

            if !seen.contains(normalizedLower) {
                seen.insert(normalizedLower)
                unique.append(color)
            }
        }

        return unique
    }
}
