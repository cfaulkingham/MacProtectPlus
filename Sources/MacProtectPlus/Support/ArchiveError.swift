import Foundation

enum ArchiveError: LocalizedError {
    case noInput
    case missingPassword
    case dmgFailed(String)
    case missingOutput

    var errorDescription: String? {
        switch self {
        case .noInput:
            "No files were selected."
        case .missingPassword:
            "Enter a password before creating the archive."
        case .dmgFailed(let output):
            output.isEmpty
                ? "hdiutil failed while creating the DMG."
                : "hdiutil failed: \(output)"
        case .missingOutput:
            "hdiutil finished without creating a DMG."
        }
    }
}
