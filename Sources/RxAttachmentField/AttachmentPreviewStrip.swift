#if os(macOS)
import SwiftUI

/// File and image cards shared by the editor and submitted messages.
public struct AttachmentPreviewStrip: View {
    private let attachments: [FieldAttachment]
    private let remove: ((FieldAttachment) -> Void)?
    @State private var preview: FieldAttachment?

    public init(attachments: [FieldAttachment], onRemove: ((FieldAttachment) -> Void)? = nil) {
        self.attachments = attachments
        remove = onRemove
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(attachments) { item in
                    AttachmentPreviewItem(attachment: item, onRemove: remove.map { action in { action(item) } },
                                          onTap: { preview = item })
                }
            }
        }
        .scrollIndicators(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .sheet(item: $preview) { AttachmentPreviewSheet(attachment: $0) }
    }
}
#endif
