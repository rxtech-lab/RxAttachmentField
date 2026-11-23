// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RxAttachmentField",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "RxAttachmentField", targets: ["RxAttachmentField"])],
    targets: [
        .target(name: "RxAttachmentField"),
        .testTarget(name: "RxAttachmentFieldTests", dependencies: ["RxAttachmentField"])
    ]
)
