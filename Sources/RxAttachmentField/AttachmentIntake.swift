#if os(macOS)
import AppKit
import UniformTypeIdentifiers

/// Turns pasted and dropped content into attachments. Shared by the task
/// description editor and the Run tab's follow-up composer so both accept the
/// same things the same way.
@MainActor
public enum AttachmentIntake {
    /// The drag types the task fields accept.
    public static let dropTypes: [UTType] = [.fileURL, .image, .plainText]

    /// Attachments for what's on the pasteboard, or `nil` when it only holds
    /// text — the caller then lets its text view run the native paste, which
    /// keeps undo and IME intact.
    public static func attachments(from pasteboard: NSPasteboard) -> [FieldAttachment]? {
        // File URLs first: an image dragged out of Finder puts both a URL and
        // raw TIFF on the pasteboard, and the URL is the better reference.
        let fileURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
        if !fileURLs.isEmpty {
            return fileURLs.map(FieldAttachment.file(at:))
        }
        if let image = imageAttachment(from: pasteboard) {
            return [image]
        }
        return nil
    }

    private static func imageAttachment(from pasteboard: NSPasteboard) -> FieldAttachment? {
        let name = "pasted-\(UUID().uuidString.prefix(8)).png"
        if let data = pasteboard.data(forType: .png) {
            return FieldAttachment(type: .image, name: name, imageData: data)
        }
        guard let image = NSImage(pasteboard: pasteboard),
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return nil }
        return FieldAttachment(type: .image, name: name, imageData: png)
    }

    /// Loads dropped items: files and images arrive through `onAttachment`,
    /// plain text through `onText`. Both run on the main actor.
    public static func load(
        _ providers: [NSItemProvider],
        onAttachment: @escaping @MainActor (FieldAttachment) -> Void,
        onText: @escaping @MainActor (String) -> Void
    ) {
        let fileType = UTType.fileURL.identifier
        let imageType = UTType.image.identifier
        for provider in providers {
            if provider.hasRepresentationConforming(toTypeIdentifier: fileType) {
                provider.loadItem(forTypeIdentifier: fileType) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    Task { @MainActor in
                        onAttachment(.file(at: url))
                    }
                }
            } else if provider.hasRepresentationConforming(toTypeIdentifier: imageType) {
                provider.loadDataRepresentation(forTypeIdentifier: imageType) { data, _ in
                    guard let data, let png = NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:]) else { return }
                    let name = "dropped-\(UUID().uuidString.prefix(8)).png"
                    Task { @MainActor in
                        onAttachment(FieldAttachment(type: .image, name: name, imageData: png))
                    }
                }
            } else {
                _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                    guard let text = string as? String, !text.isEmpty else { return }
                    Task { @MainActor in onText(text) }
                }
            }
        }
    }
}
#endif
