import Foundation

enum CompressionStatus: Equatable {
    case idle
    case working
    case success(URL)
    case failure(String)

    var message: String? {
        switch self {
        case .idle:
            nil
        case .working:
            "Creating encrypted DMG..."
        case .success(let url):
            "Created \(url.lastPathComponent)"
        case .failure(let message):
            message
        }
    }
}
