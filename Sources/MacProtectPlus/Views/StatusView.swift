import SwiftUI

struct StatusView: View {
    @EnvironmentObject private var model: ArchiveViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch model.status {
            case .working:
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)

                    Text(model.status.message ?? "")
                        .foregroundStyle(.secondary)
                }
            case .success:
                Label(model.status.message ?? "", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failure:
                Label(model.status.message ?? "", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            case .idle:
                if let validationMessage = model.validationMessage {
                    Label(validationMessage, systemImage: "info.circle")
                        .foregroundStyle(.secondary)
                } else {
                    Label("Ready", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.callout)
    }
}
