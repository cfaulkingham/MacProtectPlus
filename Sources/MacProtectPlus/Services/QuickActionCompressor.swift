import AppKit
import Foundation

@MainActor
final class QuickActionCompressor {
    private let archiver = DMGArchiver()
    private var isRunning = false

    func run(urls: [URL], terminateWhenFinished: Bool) {
        guard !isRunning else {
            return
        }

        let sourceURLs = urls
            .map { $0.standardizedFileURL }
            .filter { FileManager.default.fileExists(atPath: $0.path) }

        guard !sourceURLs.isEmpty else {
            showError("MacProtectPlus did not receive any files to protect.")
            finish(terminateWhenFinished)
            return
        }

        isRunning = true

        guard let password = PasswordPrompt.requestPassword(itemCount: sourceURLs.count) else {
            finish(terminateWhenFinished)
            return
        }

        let request = ArchiveRequest(
            sourceURLs: sourceURLs,
            outputURL: QuickArchiveDestination.outputURL(for: sourceURLs),
            password: password
        )

        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try self.archiver.createArchive(request)
                }.value

                NSWorkspace.shared.activateFileViewerSelecting([result])
                finish(terminateWhenFinished)
            } catch {
                showError(error.localizedDescription)
                finish(terminateWhenFinished)
            }
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Could Not Create DMG"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func finish(_ terminate: Bool) {
        isRunning = false

        if terminate {
            NSApp.terminate(nil)
        }
    }
}
