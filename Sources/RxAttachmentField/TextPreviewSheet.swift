#if os(macOS)
import SwiftUI
import AppKit

/// Detail preview sheet for text attachments
struct TextPreviewSheet: View {
    let attachment: FieldAttachment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Color.accentColor)
                Text(attachment.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Spacer()

                Button {
                    if let text = attachment.textContent {
#if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
#elseif os(iOS)
                        UIPasteboard.general.string = text
#endif
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Copy")

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Text content
            ScrollView {
                if let text = attachment.textContent {
                    Text(text)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .frame(width: 600, height: 450)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
#endif
