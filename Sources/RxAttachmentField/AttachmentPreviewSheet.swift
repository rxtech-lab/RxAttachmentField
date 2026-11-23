#if os(macOS)
import Quartz
import SwiftUI

public extension EnvironmentValues {
    /// Optional app renderer for Markdown documents. Other files use the system preview.
    @Entry var attachmentMarkdownPreview: (@MainActor (String, URL) -> AnyView)? = nil
}

/// The same preview is available from an inline token or a card above the editor.
public struct AttachmentPreviewSheet: View {
    public let attachment: FieldAttachment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.attachmentMarkdownPreview) private var renderMarkdown
    @State private var markdown: String?

    public init(attachment: FieldAttachment) { self.attachment = attachment }

    public var body: some View {
        switch attachment.type {
        case .image:
            ImagePreviewSheet(attachment: attachment)
        case .text:
            TextPreviewSheet(attachment: attachment)
        case .file, .link:
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(attachment.name).font(.headline).lineLimit(1)
                    Spacer()
                    Button("Close") { dismiss() }.keyboardShortcut(.cancelAction)
                }
                .padding()
                Divider()
                if attachment.type == .link, let url = URL(string: attachment.path) {
                    Link(attachment.path, destination: url).padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let markdown, let renderMarkdown {
                    renderMarkdown(markdown, URL(fileURLWithPath: attachment.path))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else if FileManager.default.fileExists(atPath: attachment.path) {
                    QuickLookFile(url: URL(fileURLWithPath: attachment.path))
                } else {
                    ContentUnavailableView("File unavailable", systemImage: "doc")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 480, idealWidth: 760, maxWidth: .infinity,
                   minHeight: 360, idealHeight: 540, maxHeight: .infinity)
            .task(id: attachment.path) {
                let url = URL(fileURLWithPath: attachment.path)
                guard renderMarkdown != nil, ["md", "markdown", "mdown"].contains(url.pathExtension.lowercased()) else { return }
                let contents = await Task.detached { try? String(contentsOf: url, encoding: .utf8) }.value
                if !Task.isCancelled { markdown = contents }
            }
        }
    }
}

private struct QuickLookFile: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal)!
        view.autostarts = false
        view.shouldCloseWithWindow = false
        return view
    }

    func updateNSView(_ view: QLPreviewView, context: Context) {
        if view.previewItem?.previewItemURL != url { view.previewItem = url as NSURL }
    }

    static func dismantleNSView(_ view: QLPreviewView, coordinator: ()) { view.close() }
}
#endif
