# ColorExtractor

Extract and deduplicate color values from text and files. CLI tool + Swift Package library.

> Notes, text files, JSON, and source code—this is intended to extract randomly scattered color patterns, collect them, and organize them.
> In a VSCode-compatible IDE, I created this because I was exhausted from manually copying theme colors from settings.json to reuse elsewhere.


## Features

- **Extraction**: Hex, RGB, RGBA, HSL, HSLA, OKLCH, HWB, LAB, LCH, OKLAB
- **Deduplication**: Normalize and merge equivalent colors across formats
- **Conversion**: RGB, HSL, HWB, LAB, LCH, OKLAB, OKLCH, SwiftUI, UIColor, CGColor
- **Output**: Standard, JSON, TOML, clean (one-per-line)
- **Platforms**: macOS 13.0+, iOS 16.0+

## Supported Color Formats

| Format           | Example                            |
| ---------------- | ---------------------------------- |
| Hex (short)      | `#RGB` → `#F00`                    |
| Hex (standard)   | `#RRGGBB` → `#FF5733`              |
| Hex (with alpha) | `#RRGGBBAA` → `#FF5733AA`          |
| RGB              | `rgb(255, 87, 51)`                 |
| RGBA             | `rgba(255, 87, 51, 0.5)`           |
| HSL              | `hsl(9, 100%, 60%)`                |
| HSLA             | `hsla(9, 100%, 60%, 0.8)`          |
| OKLCH            | `oklch(62.8% 0.25768 29.23)`       |
| OKLCHA           | `oklch(62.8% 0.25768 29.23 / 0.5)` |

## Installation

### CLI Tool

```bash
swift build -c release
cp .build/release/color-extractor /usr/local/bin/
```

### Swift Package

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/juniac/color-extractor", from: "1.0.0")
]
```

Add `ColorExtractorCore` to your target dependencies.

## Usage

### CLI Examples

**Extract from stdin:**

```bash
echo "Primary: #FF5733, Secondary: rgb(100, 200, 50)" | color-extractor
```

**Extract from files:**

```bash
color-extractor style.css
color-extractor index.html style.css theme.scss
```

**Extract from pipe:**

```bash
cat README.md | color-extractor
```

**Show help:**

```bash
color-extractor --help
color-extractor -h
```

### Output Formats

**JSON output:**

```bash
color-extractor --output json style.css
```

Output:

```json
{
  "color": {
    "color-1": {
      "$value": "#FF5733",
      "$type": "color"
    },
    "color-2": {
      "$value": "#64C832",
      "$type": "color"
    }
  }
}
```

Follows the [Design Tokens (DTCG)](https://design-tokens.github.io/community-group/format/) format, compatible with Figma and Style Dictionary.

**TOML output:**

```bash
color-extractor --output toml style.css
```

**Clean output (colors only):**

```bash
color-extractor --output clean style.css
```

Output:

```
#FF5733
#64C832
#65CC65
```

### Color Format Conversion

**Convert to RGB:**

```bash
echo "#FF5733" | color-extractor --format rgb --output clean
# Output: rgb(255, 87, 51)
```

**Convert to HSL:**

```bash
echo "#FF5733" | color-extractor --format hsl --output clean
# Output: hsl(10, 100%, 60%)
```

**Convert to SwiftUI Color:**

```bash
echo "#FF5733" | color-extractor --format swiftui --output clean
# Output: Color(red: 1.000, green: 0.341, blue: 0.200)
```

**Convert to UIColor:**

```bash
echo "#FF5733" | color-extractor --format uicolor --output clean
# Output: UIColor(red: 1.000, green: 0.341, blue: 0.200, alpha: 1.0)
```

**Available formats:**

_Basic Formats:_

- `hex` - Hexadecimal (#RRGGBB, #RRGGBBAA)
- `rgb` / `rgba` - RGB color notation
- `hsl` / `hsla` - HSL (Hue, Saturation, Lightness)

_Advanced Color Spaces:_

- `hwb` - HWB (Hue, Whiteness, Blackness)
- `lab` - CIE LAB color space
- `lch` - CIE LCH (LAB in polar coordinates)
- `oklab` - OKLAB color space (perceptually uniform)
- `oklch` - OKLCH (OKLAB in polar coordinates)

_Swift/iOS/macOS Formats:_

- `swiftui` - SwiftUI Color syntax
- `uicolor` - UIKit UIColor syntax
- `cgcolor` - Core Graphics CGColor syntax

### Save to File

```bash
color-extractor --output-file colors.txt style.css
color-extractor --output json --output-file colors.json style.css
```

### Advanced Color Space Conversions

**Convert to OKLCH (perceptually uniform):**

```bash
echo "#FF5733" | color-extractor --format oklch --output clean
# Output: oklch(68.04% 0.2100 33.69)
```

**Convert to LAB:**

```bash
echo "#FF5733" | color-extractor --format lab --output clean
# Output: lab(60.18% 62.06 54.34)
```

**Convert to HWB:**

```bash
echo "#FF5733" | color-extractor --format hwb --output clean
# Output: hwb(11 20% 0%)
```

**All formats comparison:**

```bash
# Extract from file and show in all formats
for format in hex rgb hsl hwb lab lch oklab oklch; do
  echo "=== $format ==="
  color-extractor --format $format --output clean colors.css
