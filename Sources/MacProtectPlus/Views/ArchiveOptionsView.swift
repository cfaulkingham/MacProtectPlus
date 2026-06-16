import SwiftUI

struct ArchiveOptionsView: View {
    @EnvironmentObject private var model: ArchiveViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Password")
                    .font(.headline)

                SecureField("Password", text: $model.password)
                    .textFieldStyle(.roundedBorder)

                SecureField("Confirm Password", text: $model.confirmedPassword)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Output")
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(model.outputURL?.path ?? "No destination")
                        .font(.callout)
                        .foregroundStyle(model.outputURL == nil ? .secondary : .primary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        model.showSavePanel()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("Choose destination")
                }
            }

            Divider()

            StatusView()
                .environmentObject(model)

            Spacer()
        }
        .padding(18)
        .background(.regularMaterial)
    }
}
