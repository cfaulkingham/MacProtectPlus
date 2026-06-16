import AppKit
import Foundation

let app = NSApplication.shared
let delegate = InstallerApp()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

@MainActor
final class InstallerApp: NSObject, NSApplicationDelegate {
    private let appName = "MacProtectPlus"
    private let oldSystemAppPath = "/Applications/MacProtectPlus.app"
    private let launchServicesRegisterPath = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

    private var applicationsDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
    }

    private var installedAppURL: URL {
        applicationsDirectoryURL
            .appendingPathComponent("\(appName).app", isDirectory: true)
    }

    private var installedAppPath: String {
        installedAppURL.path
    }

    private var userWorkflowPath: String {
        "\(NSHomeDirectory())/Library/Services/MacProtectPlus.workflow"
    }

    private var userWorkflowNamePath: String {
        "\(NSHomeDirectory())/Library/Services/Protect as DMG.workflow"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        runInstallerFlow()
        NSApp.terminate(nil)
    }

    private func runInstallerFlow() {
        guard let payloadApp = payloadAppURL() else {
            showAlert(
                title: "MacProtectPlus Installer",
                message: "The installer payload is missing from this app.",
                style: .critical
            )
            return
        }

        let isInstalled = FileManager.default.fileExists(atPath: installedAppPath)
            || FileManager.default.fileExists(atPath: oldSystemAppPath)
            || FileManager.default.fileExists(atPath: userWorkflowPath)
            || FileManager.default.fileExists(atPath: userWorkflowNamePath)

        if isInstalled {
            let choice = chooseAction(
                message: "MacProtectPlus is already installed, or a partial install was found.",
                details: "Choose Reinstall to repair/update the current user's app and Finder Service, or Uninstall to remove them.",
                buttons: ["Reinstall", "Uninstall", "Cancel"]
            )

            switch choice {
            case "Reinstall":
                install(payloadApp)
            case "Uninstall":
                uninstall()
            default:
                return
            }
        } else {
            let choice = chooseAction(
                message: "Install MacProtectPlus and its Finder Service?",
                details: "MacProtectPlus will be installed for the current user in ~/Applications.",
                buttons: ["Install", "Cancel"]
            )

            if choice == "Install" {
                install(payloadApp)
            }
        }
    }

    private func payloadAppURL() -> URL? {
        guard let resourcesURL = Bundle.main.resourceURL else {
            return nil
        }

        let payloadURL = resourcesURL.appendingPathComponent("Payload", isDirectory: true)
        let appURL = payloadURL.appendingPathComponent("MacProtectPlus.app", isDirectory: true)

        guard FileManager.default.fileExists(atPath: appURL.path) else {
            return nil
        }

        return appURL
    }

    private func chooseAction(message: String, details: String, buttons: [String]) -> String {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = details
        alert.alertStyle = .informational

        for button in buttons {
            alert.addButton(withTitle: button)
        }

        let response = alert.runModal()
        let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue

        guard index >= 0, index < buttons.count else {
            return "Cancel"
        }

        return buttons[index]
    }

    private func install(_ payloadApp: URL) {
        do {
            try FileManager.default.createDirectory(
                at: applicationsDirectoryURL,
                withIntermediateDirectories: true
            )

            terminateMacProtectPlusIfNeeded()
            unregisterServices(paths: [
                installedAppPath,
                oldSystemAppPath,
                userWorkflowPath,
                userWorkflowNamePath
            ])

            try removeItemIfExists(at: installedAppURL)
            try removeItemIfExists(at: URL(fileURLWithPath: userWorkflowPath))
            try removeItemIfExists(at: URL(fileURLWithPath: userWorkflowNamePath))

            try copyItem(from: payloadApp, to: installedAppURL)
            registerService(at: installedAppPath)
            refreshServices()

            showAlert(
                title: "MacProtectPlus Installer",
                message: "MacProtectPlus is installed.",
                details: "Installed to \(installedAppPath).\n\nIn Finder, right-click a file or folder and choose Services > Protect as DMG."
            )
        } catch {
            showAlert(
                title: "Install Failed",
                message: error.localizedDescription,
                style: .critical
            )
        }
    }

    private func uninstall() {
        let choice = chooseAction(
            message: "Remove MacProtectPlus from this Mac?",
            details: "This removes the current user's app and Finder Service registration.",
            buttons: ["Uninstall", "Cancel"]
        )

        guard choice == "Uninstall" else {
            return
        }

        do {
            let localBuildAppPath = Bundle.main.bundleURL
                .deletingLastPathComponent()
                .appendingPathComponent("MacProtectPlus.app", isDirectory: true)
                .path

            terminateMacProtectPlusIfNeeded()
            unregisterServices(paths: [
                installedAppPath,
                oldSystemAppPath,
                localBuildAppPath,
                userWorkflowPath,
                userWorkflowNamePath
            ])

            try removeItemIfExists(at: installedAppURL)
            try removeItemIfExists(at: URL(fileURLWithPath: userWorkflowPath))
            try removeItemIfExists(at: URL(fileURLWithPath: userWorkflowNamePath))
            refreshServices()

            showAlert(title: "MacProtectPlus Installer", message: "MacProtectPlus was uninstalled.")
        } catch {
            showAlert(
                title: "Uninstall Failed",
                message: error.localizedDescription,
                style: .critical
            )
        }
    }

    private func copyItem(from sourceURL: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["--norsrc", sourceURL.path, destinationURL.path]
        process.environment = ["COPYFILE_DISABLE": "1"]
        try run(process)
    }

    private func removeItemIfExists(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        try FileManager.default.removeItem(at: url)
    }

    private func terminateMacProtectPlusIfNeeded() {
        try? runCommand("/usr/bin/pkill", arguments: ["-x", appName], allowFailure: true)
    }

    private func unregisterServices(paths: [String]) {
        guard FileManager.default.isExecutableFile(atPath: launchServicesRegisterPath) else {
            return
        }

        for path in paths {
            try? runCommand(launchServicesRegisterPath, arguments: ["-u", path], allowFailure: true)
        }
    }

    private func registerService(at path: String) {
        guard FileManager.default.isExecutableFile(atPath: launchServicesRegisterPath) else {
            return
        }

        try? runCommand(launchServicesRegisterPath, arguments: ["-f", path], allowFailure: true)
    }

    private func refreshServices() {
        try? runCommand("/System/Library/CoreServices/pbs", arguments: ["-flush"], allowFailure: true)
        try? runCommand("/System/Library/CoreServices/pbs", arguments: ["-update", "English"], allowFailure: true)
        try? runCommand("/usr/bin/killall", arguments: ["Finder"], allowFailure: true)
    }

    private func runCommand(
        _ executablePath: String,
        arguments: [String],
        allowFailure: Bool = false
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        try run(process, allowFailure: allowFailure)
    }

    private func run(_ process: Process, allowFailure: Bool = false) throws {
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard allowFailure || process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw InstallerError.commandFailed(message?.isEmpty == false ? message! : "The command failed.")
        }
    }

    private func showAlert(
        title: String,
        message: String,
        details: String = "",
        style: NSAlert.Style = .informational
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = details.isEmpty ? message : "\(message)\n\n\(details)"
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

private enum InstallerError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            message
        }
    }
}
