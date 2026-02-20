import Foundation
import ArgumentParser
import ColorExtractorCore

@available(macOS 13.0, iOS 16.0, *)
@main
struct ColorExtractor: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "color-extractor",
        abstract: "Extract color values from text files and strings",
        discussion: """
        Extracts and deduplicates color values from text input.
        Supports multiple color formats: Hex, RGB, HSL, OKLCH.

        EXAMPLES:
            color-extractor style.css
            echo "color: #FF5733" | color-extractor
            color-extractor --format rgb --output clean file.txt
            color-extractor --output json --format swiftui colors.css
        """,
        version: "1.0.0"
    )

    @Option(name: .long, help: "Output format: json, toml, clean, or svg")
    var output: OutputFormatOption?

    @Option(name: .long, help: ArgumentHelp(
        "Convert colors to format: hex, rgb, rgba, hsl, hsla, oklch, swiftui, uicolor, cgcolor",
        valueName: "format"
    ))
    var format: ColorFormatOption?

    @Option(name: .long, help: ArgumentHelp("Save output to file", valueName: "path"))
    var outputFile: String?

    @Argument(help: "Files to extract colors from (reads from stdin if not provided)")
    var files: [String] = []

    private var hasWrittenOutputFileInCurrentRun = false

    mutating func run() throws {

        let extractor = ColorExtractorEngine()
        let outputFormat = output?.toOutputFormat() ?? .standard
        let colorFormat = format?.toColorOutputFormat()
        let formatter = OutputFormatter(format: outputFormat, colorFormat: colorFormat)

        if files.isEmpty {
            // Read from stdin
            let input = readStdin()
            let colors = extractor.extract(from: input)
            let result = formatter.format(colors: colors, source: "stdin")
            outputResult(result)
        } else {
            // Process files
            for file in files {
                do {
                    let content = try String(contentsOfFile: file, encoding: .utf8)
                    let colors = extractor.extract(from: content)
                    let result = formatter.format(colors: colors, source: file)
                    outputResult(result)

                    // Add separator between files if processing multiple
                    if files.count > 1 && file != files.last {
                        outputResult("\n---\n")
                    }
                } catch {
                    throw ColorExtractorError.fileReadError(file, error.localizedDescription)
                }
            }
        }
    }

    private func readStdin() -> String {
        var input = ""
        while let line = readLine() {
            input += line + "\n"
        }
        return input
    }

    private mutating func outputResult(_ result: String) {
        if let outputPath = outputFile {
            do {
                let shouldAppend = hasWrittenOutputFileInCurrentRun && FileManager.default.fileExists(atPath: outputPath)

                if shouldAppend {
                    // Append to existing file
                    let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: outputPath))
                    fileHandle.seekToEndOfFile()
                    if let data = (result + "\n").data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    try fileHandle.close()
                } else {
                    try result.write(toFile: outputPath, atomically: true, encoding: .utf8)
                }

                hasWrittenOutputFileInCurrentRun = true
            } catch {
                Self.exit(withError: ColorExtractorError.fileWriteError(outputPath, error.localizedDescription))
            }
        } else {
            print(result)
        }
    }
}

// MARK: - Enums for CLI Options

enum OutputFormatOption: String, ExpressibleByArgument {
    case json
    case toml
    case clean
    case svg

    func toOutputFormat() -> OutputFormat {
        switch self {
        case .json: return .json
        case .toml: return .toml
        case .clean: return .clean
        case .svg: return .svg
        }
    }
}

enum ColorFormatOption: String, ExpressibleByArgument, CaseIterable {
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
    case swiftui
    case uicolor
    case cgcolor

    func toColorOutputFormat() -> ColorOutputFormat {
        switch self {
        case .hex: return .hex
        case .rgb: return .rgb
        case .rgba: return .rgba
        case .hsl: return .hsl
        case .hsla: return .hsla
        case .hwb: return .hwb
        case .lch: return .lch
        case .lab: return .lab
        case .oklab: return .oklab
        case .oklch: return .oklch
        case .swiftui: return .swiftUIColor
        case .uicolor: return .uiColor
        case .cgcolor: return .cgColor
        }
    }
}

// MARK: - Errors

enum ColorExtractorError: LocalizedError {
    case fileReadError(String, String)
    case fileWriteError(String, String)

    var errorDescription: String? {
        switch self {
        case .fileReadError(let path, let message):
            return "Error reading file '\(path)': \(message)"
        case .fileWriteError(let path, let message):
            return "Error writing to file '\(path)': \(message)"
        }
    }
}

// MARK: - FileHandle Extension

extension FileHandle {
    var isReadable: Bool {
        var pollfd = pollfd(fd: fileDescriptor, events: Int16(POLLIN), revents: 0)
        let result = poll(&pollfd, 1, 0)
        return result > 0
    }
}
