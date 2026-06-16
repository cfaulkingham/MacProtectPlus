import Foundation

enum QuickArchiveDestination {
    static func outputURL(for sourceURLs: [URL]) -> URL {
        let directory = sourceURLs.first?.deletingLastPathComponent()
            ?? FileManager.default.homeDirectoryForCurrentUser

        let filename: String
        if sourceURLs.count == 1, let sourceURL = sourceURLs.first {
            filename = "\(sourceURL.deletingPathExtension().lastPathComponent).protected.dmg"
        } else {
            filename = "Archive.protected.dmg"
        }

        return availableURL(
            in: directory,
            filename: filename
        )
    }

    private static func availableURL(in directory: URL, filename: String) -> URL {
        let requestedURL = directory.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: requestedURL.path) else {
            return requestedURL
        }

        let requestedName = requestedURL.deletingPathExtension().lastPathComponent
        let requestedExtension = requestedURL.pathExtension
        var index = 2

        while true {
            let candidateName = requestedExtension.isEmpty
                ? "\(requestedName) \(index)"
                : "\(requestedName) \(index).\(requestedExtension)"
            let candidateURL = directory.appendingPathComponent(candidateName)

            if !FileManager.default.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }

            index += 1
        }
    }
}
