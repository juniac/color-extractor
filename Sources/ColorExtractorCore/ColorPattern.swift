import Foundation

/// Color pattern matching definitions
@available(macOS 13.0, iOS 16.0, *)
public enum ColorPattern {
    /// Hex patterns: #RGB, #RRGGBB, #RRGGBBAA
    nonisolated(unsafe) public static let hex = #/
        \#(?:[0-9A-Fa-f]{8}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})(?![0-9A-Fa-f])
    /#

    /// RGB pattern: rgb(r, g, b) or rgba(r, g, b, a)
    nonisolated(unsafe) public static let rgb = #/
        rgba?\s*\(\s*
        (\d{1,3})\s*,\s*
        (\d{1,3})\s*,\s*
        (\d{1,3})
        (?:\s*,\s*(0|1|0?\.\d+))?
        \s*\)
    /#

    /// HSL pattern: hsl(h, s%, l%) or hsla(h, s%, l%, a)
    nonisolated(unsafe) public static let hsl = #/
        hsla?\s*\(\s*
        (\d{1,3}(?:\.\d+)?)\s*,?\s*
        (\d{1,3}(?:\.\d+)?)%\s*,?\s*
        (\d{1,3}(?:\.\d+)?)%
        (?:\s*,?\s*\/?\s*(0|1|0?\.\d+))?
        \s*\)
    /#

    /// OKLCH pattern: oklch(l% c h) or oklch(l% c h / a)
    nonisolated(unsafe) public static let oklch = #/
        oklch\s*\(\s*
        (\d{1,3}(?:\.\d+)?)%\s+
        (\d+(?:\.\d+)?)\s+
        (\d{1,3}(?:\.\d+)?)
        (?:\s*\/\s*(0|1|0?\.\d+))?
        \s*\)
    /#
}

/// Parser utilities for extracting color values from regex matches
@available(macOS 13.0, iOS 16.0, *)
public enum ColorParser {
    /// Parse hex color from string
    public static func parseHex(_ string: String) -> HexColor? {
        var hexString = string
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        // Expand 3-digit hex to 6-digit
        if hexString.count == 3 {
            hexString = hexString.map { "\($0)\($0)" }.joined()
        }

        guard hexString.count == 6 || hexString.count == 8 else {
            return nil
        }

        let scanner = Scanner(string: hexString)
        var hexValue: UInt64 = 0

        guard scanner.scanHexInt64(&hexValue) else {
            return nil
        }

        if hexString.count == 6 {
            return HexColor(
                red: UInt8((hexValue & 0xFF0000) >> 16),
                green: UInt8((hexValue & 0x00FF00) >> 8),
                blue: UInt8(hexValue & 0x0000FF)
            )
        } else {
            return HexColor(
                red: UInt8((hexValue & 0xFF000000) >> 24),
                green: UInt8((hexValue & 0x00FF0000) >> 16),
                blue: UInt8((hexValue & 0x0000FF00) >> 8),
                alpha: UInt8(hexValue & 0x000000FF)
            )
        }
    }

    /// Parse RGB/RGBA color from components
    public static func parseRGB(red: String, green: String, blue: String, alpha: String? = nil) -> RGBColor? {
        guard let r = Int(red), let g = Int(green), let b = Int(blue),
              r >= 0 && r <= 255,
              g >= 0 && g <= 255,
              b >= 0 && b <= 255 else {
            return nil
        }

        var a: Double? = nil
        if let alphaStr = alpha, let alphaVal = Double(alphaStr) {
            guard alphaVal >= 0 && alphaVal <= 1 else { return nil }
            a = alphaVal
        }

        return RGBColor(red: r, green: g, blue: b, alpha: a)
    }

    /// Parse HSL/HSLA color from components
    public static func parseHSL(hue: String, saturation: String, lightness: String, alpha: String? = nil) -> HSLColor? {
        guard let h = Double(hue), let s = Double(saturation), let l = Double(lightness),
              h >= 0 && h <= 360,
              s >= 0 && s <= 100,
              l >= 0 && l <= 100 else {
            return nil
        }

        var a: Double? = nil
        if let alphaStr = alpha, let alphaVal = Double(alphaStr) {
            guard alphaVal >= 0 && alphaVal <= 1 else { return nil }
            a = alphaVal
        }

        return HSLColor(hue: h, saturation: s, lightness: l, alpha: a)
    }

    /// Parse OKLCH color from components
    public static func parseOKLCH(lightness: String, chroma: String, hue: String, alpha: String? = nil) -> OKLCHColor? {
        guard let l = Double(lightness), let c = Double(chroma), let h = Double(hue),
              l >= 0 && l <= 100,
              c >= 0,
              h >= 0 && h <= 360 else {
            return nil
        }

        var a: Double? = nil
        if let alphaStr = alpha, let alphaVal = Double(alphaStr) {
            guard alphaVal >= 0 && alphaVal <= 1 else { return nil }
            a = alphaVal
        }

        return OKLCHColor(lightness: l, chroma: c, hue: h, alpha: a)
    }
}
