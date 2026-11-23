import SwiftUI
import LinkPresentation

#if os(macOS)

/// Attachment preview item — tall rectangular card
/// Shows an X button overlay on mouse hover
struct AttachmentPreviewItem: View {
    let attachment: FieldAttachment
    let onRemove: (() -> Void)?
    var onTap: (() -> Void)?

    @State private var isHovered = false

    private let cardWidth: CGFloat = 96
    private let cardHeight: CGFloat = 104

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button { onTap?() } label: {
                cardContent
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Preview \(attachment.name)")
            .accessibilityIdentifier("attachment-preview-\(attachment.name)")

            if isHovered, let onRemove {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.3))
                    .frame(width: cardWidth, height: cardHeight)
                    .allowsHitTesting(false)
                    .transition(.opacity.animation(.easeOut(duration: 0.15)))

                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.primary)
                        .background(Color(nsColor: .windowBackgroundColor), in: Circle())
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .frame(width: 24, height: 24)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(attachment.name)")
                .padding(4)
                .transition(.opacity.animation(.easeOut(duration: 0.15)))
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch attachment.type {
        case .image:
            imageCard
        case .file:
            fileCard
        case .text:
            textCard
        case .link:
            linkCard
        }
    }

    // MARK: - Image Card

    @State private var renderedImage: CGImage?

    private var imageCard: some View {
        ZStack(alignment: .bottom) {
            if let cgImage = renderedImage {
                Image(decorative: cgImage, scale: 2.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
            } else {
                Color(nsColor: .controlBackgroundColor)
                    .frame(width: cardWidth, height: cardHeight)
                Image(systemName: "photo")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.secondary)
            }

            Text(attachment.name)
                .font(.system(size: 10))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.86))
                .environment(\.colorScheme, .dark)
        }
        .task(id: attachment.id) {
            renderedImage = makeCGImage()
        }
    }

    private func makeCGImage() -> CGImage? {
        let source = attachment.imageData.flatMap { CGImageSourceCreateWithData($0 as CFData, nil) }
            ?? CGImageSourceCreateWithURL(URL(fileURLWithPath: attachment.path) as CFURL, nil)
        guard let source else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 200,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    // MARK: - File Card

    private var fileCard: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "doc.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.accentColor)
            Text(attachment.name)
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Text Card

    private var textCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let text = attachment.textContent {
                Text(text.prefix(300))
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(nil)
                    .padding(6)
            }
            Spacer(minLength: 0)

            HStack(spacing: 3) {
                Image(systemName: "doc.text")
                    .font(.system(size: 9))
                Text(shortTextName)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var shortTextName: String {
        if let text = attachment.textContent {
            let lines = text.components(separatedBy: .newlines).count
            return "\(lines) lines"
        }
        return ""
    }

    // MARK: - Link Card

    @State private var linkTitle: String?
    @State private var linkFavicon: NSImage?

    private var linkCard: some View {
        VStack(spacing: 0) {
            Spacer()

            Group {
                if let favicon = linkFavicon {
                    Image(nsImage: favicon)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "link")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer()

            VStack(spacing: 3) {
                Text(attachment.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                if let title = linkTitle {
                    Text(title)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .task(id: attachment.id) {
            await fetchLinkMetadata()
        }
    }

    private func fetchLinkMetadata() async {
        guard attachment.type == .link,
              let url = URL(string: attachment.path) else { return }

        let provider = LPMetadataProvider()
        provider.shouldFetchSubresources = true
        provider.timeout = 5

        guard let metadata = try? await provider.startFetchingMetadata(for: url) else { return }

        linkTitle = metadata.title

        guard let iconProvider = metadata.iconProvider else { return }
        linkFavicon = await withCheckedContinuation { continuation in
            iconProvider.loadObject(ofClass: NSImage.self) { object, _ in
                continuation.resume(returning: object as? NSImage)
            }
        }
    }
}
#endif
