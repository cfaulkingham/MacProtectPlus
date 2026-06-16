import AppKit
import Foundation

@MainActor
enum PasswordPrompt {
    static func requestPassword(itemCount: Int) -> String? {
        var validationMessage: String?

        while true {
            let alert = NSAlert()
            alert.messageText = "Protect as DMG"
            alert.informativeText = validationMessage ?? itemSummary(itemCount)
            alert.alertStyle = validationMessage == nil ? .informational : .warning
            alert.addButton(withTitle: "Create DMG")
            alert.addButton(withTitle: "Cancel")

            let form = passwordForm()
            alert.accessoryView = form.view

            alert.layout()
            alert.window.initialFirstResponder = form.passwordField
            alert.window.makeFirstResponder(form.passwordField)

            guard alert.runModal() == .alertFirstButtonReturn else {
                return nil
            }

            let password = form.passwordField.stringValue
            let confirmation = form.confirmField.stringValue

            if password.isEmpty {
                validationMessage = "Enter a password."
            } else if password != confirmation {
                validationMessage = "Passwords do not match."
            } else {
                return password
            }
        }
    }

    private static func passwordForm() -> (
        view: NSView,
        passwordField: NSSecureTextField,
        confirmField: NSSecureTextField
    ) {
        let width: CGFloat = 320
        let labelHeight: CGFloat = 16
        let fieldHeight: CGFloat = 24
        let labelGap: CGFloat = 4
        let rowGap: CGFloat = 10
        let height = (labelHeight + labelGap + fieldHeight) * 2 + rowGap

        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        let passwordLabel = label("Password")
        let confirmLabel = label("Confirm Password")
        let passwordField = secureField()
        let confirmField = secureField()

        let confirmFieldY: CGFloat = 0
        let confirmLabelY = confirmFieldY + fieldHeight + labelGap
        let passwordFieldY = confirmLabelY + labelHeight + rowGap
        let passwordLabelY = passwordFieldY + fieldHeight + labelGap

        passwordLabel.frame = NSRect(x: 0, y: passwordLabelY, width: width, height: labelHeight)
        passwordField.frame = NSRect(x: 0, y: passwordFieldY, width: width, height: fieldHeight)
        confirmLabel.frame = NSRect(x: 0, y: confirmLabelY, width: width, height: labelHeight)
        confirmField.frame = NSRect(x: 0, y: confirmFieldY, width: width, height: fieldHeight)

        passwordField.nextKeyView = confirmField
        confirmField.nextKeyView = passwordField

        view.addSubview(passwordLabel)
        view.addSubview(passwordField)
        view.addSubview(confirmLabel)
        view.addSubview(confirmField)
        return (view, passwordField, confirmField)
    }

    private static func label(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        field.textColor = .secondaryLabelColor
        return field
    }

    private static func secureField() -> NSSecureTextField {
        let field = NSSecureTextField(frame: .zero)
        field.bezelStyle = .roundedBezel
        field.isEditable = true
        field.isSelectable = true
        field.lineBreakMode = .byTruncatingTail
        return field
    }

    private static func itemSummary(_ itemCount: Int) -> String {
        itemCount == 1
            ? "Enter a password for the selected item."
            : "Enter a password for \(itemCount) selected items."
    }
}
