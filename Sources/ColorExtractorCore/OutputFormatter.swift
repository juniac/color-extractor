import Foundation

/// Output format for color extraction results
public enum OutputFormat {
    case standard
    case json
    case toml
    case clean
}

/// Color output format for conversion
public enum ColorOutputFormat: String, CaseIterable {
    case hex
    case rgb
    case rgba
    case hsl
    case hsla
    case hwb
    case lch
    case lab
    case oklab
    case oklch
    case swiftUIColor = "swiftui"
    case uiColor = "uicolor"
    case cgColor = "cgcolor"
}

/// Formats extracted colors for output
@available(macOS 13.0, iOS 16.0, *)
public struct OutputFormatter {
    private let format: OutputFormat
    private let colorFormat: ColorOutputFormat?

    public init(format: OutputFormat, colorFormat: ColorOutputFormat? = nil) {
        self.format = format
        self.colorFormat = colorFormat
    }

    /// Format colors for output
    public func format(colors: [ExtractedColor], source: String) -> String {
        switch format {
        case .standard:
            return formatStandard(colors: colors, source: source)
        case .json:
            return formatJSON(colors: colors, source: source)
        case .toml:
            return formatTOML(colors: colors, source: source)
        case .clean:
            return formatClean(colors: colors)
        }
    }

    // MARK: - Format Implementations

    private func formatStandard(colors: [ExtractedColor], source: String) -> String {
        guard !colors.isEmpty else {
            return "No colors found in \(source)"
        }

        var output = "Found \(colors.count) unique color(s) in \(source):\n\n"

        for (index, color) in colors.enumerated() {
            let formatted = formatColor(color)
            output += "\(index + 1). \(color.original) [\(color.format.rawValue)] -> \(formatted)\n"
        }

        return output
    }

