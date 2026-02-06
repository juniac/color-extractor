import XCTest
@testable import ColorExtractorCore

final class ColorExtractorTests: XCTestCase {
    var extractor: ColorExtractorEngine!

    override func setUp() {
        super.setUp()
        extractor = ColorExtractorEngine()
    }

    // MARK: - Hex Color Tests

    func testExtractSimpleHexColor() {
        let text = "Background color is #FF5733"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].original, "#FF5733")
        XCTAssertEqual(colors[0].format, .hex)
        XCTAssertEqual(colors[0].normalized, "#FF5733")
    }

    func testExtractShortHexColor() {
        let text = "Color: #F00"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].original, "#F00")
        XCTAssertEqual(colors[0].normalized, "#FF0000")
    }

    func testExtractHexColorWithAlpha() {
        let text = "Transparent: #FF5733AA"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].original, "#FF5733AA")
        XCTAssertEqual(colors[0].normalized, "#FF5733AA")
    }

    func testExtractMultipleHexColors() {
        let text = "Primary: #FF0000, Secondary: #00FF00, Accent: #0000FF"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 3)
    }

    func testHexColorCaseInsensitive() {
        let text = "Lowercase: #ff5733, Uppercase: #FF5733"
        let colors = extractor.extract(from: text)

        // Should deduplicate case-insensitive
        XCTAssertEqual(colors.count, 1)
    }

    // MARK: - RGB Color Tests

    func testExtractRGBColor() {
        let text = "Color: rgb(255, 87, 51)"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].format, .rgb)
        XCTAssertEqual(colors[0].normalized, "#FF5733")
    }

    func testExtractRGBAColor() {
        let text = "Color: rgba(255, 87, 51, 0.5)"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].format, .rgba)
    }

    func testRGBWithVariousWhitespace() {
        let text1 = "rgb(255,87,51)"
        let text2 = "rgb( 255 , 87 , 51 )"
        let text3 = "rgb(  255  ,  87  ,  51  )"

        let colors1 = extractor.extract(from: text1)
        let colors2 = extractor.extract(from: text2)
        let colors3 = extractor.extract(from: text3)

        XCTAssertEqual(colors1.count, 1)
        XCTAssertEqual(colors2.count, 1)
        XCTAssertEqual(colors3.count, 1)

        // All should normalize to same value
        XCTAssertEqual(colors1[0].normalized, colors2[0].normalized)
        XCTAssertEqual(colors2[0].normalized, colors3[0].normalized)
    }

    // MARK: - HSL Color Tests

    func testExtractHSLColor() {
        let text = "Color: hsl(9, 100%, 60%)"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].format, .hsl)
    }

    func testExtractHSLAColor() {
        let text = "Color: hsla(9, 100%, 60%, 0.8)"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].format, .hsla)
    }

    // MARK: - OKLCH Color Tests

    func testExtractOKLCHColor() {
        let text = "Color: oklch(62.8% 0.25768 29.23)"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].format, .oklch)
    }

    func testExtractOKLCHAColor() {
        let text = "Color: oklch(62.8% 0.25768 29.23 / 0.5)"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].format, .oklcha)
    }

    // MARK: - Mixed Format Tests

    func testExtractMixedFormats() {
        let text = """
        Primary: #FF5733
        Secondary: rgb(0, 255, 0)
        Accent: hsl(240, 100%, 50%)
        Special: oklch(70% 0.2 180)
        """

        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 4)

        let formats = colors.map { $0.format }
        XCTAssertTrue(formats.contains(.hex))
        XCTAssertTrue(formats.contains(.rgb))
        XCTAssertTrue(formats.contains(.hsl))
        XCTAssertTrue(formats.contains(.oklch))
    }

    // MARK: - Deduplication Tests

    func testDeduplicateIdenticalColors() {
        let text = "#FF5733 #FF5733 #FF5733"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
    }

    func testDeduplicateDifferentFormats() {
        // #FF5733 is rgb(255, 87, 51)
        let text = "Hex: #FF5733, RGB: rgb(255, 87, 51)"
        let colors = extractor.extract(from: text)

        // Should deduplicate to 1 color
        XCTAssertEqual(colors.count, 1)
    }

    func testDeduplicateShortAndLongHex() {
        let text = "#FFF #FFFFFF"
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 1)
    }

    // MARK: - Edge Cases

    func testEmptyString() {
        let colors = extractor.extract(from: "")
        XCTAssertEqual(colors.count, 0)
    }

    func testNoColorsFound() {
        let text = "This text has no color values at all."
        let colors = extractor.extract(from: text)

        XCTAssertEqual(colors.count, 0)
    }

    func testInvalidColorValues() {
        let text = """
        Invalid RGB: rgb(300, 400, 500)
        Invalid Hex: #GGGGGG
        Invalid HSL: hsl(400, 150%, 200%)
        """

        let colors = extractor.extract(from: text)

        // Should extract 0 valid colors
        XCTAssertEqual(colors.count, 0)
    }

    func testColorsInRealWorldCSS() {
        let css = """
        .button {
            background-color: #007bff;
            border-color: #007bff;
            color: #fff;
        }

        .alert {
            background: rgba(255, 0, 0, 0.1);
            border: 1px solid rgb(255, 0, 0);
        }
        """

        let colors = extractor.extract(from: css)

        XCTAssertGreaterThan(colors.count, 0)
    }

    // MARK: - Multi-line Tests

    func testExtractFromMultipleLines() {
        let lines = [
            "Line 1: #FF0000",
            "Line 2: rgb(0, 255, 0)",
            "Line 3: hsl(240, 100%, 50%)"
        ]

        let colors = extractor.extract(from: lines)

        XCTAssertEqual(colors.count, 3)
    }
}
