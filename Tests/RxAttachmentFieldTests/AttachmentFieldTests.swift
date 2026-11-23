import Foundation
import Testing
@testable import RxAttachmentField

@Test func removalKeepsRepeatedAndReorderedImageReferences() {
    let first = FieldAttachment(type: .image, name: "First")
    let second = FieldAttachment(type: .image, name: "Second")
    let third = FieldAttachment(type: .image, name: "Third")
    var items = [first, FieldAttachment(type: .file, name: "Notes"), second, third]
    var text = "[Image3] [Image1] [Image3] [Image2] [Image99]"
    FieldAttachment.remove(second.id, from: &items, text: &text)
    #expect(text == "[Image2] [Image1] [Image2]  [Image99]")
    #expect(items.map(\.name) == ["First", "Notes", "Third"])
}

#if os(macOS)
import AppKit
import SwiftUI

@Test @MainActor func clipboardKeepsFinderURLsAndConvertsTIFFToPNG() throws {
    let board = NSPasteboard.withUniqueName()
    defer { board.releaseGlobally() }
    let url = URL(fileURLWithPath: "/tmp/Field notes.md")
    board.writeObjects([url as NSURL])
    #expect(AttachmentIntake.attachments(from: board)?.first?.path == url.path)
    board.clearContents()
    let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 4, bitsPerPixel: 32))
    board.setData(bitmap.tiffRepresentation, forType: .tiff)
    let image = try #require(AttachmentIntake.attachments(from: board)?.first)
    #expect(image.type == .image)
    #expect(image.imageData?.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]) == true)
    board.clearContents()
    board.setString("first\nsecond", forType: .string)
    #expect(AttachmentIntake.attachments(from: board) == nil)
}
#endif
