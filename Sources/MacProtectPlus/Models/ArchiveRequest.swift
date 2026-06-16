import Foundation

struct ArchiveRequest: Sendable {
    let sourceURLs: [URL]
    let outputURL: URL
    let password: String
}
