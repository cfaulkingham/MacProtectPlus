import Foundation

final class DMGArchiver: @unchecked Sendable {
    func createArchive(_ request: ArchiveRequest) throws -> URL {
        guard !request.sourceURLs.isEmpty else {
            throw ArchiveError.noInput
        }

        guard !request.password.isEmpty else {
            throw ArchiveError.missingPassword
        }

        let fileManager = FileManager.default
        let stagingDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("MacProtectPlus-Staging-\(UUID().uuidString)", isDirectory: true)

        let temporaryOutputDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("MacProtectPlus-\(UUID().uuidString)", isDirectory: true)
        let temporaryOutputURL = temporaryOutputDirectory
            .appendingPathComponent(request.outputURL.lastPathComponent)

        try fileManager.createDirectory(
            at: temporaryOutputDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? fileManager.removeItem(at: temporaryOutputDirectory)
            try? fileManager.removeItem(at: stagingDirectory)
        }

        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        try Self.stage(request.sourceURLs, in: stagingDirectory)
        try Self.createDiskImage(
            from: stagingDirectory,
            outputURL: temporaryOutputURL,
            volumeName: Self.volumeName(for: request.outputURL),
            password: request.password
        )

        guard fileManager.fileExists(atPath: temporaryOutputURL.path) else {
            throw ArchiveError.missingOutput
        }

        let destinationDirectory = request.outputURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: destinationDirectory,
            withIntermediateDirectories: true
        )

        if fileManager.fileExists(atPath: request.outputURL.path) {
            try fileManager.removeItem(at: request.outputURL)
        }

        try fileManager.moveItem(at: temporaryOutputURL, to: request.outputURL)
        return request.outputURL
    }

    private static func stage(_ urls: [URL], in stagingDirectory: URL) throws {
        let fileManager = FileManager.default
        var usedNames = Set<String>()

        for url in urls.map(\.standardizedFileURL) {
            let entryName = uniqueName(for: url.lastPathComponent, usedNames: &usedNames)
            let destinationURL = stagingDirectory.appendingPathComponent(entryName)
            try fileManager.copyItem(at: url, to: destinationURL)
        }
    }

    private static func createDiskImage(
        from sourceURL: URL,
        outputURL: URL,
        volumeName: String,
        password: String
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = [
            "create",
            "-format",
            "UDZO",
            "-imagekey",
            "zlib-level=9",
            "-encryption",
            "AES-256",
            "-stdinpass",
            "-volname",
            volumeName,
            "-srcfolder",
            sourceURL.path,
            outputURL.path
        ]

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        inputPipe.fileHandleForWriting.write(Data((password + "\n").utf8))
        try? inputPipe.fileHandleForWriting.close()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let output = text(from: outputPipe) + text(from: errorPipe)
            throw ArchiveError.dmgFailed(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private static func volumeName(for outputURL: URL) -> String {
        let rawName = outputURL.deletingPathExtension().lastPathComponent
        let invalidCharacters = CharacterSet(charactersIn: ":/")
        let sanitized = rawName.unicodeScalars
            .map { invalidCharacters.contains($0) ? "-" : String($0) }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let fallbackName = sanitized.isEmpty ? "Protected Files" : sanitized
        return String(fallbackName.prefix(80))
    }

    private static func text(from pipe: Pipe) -> String {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func uniqueName(for name: String, usedNames: inout Set<String>) -> String {
        let fallbackName = name.isEmpty ? "Item" : name

        if usedNames.insert(fallbackName).inserted {
            return fallbackName
        }

        let url = URL(fileURLWithPath: fallbackName)
        let stem = url.deletingPathExtension().lastPathComponent
        let pathExtension = url.pathExtension
        var index = 2

        while true {
            let candidate = pathExtension.isEmpty
                ? "\(stem) \(index)"
                : "\(stem) \(index).\(pathExtension)"

            if usedNames.insert(candidate).inserted {
                return candidate
            }

            index += 1
        }
    }
}
