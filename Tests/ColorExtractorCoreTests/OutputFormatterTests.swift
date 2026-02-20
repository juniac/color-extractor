import XCTest
@testable import ColorExtractorCore

@available(macOS 13.0, iOS 16.0, *)
final class OutputFormatterTests: XCTestCase {
    func testSVGOutputIncludesSquareSwatchesAndColorLabels() {
        let formatter = OutputFormatter(format: .svg)
        let colors = [
            ExtractedColor(original: "#FF0000", format: .hex, normalized: "#FF0000"),
            ExtractedColor(original: "#00FF00", format: .hex, normalized: "#00FF00")
        ]

        let output = formatter.format(colors: colors, source: "stdin")

        XCTAssertTrue(output.contains("<svg"))
        XCTAssertTrue(output.contains("<rect"))
        XCTAssertTrue(output.contains("#FF0000"))
        XCTAssertTrue(output.contains("#00FF00"))
        XCTAssertTrue(output.contains("width=\"120\""))
        XCTAssertTrue(output.contains("height=\"120\""))
        XCTAssertTrue(output.contains("height=\"28\" fill=\"#FFFFFF\""))
    }

    func testSVGOutputSortsSimilarColorsNearby() {
        let formatter = OutputFormatter(format: .svg)
        let colors = [
            ExtractedColor(original: "#0033FF", format: .hex, normalized: "#0033FF"),
            ExtractedColor(original: "#AA1111", format: .hex, normalized: "#AA1111"),
            ExtractedColor(original: "#FF0000", format: .hex, normalized: "#FF0000")
        ]

        let output = formatter.format(colors: colors, source: "stdin")

        let firstRed = output.range(of: "#FF0000")
        let secondRed = output.range(of: "#AA1111")
        let blue = output.range(of: "#0033FF")

        XCTAssertNotNil(firstRed)
        XCTAssertNotNil(secondRed)
        XCTAssertNotNil(blue)

        let firstIndex = firstRed!.lowerBound
        let secondIndex = secondRed!.lowerBound
        let blueIndex = blue!.lowerBound

        XCTAssertTrue(secondIndex < blueIndex || firstIndex < blueIndex)
    }
}