    private func formatJSON(colors: [ExtractedColor], source: String) -> String {
        // Build DTCG (Design Tokens Community Group) format
        var tokenEntries: [String: Any] = [:]

        for (index, color) in colors.enumerated() {
            let key = "color-\(index + 1)"
            tokenEntries[key] = [
                "$value": formatColor(color),
                "$type": "color"
            ] as [String: Any]
        }

        let output: [String: Any] = [
            "color": tokenEntries
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }

    private func formatTOML(colors: [ExtractedColor], source: String) -> String {
        var output = "source = \"\(source)\"\n"
        output += "count = \(colors.count)\n\n"

        for (index, color) in colors.enumerated() {
            output += "[[colors]]\n"
            output += "original = \"\(color.original)\"\n"
            output += "format = \"\(color.format.rawValue)\"\n"
            output += "normalized = \"\(color.normalized)\"\n"
            output += "converted = \"\(formatColor(color))\"\n"
            if index < colors.count - 1 {
                output += "\n"
            }
        }

        return output
    }

    private func formatClean(colors: [ExtractedColor]) -> String {
        return colors.map { formatColor($0) }.joined(separator: "\n")
    }

    // MARK: - Color Format Conversion

    private func formatColor(_ color: ExtractedColor) -> String {
        guard let targetFormat = colorFormat else {
            return color.normalized
        }

        switch targetFormat {
        case .hex:
            return convertToHex(color)
        case .rgb:
            return convertToRGB(color, withAlpha: false)
        case .rgba:
            return convertToRGB(color, withAlpha: true)
        case .hsl:
            return convertToHSL(color, withAlpha: false)
        case .hsla:
            return convertToHSL(color, withAlpha: true)
        case .oklch:
            return convertToOKLCH(color)
        case .hwb:
            return convertToHWB(color)
        case .lch:
            return convertToLCH(color)
        case .lab:
            return convertToLAB(color)
        case .oklab:
            return convertToOKLAB(color)
        case .swiftUIColor:
            return convertToSwiftUIColor(color)
        case .uiColor:
            return convertToUIColor(color)
        case .cgColor:
            return convertToCGColor(color)
        }
    }

    private func convertToHex(_ color: ExtractedColor) -> String {
        return color.normalized
    }

    private func convertToRGB(_ color: ExtractedColor, withAlpha: Bool) -> String {
        // Parse hex to RGB
        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        if withAlpha, let alpha = hexColor.alpha {
            let alphaValue = Double(alpha) / 255.0
            return String(format: "rgba(%d, %d, %d, %.2f)", hexColor.red, hexColor.green, hexColor.blue, alphaValue)
        } else {
            return String(format: "rgb(%d, %d, %d)", hexColor.red, hexColor.green, hexColor.blue)
        }
    }

    private func convertToHSL(_ color: ExtractedColor, withAlpha: Bool) -> String {
        // Parse hex to RGB first, then to HSL
        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        let r = Double(hexColor.red) / 255.0
        let g = Double(hexColor.green) / 255.0
        let b = Double(hexColor.blue) / 255.0

        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal

        var h: Double = 0
        var s: Double = 0
        let l = (maxVal + minVal) / 2.0

        if delta != 0 {
            s = l < 0.5 ? delta / (maxVal + minVal) : delta / (2.0 - maxVal - minVal)

            if maxVal == r {
                h = ((g - b) / delta) + (g < b ? 6 : 0)
            } else if maxVal == g {
                h = ((b - r) / delta) + 2
            } else {
                h = ((r - g) / delta) + 4
            }
            h /= 6
        }

        let hDeg = Int(h * 360)
        let sPercent = Int(s * 100)
        let lPercent = Int(l * 100)

        if withAlpha, let alpha = hexColor.alpha {
            let alphaValue = Double(alpha) / 255.0
            return String(format: "hsla(%d, %d%%, %d%%, %.2f)", hDeg, sPercent, lPercent, alphaValue)
        } else {
            return String(format: "hsl(%d, %d%%, %d%%)", hDeg, sPercent, lPercent)
        }
    }

    private func convertToOKLCH(_ color: ExtractedColor) -> String {
        // If already OKLCH, return as-is
        if color.format == .oklch || color.format == .oklcha {
            return color.normalized
        }

        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        let r = Double(hexColor.red) / 255.0
        let g = Double(hexColor.green) / 255.0
        let b = Double(hexColor.blue) / 255.0

        // Convert RGB -> OKLAB -> OKLCH
        let oklab = ColorSpaceConverter.rgbToOKLAB(r: r, g: g, b: b)
        let oklch = ColorSpaceConverter.oklabToOKLCH(l: oklab.l, a: oklab.a, b: oklab.b)

        if let alpha = hexColor.alpha {
            let alphaValue = Double(alpha) / 255.0
            return String(format: "oklch(%.2f%% %.4f %.2f / %.2f)",
                         oklch.l * 100, oklch.c, oklch.h, alphaValue)
        } else {
            return String(format: "oklch(%.2f%% %.4f %.2f)",
                         oklch.l * 100, oklch.c, oklch.h)
        }
    }

    private func convertToHWB(_ color: ExtractedColor) -> String {
        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        let r = Double(hexColor.red) / 255.0
        let g = Double(hexColor.green) / 255.0
        let b = Double(hexColor.blue) / 255.0

        let hwb = ColorSpaceConverter.rgbToHWB(r: r, g: g, b: b)

        let h = Int(hwb.h.rounded())
        let w = Int((hwb.w * 100).rounded())
        let bl = Int((hwb.b * 100).rounded())

        if let alpha = hexColor.alpha {
            let alphaValue = Double(alpha) / 255.0
            return String(format: "hwb(%d %d%% %d%% / %.2f)", h, w, bl, alphaValue)
        } else {
            return String(format: "hwb(%d %d%% %d%%)", h, w, bl)
        }
    }

    private func convertToLCH(_ color: ExtractedColor) -> String {
        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        let r = Double(hexColor.red) / 255.0
        let g = Double(hexColor.green) / 255.0
        let b = Double(hexColor.blue) / 255.0

        // Convert RGB -> XYZ -> LAB -> LCH
        let xyz = ColorSpaceConverter.rgbToXYZ(r: r, g: g, b: b)
        let lab = ColorSpaceConverter.xyzToLAB(x: xyz.x, y: xyz.y, z: xyz.z)
        let lch = ColorSpaceConverter.labToLCH(l: lab.l, a: lab.a, b: lab.b)

        if let alpha = hexColor.alpha {
            let alphaValue = Double(alpha) / 255.0
            return String(format: "lch(%.2f%% %.2f %.2f / %.2f)",
                         lch.l, lch.c, lch.h, alphaValue)
        } else {
            return String(format: "lch(%.2f%% %.2f %.2f)", lch.l, lch.c, lch.h)
        }
    }

    private func convertToLAB(_ color: ExtractedColor) -> String {
        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        let r = Double(hexColor.red) / 255.0
        let g = Double(hexColor.green) / 255.0
        let b = Double(hexColor.blue) / 255.0

        // Convert RGB -> XYZ -> LAB
        let xyz = ColorSpaceConverter.rgbToXYZ(r: r, g: g, b: b)
        let lab = ColorSpaceConverter.xyzToLAB(x: xyz.x, y: xyz.y, z: xyz.z)

        if let alpha = hexColor.alpha {
            let alphaValue = Double(alpha) / 255.0
            return String(format: "lab(%.2f%% %.2f %.2f / %.2f)",
                         lab.l, lab.a, lab.b, alphaValue)
        } else {
            return String(format: "lab(%.2f%% %.2f %.2f)", lab.l, lab.a, lab.b)
        }
    }

    private func convertToOKLAB(_ color: ExtractedColor) -> String {
        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        let r = Double(hexColor.red) / 255.0
        let g = Double(hexColor.green) / 255.0
        let b = Double(hexColor.blue) / 255.0

        let oklab = ColorSpaceConverter.rgbToOKLAB(r: r, g: g, b: b)

        if let alpha = hexColor.alpha {
            let alphaValue = Double(alpha) / 255.0
            return String(format: "oklab(%.4f %.4f %.4f / %.2f)",
                         oklab.l, oklab.a, oklab.b, alphaValue)
        } else {
            return String(format: "oklab(%.4f %.4f %.4f)", oklab.l, oklab.a, oklab.b)
        }
    }

    private func convertToSwiftUIColor(_ color: ExtractedColor) -> String {
        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        let r = Double(hexColor.red) / 255.0
        let g = Double(hexColor.green) / 255.0
        let b = Double(hexColor.blue) / 255.0

        if let alpha = hexColor.alpha {
            let a = Double(alpha) / 255.0
            return String(format: "Color(red: %.3f, green: %.3f, blue: %.3f, opacity: %.3f)", r, g, b, a)
        } else {
            return String(format: "Color(red: %.3f, green: %.3f, blue: %.3f)", r, g, b)
        }
    }

    private func convertToUIColor(_ color: ExtractedColor) -> String {
        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        let r = Double(hexColor.red) / 255.0
        let g = Double(hexColor.green) / 255.0
        let b = Double(hexColor.blue) / 255.0

        if let alpha = hexColor.alpha {
            let a = Double(alpha) / 255.0
            return String(format: "UIColor(red: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", r, g, b, a)
        } else {
            return String(format: "UIColor(red: %.3f, green: %.3f, blue: %.3f, alpha: 1.0)", r, g, b)
        }
    }

    private func convertToCGColor(_ color: ExtractedColor) -> String {
        guard let hexColor = ColorParser.parseHex(color.normalized) else {
            return color.normalized
        }

        let r = Double(hexColor.red) / 255.0
        let g = Double(hexColor.green) / 255.0
        let b = Double(hexColor.blue) / 255.0

        if let alpha = hexColor.alpha {
            let a = Double(alpha) / 255.0
            return String(format: "CGColor(red: %.3f, green: %.3f, blue: %.3f, alpha: %.3f)", r, g, b, a)
        } else {
            return String(format: "CGColor(red: %.3f, green: %.3f, blue: %.3f, alpha: 1.0)", r, g, b)
        }
    }
}
