# RxAttachmentField

A native macOS attachment field for SwiftUI. Paste a screenshot or choose an image to insert an `[Image1]` tag at the selection. Image thumbnails and file cards appear above the editor. Click a card to open its preview sheet. Ordinary text uses the native paste operation.

```swift
import RxAttachmentField
import SwiftUI

struct RequestEditor: View {
    @State private var text = ""
    @State private var attachments: [FieldAttachment] = []

    var body: some View {
        AttachmentTextField(text: $text, attachments: $attachments, placeholder: "Describe the work…")
    }
}
```

Add `https://github.com/rxtech-lab/RxAttachmentField.git` as a Swift package dependency and select the `RxAttachmentField` product. The editor requires macOS 14 or later and Swift 6.2. Its Foundation attachment model is also available on iOS.

For an existing composer, the initializer accepting an `IMETextView` preserves its keyboard handlers, focus, sizing and submission policy. `AttachmentPreviewStrip` presents the same cards in read-only messages.
