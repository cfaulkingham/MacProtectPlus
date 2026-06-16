import SwiftUI

struct SelectedFilesView: View {
    @EnvironmentObject private var model: ArchiveViewModel
    @Binding var isDropTargeted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Files")
                    .font(.headline)

                Spacer()

                Text("\(model.selectedFiles.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding([.horizontal, .top], 18)
            .padding(.bottom, 10)

            if model.selectedFiles.isEmpty {
                DropEmptyState(isTargeted: isDropTargeted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(18)
            } else {
                List(model.selectedFiles) { file in
                    SelectedFileRow(file: file) {
                        model.remove(file)
                    }
                }
                .listStyle(.inset)
            }
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.tint, lineWidth: 2)
                    .padding(8)
            }
        }
    }
}

private struct DropEmptyState: View {
    let isTargeted: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isTargeted ? "arrow.down.doc.fill" : "tray.and.arrow.down")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(.secondary)

            Text(isTargeted ? "Release to Add" : "Drop Files Here")
                .font(.title3)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.35))
        }
    }
}

private struct SelectedFileRow: View {
    let file: SelectedFile
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: file.isDirectory ? "folder" : "doc")
                .foregroundStyle(file.isDirectory ? .blue : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .lineLimit(1)

                Text(file.parentPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 12)

            Text(file.sizeText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(minWidth: 70, alignment: .trailing)

            Button(action: onRemove) {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .help("Remove")
        }
        .padding(.vertical, 4)
    }
}
