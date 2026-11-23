#if os(macOS)
import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
private final class EditorSelection {
    weak var view: NSTextView?

    func insert(_ text: String) {
        guard let view, view.isEditable else { return }
        view.insertText(text, replacementRange: view.selectedRange())
    }
}

public enum AttachmentInsertionSource { case paste, drop, picker }

/// A multiline macOS field with inline attachment tokens and a clickable preview strip.
public struct AttachmentTextField: View {
    private let editor: IMETextView
    private let attachments: [FieldAttachment]
    private let editorHeight: CGFloat?
    private let showsFilePicker: Bool
    private let add: (FieldAttachment, AttachmentInsertionSource) -> String?
    private let remove: (FieldAttachment) -> Void
    @State private var selection = EditorSelection()
    @State private var choosingFiles = false
    @State private var preview: FieldAttachment?

    /// The bound string contains the editable image tags. The attachment array holds their data.
    public init(text: Binding<String>, attachments: Binding<[FieldAttachment]>,
                placeholder: String = "", onSubmit: (() -> Void)? = nil) {
        self.init(editor: IMETextView(text: text, isFocused: .constant(false), hasMarkedText: .constant(false),
            font: .systemFont(ofSize: NSFont.systemFontSize), textColor: .labelColor,
            placeholder: placeholder, onReturn: onSubmit),
            attachments: attachments.wrappedValue,
            onAdd: { item, _ in
                attachments.wrappedValue.append(item)
                guard item.type == .image else { return nil }
                return FieldAttachment.imageToken(attachments.wrappedValue.filter { $0.type == .image }.count)
            },
            onRemove: { item in
                FieldAttachment.remove(item.id, from: &attachments.wrappedValue, text: &text.wrappedValue)
            })
    }

    /// Supply an existing editor to retain its keyboard shortcuts, focus and draft representation.
    /// Return a token from `onAdd` to insert it at the selection, or nil if the caller handles insertion.
    public init(editor: IMETextView, attachments: [FieldAttachment], editorHeight: CGFloat? = nil,
                showsFilePicker: Bool = true,
                onAdd: @escaping (FieldAttachment, AttachmentInsertionSource) -> String?,
                onRemove: @escaping (FieldAttachment) -> Void) {
        self.editor = editor
        self.attachments = attachments
        self.editorHeight = editorHeight
        self.showsFilePicker = showsFilePicker
        add = onAdd
        remove = onRemove
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !attachments.isEmpty {
                AttachmentPreviewStrip(attachments: attachments, onRemove: remove)
            }
            HStack(alignment: .bottom, spacing: 4) {
                if showsFilePicker {
                    Button { choosingFiles = true } label: { Label("Add Files…", systemImage: "paperclip") }
                        .labelStyle(.iconOnly).buttonStyle(.borderless)
                        .help("Add Files…")
                        .accessibilityIdentifier("\(editor.accessibilityIdentifier)-add-files")
                        .fileImporter(isPresented: $choosingFiles, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                            guard case .success(let urls) = result else { return }
                            for url in urls { insert(.file(at: url), source: .picker) }
                        }
                }
                if let editorHeight {
                    configuredEditor.frame(height: editorHeight)
                } else {
                    Text(editor.text.isEmpty || editor.text.hasSuffix("\n") ? editor.text + " " : editor.text)
                        .font(Font(editor.font)).lineLimit(1...5).padding(.horizontal, 5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .hidden().overlay { configuredEditor }
                }
            }
        }
        .onDrop(of: AttachmentIntake.dropTypes, isTargeted: nil) { providers in
            guard editor.isEditable else { return false }
            AttachmentIntake.load(providers, onAttachment: { insert($0, source: .drop) }, onText: selection.insert)
            return true
        }
        .sheet(item: $preview) { AttachmentPreviewSheet(attachment: $0) }
    }

    private var configuredEditor: IMETextView {
        var field = editor
        field.onTextViewReady = { view in
            selection.view = view
            view.unregisterDraggedTypes()
            editor.onTextViewReady?(view)
        }
        field.onPasteCommandV = {
            guard editor.isEditable else { return true }
            guard let items = AttachmentIntake.attachments(from: .general) else { return editor.onPasteCommandV() }
            for item in items { insert(item, source: .paste) }
            return true
        }
        if field.onImageChipTap == nil {
            field.onImageChipTap = { index in
                let images = attachments.filter { $0.type == .image }
                if index > 0, index <= images.count { preview = images[index - 1] }
            }
        }
        return field
    }

    private func insert(_ item: FieldAttachment, source: AttachmentInsertionSource) {
        guard editor.isEditable, let token = add(item, source) else { return }
        selection.insert(token)
    }
}
#endif
