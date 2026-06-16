import AppKit
import Foundation

enum PasteboardFileReader {
    private static let filenamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")

    static func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
        if let objects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ), !objects.isEmpty {
            return objects.compactMap { object in
                guard let nsURL = object as? NSURL, nsURL.isFileURL else {
                    return nil
                }

                return nsURL as URL
            }
        }

        if let paths = pasteboard.propertyList(forType: filenamesType) as? [String] {
            return paths.map { URL(fileURLWithPath: $0) }
        }

        return []
    }
}
