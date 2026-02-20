import XCTest

final class CLIOutputFileBehaviorTests: XCTestCase {
    func testSVGOutputFileIsOverwrittenOnNewRun() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let firstInput = tempDir.appendingPathComponent("first.txt")
        let secondInput = tempDir.appendingPathComponent("second.txt")
        let output = tempDir.appendingPathComponent("palette.svg")

        try "#FF0000".write(to: firstInput, atomically: true, encoding: .utf8)
        try "#00FF00".write(to: secondInput, atomically: true, encoding: .utf8)

        try runCLI(arguments: [
            "--output", "svg",
            "--output-file", output.path,
            firstInput.path
        ])

        try runCLI(arguments: [
            "--output", "svg",
            "--output-file", output.path,
            secondInput.path
        ])

        let contents = try String(contentsOf: output, encoding: .utf8)

        XCTAssertEqual(contents.components(separatedBy: "<svg").count - 1, 1)
        XCTAssertTrue(contents.contains("#00FF00"))
        XCTAssertFalse(contents.contains("#FF0000"))
    }

    private func runCLI(arguments: [String]) throws {
        let process = Process()
        let currentDirectory = FileManager.default.currentDirectoryPath
        let executablePath = currentDirectory + "/.build/debug/color-extractor"
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8) ?? "Unknown CLI failure"
            XCTFail("CLI failed: \(message)")
        }
    }
}