done
```

### Combine Options

```bash
# Extract colors, convert to SwiftUI format, output as JSON, save to file
color-extractor --format swiftui --output json --output-file colors.json style.css

# Extract from multiple files, convert to OKLCH, clean output
color-extractor --format oklch --output clean *.css

# Convert theme colors to LAB color space for color science work
color-extractor --format lab --output json theme.json
```

### Swift Library Examples

```swift
import ColorExtractorCore

let extractor = ColorExtractorEngine()

// Extract from string
let text = "Button color is #007bff and text is rgb(255, 255, 255)"
let colors = extractor.extract(from: text)

for color in colors {
    print("\(color.original) [\(color.format)] -> \(color.normalized)")
}

// Extract from multiple lines
let lines = [
    "Primary: #FF0000",
    "Secondary: rgb(0, 255, 0)",
    "Accent: hsl(240, 100%, 50%)"
]
let allColors = extractor.extract(from: lines)
```

## Output

Default output shows:

- **Original format**: Color value as found in source
- **Format type**: Detected color format (hex, rgb, hsl, etc.)
- **Normalized representation**: Canonical form for deduplication

Example:

```
Found 4 unique color(s) in stdin:

1. #FF5733 [hex] -> #FF5733
2. rgb(100, 200, 50) [rgb] -> #64C832
3. hsl(120, 50%, 60%) [hsl] -> #65CC65
4. oklch(70% 0.2 180) [oklch] -> oklch(70.00% 0.2000 180.00)
```

## Color Spaces

### RGB/Hex

Standard web colors, device-dependent. Used in CSS, HTML, and most graphics software.

### HSL/HWB

Designer-friendly representations using hue, saturation, and lightness (or whiteness/blackness).

### LAB/LCH

Perceptually uniform, device-independent color spaces (CIE standard). Used for color difference calculations and scientific applications.

### OKLAB/OKLCH

Modern perceptually uniform color spaces with improved uniformity over LAB. Recommended for color manipulation, gradients, and accessibility calculations.

### SwiftUI/UIColor/CGColor

Native Swift color formats for direct integration with iOS/macOS development.

## Deduplication

Colors are automatically deduplicated by:

- Converting to canonical representation (Hex/RGB/HSL → Hex, OKLCH → OKLCH)
- Case-insensitive comparison
- Recognizing equivalent formats (e.g., `#FFF` == `#FFFFFF`, `#FF5733` == `rgb(255, 87, 51)`)

Example:

```bash
echo "#FF5733 #ff5733 rgb(255, 87, 51)" | color-extractor
# Output: Found 1 unique color
```

## Development

```bash
# Build
swift build

# Run during development
swift run color-extractor [arguments]

# Run tests
swift test

# Clean build artifacts
swift package clean
```

## Architecture

```
Sources/
  ColorExtractorCore/   # Library (platform-agnostic)
    - Color models, regex patterns
    - Parsing, normalization, deduplication
    - Color space conversions (RGB, XYZ, LAB, LCH, OKLAB, OKLCH, HWB, HSL)
  ColorExtractor/       # CLI executable
    - ArgumentParser integration
    - File I/O, stdin handling
    - Output formatting (standard, JSON, TOML, clean)
```

## Requirements

- Swift 6.2+
- macOS 13.0+ / iOS 16.0+
