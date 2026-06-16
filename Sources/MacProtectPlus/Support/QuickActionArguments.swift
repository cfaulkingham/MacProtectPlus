import Foundation

enum QuickActionArguments {
    private static let flag = "--quick-action"

    static func fileURLs(arguments: [String] = CommandLine.arguments) -> [URL]? {
        guard let flagIndex = arguments.firstIndex(of: flag) else {
            return nil
        }

        let paths = arguments.dropFirst(flagIndex + 1)
        let urls = paths
            .map { URL(fileURLWithPath: $0).standardizedFileURL }
            .filter { FileManager.default.fileExists(atPath: $0.path) }

        return urls.isEmpty ? nil : urls
    }
}
