import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: ArchiveViewModel
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            Divider()

            HSplitView {
                SelectedFilesView(isDropTargeted: $isDropTargeted)
                    .environmentObject(model)
                    .frame(minWidth: 360)

                ArchiveOptionsView()
                    .environmentObject(model)
                    .frame(minWidth: 280)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            model.add(urls)
            return true
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                model.showOpenPanel()
            } label: {
                Label("Add", systemImage: "plus")
            }
            .help("Add files or folders")

            Button {
                model.clear()
            } label: {
                Label("Clear", systemImage: "xmark")
            }
            .disabled(model.selectedFiles.isEmpty && model.password.isEmpty)
            .help("Clear selection")

            Spacer()

            Button {
                model.compress()
            } label: {
                Label("Create DMG", systemImage: "lock.doc")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canCompress)
            .help("Create encrypted DMG")
        }
        .padding(12)
    }
}
