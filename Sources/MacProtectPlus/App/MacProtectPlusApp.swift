import SwiftUI

@main
struct MacProtectPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = ArchiveViewModel()
    private let launchQuickActionURLs = QuickActionArguments.fileURLs()

    var body: some Scene {
        WindowGroup {
            if let launchQuickActionURLs {
                QuickActionLaunchView(
                    urls: launchQuickActionURLs,
                    appDelegate: appDelegate
                )
                .frame(width: 1, height: 1)
            } else {
                ContentView()
                    .environmentObject(model)
                    .frame(minWidth: 680, minHeight: 520)
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Add Files...") {
                    model.showOpenPanel()
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button("Create DMG") {
                    model.compress()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(!model.canCompress)
            }
        }
    }
}

private struct QuickActionLaunchView: View {
    let urls: [URL]
    let appDelegate: AppDelegate
    @State private var didStart = false

    var body: some View {
        Color.clear
            .onAppear {
                guard !didStart else {
                    return
                }

                didStart = true

                DispatchQueue.main.async {
                    appDelegate.runQuickAction(
                        with: urls,
                        terminateWhenFinished: true
                    )
                }
            }
    }
}
