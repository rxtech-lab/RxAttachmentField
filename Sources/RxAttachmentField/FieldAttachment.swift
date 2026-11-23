import Foundation

public struct FieldAttachment: Identifiable, Sendable {
    public let id: UUID
    public let type: AttachmentType
    public let name: String
    public let path: String
    public let fileSize: Int64?
    public let textContent: String?
    public let imageData: Data?

    public init(
        id: UUID = UUID(),
        type: AttachmentType,
        name: String,
        path: String = "",
        fileSize: Int64? = nil,
        textContent: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.path = path
        self.fileSize = fileSize
        self.textContent = textContent
        self.imageData = imageData
    }

    public enum AttachmentType: String, Sendable {
        case image
        case file
        case text
        case link
    }

    public static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tiff", "heic"
    ]


    public static func file(at url: URL) -> Self {
        let type: AttachmentType = imageExtensions.contains(url.pathExtension.lowercased()) ? .image : .file
        let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        let data = type == .image ? try? Data(contentsOf: url, options: .mappedIfSafe) : nil
        return Self(type: type, name: url.lastPathComponent, path: url.path, fileSize: size.map(Int64.init), imageData: data)
    }

    public static func imageToken(_ index: Int) -> String { "[Image\(index)]" }

    /// Remap the old indices by image identity, including repeated or reordered tokens.
    public static func remove(_ id: UUID, from attachments: inout [Self], text: inout String) {
        guard let removed = attachments.first(where: { $0.id == id }) else { return }
        let oldImages = attachments.filter { $0.type == .image }
        attachments.removeAll { $0.id == id }
        guard removed.type == .image else { return }
        let remaining = attachments.filter { $0.type == .image }
        let slots = Dictionary(uniqueKeysWithValues: remaining.enumerated().map { ($0.element.id, $0.offset + 1) })
        let source = text as NSString
        let result = NSMutableString(string: text)
        for match in imagePattern.matches(in: text, range: NSRange(location: 0, length: source.length)).reversed() {
            guard let slot = Int(source.substring(with: match.range(at: 1))), slot > 0, slot <= oldImages.count else { continue }
            let replacement = slots[oldImages[slot - 1].id].map(imageToken) ?? ""
            result.replaceCharacters(in: match.range, with: replacement)
        }
        text = result as String
    }

    private static let imagePattern = try! NSRegularExpression(pattern: #"\[Image(\d+)\]"#)
}
