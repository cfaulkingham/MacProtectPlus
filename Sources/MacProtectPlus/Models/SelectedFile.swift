import Foundation

struct SelectedFile: Identifiable, Hashable, Sendable {
    let url: URL

    var id: String { url.standardizedFileURL.path }
    var name: String { url.lastPathComponent }
    var parentPath: String { url.deletingLastPathComponent().path }
    var isDirectory: Bool { FileMetadata.isDirectory(url) }
    var kindText: String { isDirectory ? "Folder" : "File" }
    var sizeText: String {
        guard !isDirectory, let size = FileMetadata.fileSize(url) else {
            return "-"
        }

        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
