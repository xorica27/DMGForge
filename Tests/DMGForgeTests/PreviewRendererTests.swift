import AppKit
import Foundation
import Testing
@testable import DMGForgeCore

@Test func generatedPreviewWritesPNG() throws {
    let tempRoot = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let outputURL = tempRoot.appendingPathComponent("preview.png")

    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )

    try PreviewRenderer().render(project: project, to: outputURL)

    let data = try Data(contentsOf: outputURL)
    #expect(data.starts(with: [0x89, 0x50, 0x4E, 0x47]))
    #expect(data.count > 1_000)
}

@Test func imagePreviewCopiesCustomBackground() throws {
    let tempRoot = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let sourceURL = tempRoot.appendingPathComponent("source.png")
    let outputURL = tempRoot.appendingPathComponent("preview.png")
    try makeSolidPNG(color: .systemTeal, size: NSSize(width: 32, height: 32), outputURL: sourceURL)

    var project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    project.background = DMGBackground(
        mode: .image,
        imagePath: sourceURL.path,
        title: "Ignored",
        description: "Ignored",
        footer: "Ignored"
    )

    try PreviewRenderer().render(project: project, to: outputURL)

    #expect(try Data(contentsOf: outputURL) == Data(contentsOf: sourceURL))
}

private func makeTempDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makeSolidPNG(color: NSColor, size: NSSize, outputURL: URL) throws {
    let image = NSImage(size: size)
    image.lockFocus()
    color.setFill()
    NSRect(origin: .zero, size: size).fill()
    image.unlockFocus()

    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }

    try pngData.write(to: outputURL)
}

