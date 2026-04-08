import Foundation

/// Represents a color extracted from text
public struct ExtractedColor: Hashable, Equatable {
    public let original: String
    public let format: ColorFormat
    public let normalized: String
    public let range: Range<String.Index>?

    public init(original: String, format: ColorFormat, normalized: String, range: Range<String.Index>? = nil) {
        self.original = original
        self.format = format
        self.normalized = normalized
        self.range = range
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(normalized)
    }

    public static func == (lhs: ExtractedColor, rhs: ExtractedColor) -> Bool {
        lhs.normalized == rhs.normalized
    }
}

/// Supported color formats
public enum ColorFormat: String, CaseIterable, Sendable {
    case hex
    case rgb
    case rgba
    case hsl
    case hsla
    case oklch
    case oklcha
}

/// Protocol for types that can be represented as a color
public protocol ColorRepresentable {
    var normalized: String { get }
    var format: ColorFormat { get }
}

/// Hex color representation
public struct HexColor: ColorRepresentable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8?

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8? = nil) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var normalized: String {
        if let alpha = alpha {
            return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
        }
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    public var format: ColorFormat {
        alpha != nil ? .hex : .hex
    }
}

/// RGB color representation
public struct RGBColor: ColorRepresentable {
    public let red: Int
    public let green: Int
    public let blue: Int
    public let alpha: Double?

    public init(red: Int, green: Int, blue: Int, alpha: Double? = nil) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var normalized: String {
        // Normalize to hex for comparison
        let r = UInt8(clamping: red)
        let g = UInt8(clamping: green)
        let b = UInt8(clamping: blue)

        if let alpha = alpha {
            let a = UInt8(clamping: Int(alpha * 255))
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    public var format: ColorFormat {
        alpha != nil ? .rgba : .rgb
    }
}

/// HSL color representation
public struct HSLColor: ColorRepresentable {
    public let hue: Double
    public let saturation: Double
    public let lightness: Double
    public let alpha: Double?

    public init(hue: Double, saturation: Double, lightness: Double, alpha: Double? = nil) {
        self.hue = hue
        self.saturation = saturation
        self.lightness = lightness
        self.alpha = alpha
    }

    public var normalized: String {
        // Convert to RGB for normalization
        let rgb = toRGB()
        return rgb.normalized
    }

    public var format: ColorFormat {
        alpha != nil ? .hsla : .hsl
    }

    private func toRGB() -> RGBColor {
        let h = hue / 360.0
        let s = saturation / 100.0
        let l = lightness / 100.0

        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q

        let r = hueToRGB(p: p, q: q, t: h + 1/3.0)
        let g = hueToRGB(p: p, q: q, t: h)
        let b = hueToRGB(p: p, q: q, t: h - 1/3.0)

        return RGBColor(
            red: Int(r * 255),
            green: Int(g * 255),
            blue: Int(b * 255),
            alpha: alpha
        )
    }

    private func hueToRGB(p: Double, q: Double, t: Double) -> Double {
        var t = t
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        if t < 1/6.0 { return p + (q - p) * 6 * t }
        if t < 1/2.0 { return q }
        if t < 2/3.0 { return p + (q - p) * (2/3.0 - t) * 6 }
        return p
    }
}

/// OKLCH color representation
public struct OKLCHColor: ColorRepresentable {
    public let lightness: Double
    public let chroma: Double
    public let hue: Double
    public let alpha: Double?

    public init(lightness: Double, chroma: Double, hue: Double, alpha: Double? = nil) {
        self.lightness = lightness
        self.chroma = chroma
        self.hue = hue
        self.alpha = alpha
    }

    public var normalized: String {
        // For now, use string representation for OKLCH
        // Full OKLCH to RGB conversion requires complex color space math
        if let alpha = alpha {
            return String(format: "oklch(%.2f%% %.4f %.2f / %.2f)", lightness, chroma, hue, alpha)
        }
        return String(format: "oklch(%.2f%% %.4f %.2f)", lightness, chroma, hue)
    }

    public var format: ColorFormat {
        alpha != nil ? .oklcha : .oklch
    }
}
