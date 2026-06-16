import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class ArchiveViewModel: ObservableObject {
    @Published private(set) var selectedFiles: [SelectedFile] = []
    @Published var password = ""
    @Published var confirmedPassword = ""
    @Published private(set) var outputURL: URL?
    @Published private(set) var status: CompressionStatus = .idle

    private let archiver = DMGArchiver()

    var canCompress: Bool {
        validationMessage == nil && status != .working
    }

    var validationMessage: String? {
        if selectedFiles.isEmpty {
            return "Add at least one file or folder."
        }

        if password.isEmpty {
            return "Enter a password."
        }

        if password != confirmedPassword {
            return "Passwords do not match."
        }

        if outputURL == nil {
            return "Choose where to save the DMG."
        }

        return nil
    }

    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true
        panel.title = "Select Files"

        guard panel.runModal() == .OK else {
            return
        }

        add(panel.urls)
    }

    func showSavePanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "dmg") ?? .data]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = outputURL?.lastPathComponent ?? defaultArchiveName()
        panel.directoryURL = outputURL?.deletingLastPathComponent() ?? defaultOutputDirectory()
        panel.title = "Save DMG"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        outputURL = url.pathExtension.lowercased() == "dmg"
            ? url
            : url.appendingPathExtension("dmg")
    }

    func add(_ urls: [URL]) {
        let normalizedURLs = urls
            .map { $0.standardizedFileURL }
            .filter { FileManager.default.fileExists(atPath: $0.path) }

        guard !normalizedURLs.isEmpty else {
            return
        }

        var seen = Set(selectedFiles.map(\.id))
        var nextFiles = selectedFiles

        for url in normalizedURLs {
            let file = SelectedFile(url: url)
            if seen.insert(file.id).inserted {
                nextFiles.append(file)
            }
        }

        selectedFiles = nextFiles.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        outputURL = suggestedOutputURL()
        status = .idle
    }

    func replaceSelection(with urls: [URL]) {
        selectedFiles.removeAll()
        add(urls)
    }

    func remove(_ file: SelectedFile) {
        selectedFiles.removeAll { $0 == file }
        outputURL = selectedFiles.isEmpty ? nil : suggestedOutputURL()
        status = .idle
    }

    func clear() {
        selectedFiles.removeAll()
        password = ""
        confirmedPassword = ""
        outputURL = nil
        status = .idle
    }

    func compress() {
        guard canCompress, let outputURL else {
            status = .failure(validationMessage ?? "The archive is not ready.")
            return
        }

        let request = ArchiveRequest(
            sourceURLs: selectedFiles.map(\.url),
            outputURL: outputURL,
            password: password
        )

        status = .working

        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try self.archiver.createArchive(request)
                }.value

                status = .success(result)
                password = ""
                confirmedPassword = ""
                NSWorkspace.shared.activateFileViewerSelecting([result])
            } catch {
                status = .failure(error.localizedDescription)
            }
        }
    }

    private func suggestedOutputURL() -> URL? {
        guard !selectedFiles.isEmpty else {
            return nil
        }

        return defaultOutputDirectory().appendingPathComponent(defaultArchiveName())
    }

    private func defaultOutputDirectory() -> URL {
        selectedFiles.first?.url.deletingLastPathComponent()
            ?? FileManager.default.homeDirectoryForCurrentUser
    }

    private func defaultArchiveName() -> String {
        if selectedFiles.count == 1, let file = selectedFiles.first {
            let baseName = file.url.deletingPathExtension().lastPathComponent
            return "\(baseName).protected.dmg"
        }

        return "Archive.protected.dmg"
    }
}
