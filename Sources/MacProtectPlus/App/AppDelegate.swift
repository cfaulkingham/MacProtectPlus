import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let quickActionCompressor = QuickActionCompressor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()

        if QuickActionArguments.fileURLs() == nil {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        runQuickAction(with: urls, terminateWhenFinished: false)
    }

    @objc(protectFiles:userData:error:)
    func protectFiles(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        let urls = PasteboardFileReader.fileURLs(from: pasteboard)

        guard !urls.isEmpty else {
            error.pointee = "MacProtectPlus did not receive any files from Finder." as NSString
            return
        }

        runQuickAction(with: urls, terminateWhenFinished: true)
    }

    func runQuickAction(with urls: [URL], terminateWhenFinished: Bool) {
        if terminateWhenFinished {
            hideApplicationWindows()
        }

        NSApp.activate(ignoringOtherApps: true)
        quickActionCompressor.run(
            urls: urls,
            terminateWhenFinished: terminateWhenFinished
        )
    }

    private func hideApplicationWindows() {
        for window in NSApp.windows where window.isVisible {
            window.orderOut(nil)
        }
    }
}
